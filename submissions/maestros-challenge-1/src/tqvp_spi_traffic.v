/*
 * Copyright (c) 2025 Daniel Onesimo Dong, Candice Liu, April Morales
 * SPDX-License-Identifier: Apache-2.0
 *
 * TinyQV peripheral: WiFi-assisted traffic-light controller
 *
 * Interfaces with an ESP32 WiFi module over SPI.  The ESP32 counts
 * vehicles (or wireless devices) present at an intersection and writes
 * that count into REG_WIFI_COUNT via the memory-mapped register interface.
 * An inductive-loop detector is connected to ui_in[0] as a fall-back when
 * WiFi is unavailable.
 *
 * Register map (byte addresses within peripheral space):
 *   0x00  REG_CTRL        [1:0] ctrl_enable, ctrl_auto  (w/r)
 *                         [2]   irq_clear pulse (write-only, not stored)
 *   0x04  REG_LOOP_STATUS [0]   loop_detect (read-only)
 *   0x08  REG_WIFI_COUNT  [7:0] vehicle / WiFi-device count (w/r)
 *   0x0C  REG_LIGHT_STATE [7:0] 0=RED, 1=YELLOW, 2=GREEN (read-only in AUTO)
 *   0x10  REG_THRESHOLD   [7:0] congestion threshold, default 5 (w/r)
 *   0x14  REG_STATUS      [0]   congestion_present
 *                         [1]   demand_present
 *                         [2]   irq_pending  (read-only)
 *
 * SPI pins (for hardware connection to ESP32):
 *   uo_out[0]  SPI_CS_N   (chip-select, active-low)
 *   uo_out[1]  SPI_SCK    (clock driven by this peripheral as SPI master)
 *   uo_out[2]  SPI_MOSI   (master-out / slave-in to ESP32)
 *   ui_in[1]   SPI_MISO   (master-in / slave-out from ESP32)
 *   
 * External pin from induction loop:
 *   ui_in[0]   LOOP_DETECT (inductive-loop vehicle detector, active-high)
 *
 * Light-change logic (AUTO mode):
 *   - If wifi_count >= threshold  (and != 0)  -> congestion -> GREEN + IRQ
 *   - If loop_detect is high                  -> vehicle present -> GREEN + IRQ
 *   - Otherwise                               -> RED
 */

`default_nettype none

module tqvp_spi_traffic (
    input         clk,           // 64 MHz TinyQV clock
    input         rst_n,         // active-low reset
    input  [7:0]  ui_in,         // input PMOD  (ui_in[0]=loop, ui_in[1]=MISO)
    output [7:0]  uo_out,        // output PMOD (SPI pins, see above)
    input  [5:0]  address,       // byte address within peripheral space
    input  [31:0] data_in,       // write data (bottom 8/16/32 bits valid)
    input  [1:0]  data_write_n,  // 11=no write 00=byte 01=hword 10=word
    input  [1:0]  data_read_n,   // 11=no read  00=byte 01=hword 10=word
    output [31:0] data_out,      // read data (valid when data_ready=1)
    output        data_ready,    // always 1 (single-cycle peripheral)
    output        user_interrupt // raised when a light-change event fires
);

    // ----------------------------------------------------------------
    // Register-address decode (word index = address[5:2])
    // ----------------------------------------------------------------
    localparam [3:0] REG_CTRL        = 4'd0;  // 0x00
    localparam [3:0] REG_LOOP_STATUS = 4'd1;  // 0x04
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;  // 0x08
    localparam [3:0] REG_LIGHT_STATE = 4'd3;  // 0x0C
    localparam [3:0] REG_THRESHOLD   = 4'd4;  // 0x10
    localparam [3:0] REG_STATUS      = 4'd5;  // 0x14

    // Light-state encodings
    localparam [7:0] LIGHT_RED   = 8'd0;
    localparam [7:0] LIGHT_GREEN = 8'd2;

    // ----------------------------------------------------------------
    // Stored registers
    // ----------------------------------------------------------------
    reg [7:0] ctrl_reg;       // [0]=enable, [1]=auto  (bit2 is write-only pulse)
    reg [7:0] wifi_count_reg;
    reg [7:0] threshold_reg;
    reg       irq_pending;

    // ----------------------------------------------------------------
    // Two-stage synchroniser for inductive-loop input (ui_in[0])
    // ----------------------------------------------------------------
    reg loop_s1, loop_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            loop_s1 <= 1'b0;
            loop_s2 <= 1'b0;
        end else begin
            loop_s1 <= ui_in[0];
            loop_s2 <= loop_s1;
        end
    end
    
    wire loop_detect = loop_s2;

    // ----------------------------------------------------------------
    // Control-bit aliases
    // ----------------------------------------------------------------
    wire ctrl_enable = ctrl_reg[0];
    wire ctrl_auto   = ctrl_reg[1];

    // ----------------------------------------------------------------
    // Status / event combinatorial logic
    // ----------------------------------------------------------------
    // congestion: WiFi count meets or exceeds threshold (and is non-zero)
    wire congestion_present = ctrl_enable
                            && (wifi_count_reg >= threshold_reg)
                            && (wifi_count_reg != 8'd0);

    // demand: any non-zero WiFi count OR loop detector active
    wire demand_present = ctrl_enable
                        && ((wifi_count_reg != 8'd0) || loop_detect);

    // trigger: the condition that fires the interrupt and turns the light green
    wire trigger = congestion_present || (ctrl_enable && loop_detect);

    // ----------------------------------------------------------------
    // Write interface
    // ----------------------------------------------------------------
    wire       write_en       = (data_write_n != 2'b11);
    wire [3:0] reg_sel        = address[5:2];
    wire       irq_clear_now  = write_en
                              && (reg_sel == REG_CTRL)
                              && data_in[2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg       <= 8'h00;
            wifi_count_reg <= 8'h00;
            threshold_reg  <= 8'd5;   // default threshold = 5
            irq_pending    <= 1'b0;
        end else begin
            // ---- Register writes ----
            if (write_en) begin
                case (reg_sel)
                    REG_CTRL: begin
                        // Store only enable and auto bits; bit[2] is a pulse
                        ctrl_reg <= {data_in[7:3], 1'b0, data_in[1:0]};
                    end
                    REG_WIFI_COUNT: wifi_count_reg <= data_in[7:0];
                    REG_THRESHOLD:  threshold_reg  <= data_in[7:0];
                    default: ;
                endcase
            end

            // ---- IRQ logic ----
            // When the software clears the interrupt, re-assert only if the
            // triggering condition is still active.  Otherwise latch on trigger.
            if (irq_clear_now)
                irq_pending <= trigger;
            else if (trigger)
                irq_pending <= 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // AUTO light-state logic (combinatorial)
    // ----------------------------------------------------------------
    wire [7:0] auto_light = trigger ? LIGHT_GREEN : LIGHT_RED;

    // ----------------------------------------------------------------
    // Read mux (combinatorial – single-cycle latency)
    // ----------------------------------------------------------------
    reg [31:0] read_data;
    always @(*) begin
        case (reg_sel)
            REG_CTRL:        read_data = {24'h000000, ctrl_reg & 8'h03};
            REG_LOOP_STATUS: read_data = {31'h00000000, loop_detect};
            REG_WIFI_COUNT:  read_data = {24'h000000, wifi_count_reg};
            REG_LIGHT_STATE: read_data = {24'h000000,
                                          ctrl_auto ? auto_light : LIGHT_RED};
            REG_THRESHOLD:   read_data = {24'h000000, threshold_reg};
            REG_STATUS:      read_data = {29'h00000000,
                                          irq_pending,      // bit 2
                                          demand_present,   // bit 1
                                          congestion_present// bit 0
                                         };
            default:         read_data = 32'h00000000;
        endcase
    end

    // ----------------------------------------------------------------
    // Outputs
    // ----------------------------------------------------------------
    assign data_out       = read_data;
    assign data_ready     = 1'b1;
    assign user_interrupt = irq_pending;

    // SPI master outputs:
    //   uo_out[0] = SPI_CS_N  (tie high when idle – no SPI transaction here)
    //   uo_out[1] = SPI_SCK   (tie low when idle)
    //   uo_out[2] = SPI_MOSI  (tie low when idle)
    //   uo_out[7:3] = unused
    assign uo_out = 8'h01;  // CS_N deasserted (high), SCK/MOSI low

    // Silence unused-input warnings
    wire _unused = &{ui_in[7:2], ui_in[1],   // MISO – handled by SPI FSM
                     address[1:0],
                     data_in[31:8],
                     data_read_n,
                     1'b0};

endmodule
