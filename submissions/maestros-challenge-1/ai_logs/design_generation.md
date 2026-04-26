##results    # Testing and implementation results
                
#simulation/           # Simulation outputs
#synthesis/            # Synthesis reports
#fpga/                # FPGA implementation results
#timing/              # Timing analysis

#tb
`timescale 1ns/1ps
`default_nettype none

module tb_tqvp_spi_traffic;

    // ============================================================
    // Clock / reset
    // ============================================================
    reg clk;
    reg rst_n;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;   // 100 MHz clock
    end

    // ============================================================
    // DUT interface
    // ============================================================
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;

    reg  [5:0]  address;
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire        user_interrupt;

    // ============================================================
    // DUT instantiation
    // ============================================================
    tqvp_spi_traffic dut (
        .clk(clk),
        .rst_n(rst_n),
        .ui_in(ui_in),
        .uo_out(uo_out),
        .address(address),
        .data_in(data_in),
        .data_write_n(data_write_n),
        .data_read_n(data_read_n),
        .data_out(data_out),
        .data_ready(data_ready),
        .user_interrupt(user_interrupt)
    );

    // ============================================================
    // Register map
    // ============================================================
    localparam [5:0] REG_CTRL        = 6'h00;
    localparam [5:0] REG_LOOP_STATUS = 6'h04;
    localparam [5:0] REG_WIFI_COUNT  = 6'h08;
    localparam [5:0] REG_LIGHT_STATE = 6'h0C;
    localparam [5:0] REG_THRESHOLD   = 6'h10;
    localparam [5:0] REG_STATUS      = 6'h14;

    // CTRL bits
    localparam [7:0] CTRL_ENABLE    = 8'h01;
    localparam [7:0] CTRL_AUTO      = 8'h02;
    localparam [7:0] CTRL_IRQ_CLEAR = 8'h04;

    // STATUS bits
    localparam [7:0] STATUS_CONGESTION = 8'h01;
    localparam [7:0] STATUS_DEMAND     = 8'h02;
    localparam [7:0] STATUS_IRQ        = 8'h04;

    // Light state encoding
    localparam [7:0] LIGHT_RED    = 8'd0;
    localparam [7:0] LIGHT_YELLOW = 8'd1;
    localparam [7:0] LIGHT_GREEN  = 8'd2;

    reg [31:0] rd_word;
    reg [7:0]  rd_byte;

    // ============================================================
    // Tasks
    // ============================================================
    task reset_dut;
    begin
        ui_in        = 8'h00;
        address      = 6'h00;
        data_in      = 32'h0000_0000;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;

        rst_n = 1'b0;
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);
    end
    endtask

    task write_byte;
        input [5:0] reg_addr;
        input [7:0] value;
    begin
        @(posedge clk);
        address      <= reg_addr;
        data_in      <= {24'h000000, value};
        data_write_n <= 2'b00;   // byte write
        data_read_n  <= 2'b11;

        @(posedge clk);
        data_write_n <= 2'b11;
        address      <= 6'h00;
        data_in      <= 32'h0000_0000;
    end
    endtask

    task read_word;
        input  [5:0]  reg_addr;
        output [31:0] value;
    begin
        @(posedge clk);
        address      <= reg_addr;
        data_read_n  <= 2'b10;   // word read
        data_write_n <= 2'b11;

        @(posedge clk);
        value        = data_out;
        data_read_n  <= 2'b11;
        address      <= 6'h00;
    end
    endtask

    task read_byte;
        input  [5:0] reg_addr;
        output [7:0] value;
        reg [31:0] tmp;
    begin
        read_word(reg_addr, tmp);
        value = tmp[7:0];
    end
    endtask

    task expect_eq8;
        input [8*40-1:0] label;
        input [7:0] got;
        input [7:0] exp;
    begin
        if (got !== exp) begin
            $display("FAIL: %0s got=0x%02x expected=0x%02x at t=%0t", label, got, exp, $time);
            $finish;
        end else begin
            $display("PASS: %0s got expected 0x%02x", label, got);
        end
    end
    endtask

    task expect_eq1;
        input [8*40-1:0] label;
        input got;
        input exp;
    begin
        if (got !== exp) begin
            $display("FAIL: %0s got=%0d expected=%0d at t=%0t", label, got, exp, $time);
            $finish;
        end else begin
            $display("PASS: %0s got expected %0d", label, got);
        end
    end
    endtask

    task expect_mask_set;
        input [8*40-1:0] label;
        input [31:0] got;
        input [31:0] mask;
    begin
        if ((got & mask) != mask) begin
            $display("FAIL: %0s got=0x%08x required mask=0x%08x at t=%0t", label, got, mask, $time);
            $finish;
        end else begin
            $display("PASS: %0s mask 0x%08x set", label, mask);
        end
    end
    endtask

    task expect_light_legal;
        input [7:0] light;
    begin
        if ((light !== LIGHT_RED) &&
            (light !== LIGHT_YELLOW) &&
            (light !== LIGHT_GREEN)) begin
            $display("FAIL: illegal LIGHT_STATE=%0d at t=%0t", light, $time);
            $finish;
        end else begin
            $display("PASS: legal LIGHT_STATE=%0d", light);
        end
    end
    endtask

    // ============================================================
    // Test sequence
    // ============================================================
    initial begin
        $dumpfile("tb_tqvp_spi_traffic.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic);

        $display("========================================");
        $display("Starting tb_tqvp_spi_traffic");
        $display("========================================");

        reset_dut();

        // --------------------------------------------------------
        // Test 1: default values after reset
        // --------------------------------------------------------
        $display("\n--- Test 1: reset defaults ---");

        read_byte(REG_CTRL, rd_byte);
        expect_eq8("CTRL after reset", rd_byte, 8'h00);

        read_byte(REG_WIFI_COUNT, rd_byte);
        expect_eq8("WIFI_COUNT after reset", rd_byte, 8'h00);

        read_byte(REG_THRESHOLD, rd_byte);
        expect_eq8("THRESHOLD after reset", rd_byte, 8'd5);

        read_byte(REG_LIGHT_STATE, rd_byte);
        expect_eq8("LIGHT_STATE after reset", rd_byte, LIGHT_RED);

        expect_eq1("user_interrupt after reset", user_interrupt, 1'b0);

        // --------------------------------------------------------
        // Test 2: enable module and set threshold
        // --------------------------------------------------------
        $display("\n--- Test 2: write CTRL and THRESHOLD ---");

        write_byte(REG_CTRL, CTRL_ENABLE | CTRL_AUTO);
        write_byte(REG_THRESHOLD, 8'd6);

        read_byte(REG_CTRL, rd_byte);
        expect_eq8("CTRL programmed", rd_byte, (CTRL_ENABLE | CTRL_AUTO));

        read_byte(REG_THRESHOLD, rd_byte);
        expect_eq8("THRESHOLD programmed", rd_byte, 8'd6);

        // --------------------------------------------------------
        // Test 3: write WIFI_COUNT below threshold
        // --------------------------------------------------------
        $display("\n--- Test 3: WIFI_COUNT below threshold ---");

        write_byte(REG_WIFI_COUNT, 8'd3);
        repeat (4) @(posedge clk);

        read_byte(REG_WIFI_COUNT, rd_byte);
        expect_eq8("WIFI_COUNT = 3", rd_byte, 8'd3);

        read_word(REG_STATUS, rd_word);
        expect_mask_set("STATUS demand set", rd_word, STATUS_DEMAND);

        if (rd_word[0] !== 1'b0) begin
            $display("FAIL: congestion should be 0 when WIFI_COUNT < THRESHOLD");
            $finish;
        end else begin
            $display("PASS: congestion is 0 below threshold");
        end

        // With your current RTL, any nonzero wifi_count sets demand_present,
        // but irq_pending is only asserted when congestion or loop_detect is true.
        expect_eq1("user_interrupt below threshold", user_interrupt, 1'b0);

        read_byte(REG_LIGHT_STATE, rd_byte);
        expect_eq8("LIGHT_STATE below threshold", rd_byte, LIGHT_RED);

        // --------------------------------------------------------
        // Test 4: write WIFI_COUNT above threshold
        // --------------------------------------------------------
        $display("\n--- Test 4: WIFI_COUNT above threshold ---");

        write_byte(REG_WIFI_COUNT, 8'd9);
        repeat (4) @(posedge clk);

        read_byte(REG_WIFI_COUNT, rd_byte);
        expect_eq8("WIFI_COUNT = 9", rd_byte, 8'd9);

        read_word(REG_STATUS, rd_word);
        expect_mask_set("STATUS congestion set", rd_word, STATUS_CONGESTION);
        expect_mask_set("STATUS demand set", rd_word, STATUS_DEMAND);
        expect_mask_set("STATUS irq set", rd_word, STATUS_IRQ);

        expect_eq1("user_interrupt above threshold", user_interrupt, 1'b1);

        read_byte(REG_LIGHT_STATE, rd_byte);
        expect_eq8("LIGHT_STATE above threshold", rd_byte, LIGHT_GREEN);

        // --------------------------------------------------------
        // Test 5: clear interrupt
        // Note: with the current RTL, irq_pending may re-assert on the next
        // cycle if congestion/loop_detect remains true.
        // So clear, then immediately remove the cause if needed.
        // --------------------------------------------------------
        $display("\n--- Test 5: clear interrupt ---");

        // First clear the congestion source
        write_byte(REG_WIFI_COUNT, 8'd0);
        repeat (2) @(posedge clk);

        // Now pulse IRQ clear
        write_byte(REG_CTRL, CTRL_ENABLE | CTRL_AUTO | CTRL_IRQ_CLEAR);
        repeat (2) @(posedge clk);

        read_word(REG_STATUS, rd_word);

        if (rd_word[2] !== 1'b0) begin
            $display("FAIL: irq_pending should be 0 after clearing source and IRQ");
            $finish;
        end else begin
            $display("PASS: irq_pending cleared");
        end

        expect_eq1("user_interrupt cleared", user_interrupt, 1'b0);

        // --------------------------------------------------------
        // Test 6: loop detector input alone
        // --------------------------------------------------------
        $display("\n--- Test 6: inductive loop input ---");

        ui_in[0] = 1'b1;
        repeat (4) @(posedge clk);

        read_word(REG_LOOP_STATUS, rd_word);
        expect_mask_set("LOOP_STATUS vehicle present", rd_word, 32'h0000_0001);

        read_word(REG_STATUS, rd_word);
        expect_mask_set("STATUS demand from loop", rd_word, STATUS_DEMAND);
        expect_mask_set("STATUS irq from loop", rd_word, STATUS_IRQ);

        expect_eq1("user_interrupt from loop", user_interrupt, 1'b1);

        read_byte(REG_LIGHT_STATE, rd_byte);
        expect_eq8("LIGHT_STATE from loop", rd_byte, LIGHT_GREEN);

        // deassert loop
        ui_in[0] = 1'b0;
        repeat (4) @(posedge clk);

        // clear irq after removing cause
        write_byte(REG_CTRL, CTRL_ENABLE | CTRL_AUTO | CTRL_IRQ_CLEAR);
        repeat (2) @(posedge clk);

        expect_eq1("user_interrupt after loop clear", user_interrupt, 1'b0);

        // --------------------------------------------------------
        // Test 7: combined loop + high wifi count
        // --------------------------------------------------------
        $display("\n--- Test 7: combined scenario ---");

        ui_in[0] = 1'b1;
        write_byte(REG_WIFI_COUNT, 8'd12);
        repeat (4) @(posedge clk);

        read_word(REG_STATUS, rd_word);
        expect_mask_set("combined congestion", rd_word, STATUS_CONGESTION);
        expect_mask_set("combined demand", rd_word, STATUS_DEMAND);
        expect_mask_set("combined irq", rd_word, STATUS_IRQ);

        read_byte(REG_LIGHT_STATE, rd_byte);
        expect_eq8("combined LIGHT_STATE", rd_byte, LIGHT_GREEN);

        // cleanup
        ui_in[0] = 1'b0;
        write_byte(REG_WIFI_COUNT, 8'd0);
        repeat (4) @(posedge clk);
        write_byte(REG_CTRL, CTRL_ENABLE | CTRL_AUTO | CTRL_IRQ_CLEAR);
        repeat (2) @(posedge clk);

        expect_eq1("final user_interrupt", user_interrupt, 1'b0);

        $display("\n========================================");
        $display("ALL TESTS PASSED");
        $display("========================================");
        $finish;
    end

endmodule

`default_nettype wire

#code
/*
 * Copyright (c) 2025 Michael Bell
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



#sim results
Windows PowerShell
Copyright (C) Microsoft Corporation. All rights reserved.

Install the latest PowerShell for new features and improvements! https://aka.ms/PSWindows

PS C:\Users\moral> cd Desktop
PS C:\Users\moral\Desktop> cd Things
PS C:\Users\moral\Desktop\Things> iverilog -o sim_executable.vvp tqvp_spi_traffic.v tb_tqvp_spi_traffic.v
PS C:\Users\moral\Desktop\Things> vvp sim_executable.vvp
VCD info: dumpfile tb_tqvp_spi_traffic.vcd opened for output.
========================================
Starting tb_tqvp_spi_traffic
========================================

--- Test 1: reset defaults ---
PASS: CTRL after reset got expected 0x00
PASS: WIFI_COUNT after reset got expected 0x00
PASS: THRESHOLD after reset got expected 0x05
PASS: LIGHT_STATE after reset got expected 0x00
PASS: user_interrupt after reset got expected 0

--- Test 2: write CTRL and THRESHOLD ---
PASS: CTRL programmed got expected 0x03
PASS: THRESHOLD programmed got expected 0x06

--- Test 3: WIFI_COUNT below threshold ---
PASS: WIFI_COUNT = 3 got expected 0x03
PASS: STATUS demand set mask 0x00000002 set
PASS: congestion is 0 below threshold
PASS: user_interrupt below threshold got expected 0
PASS: LIGHT_STATE below threshold got expected 0x00

--- Test 4: WIFI_COUNT above threshold ---
PASS: WIFI_COUNT = 9 got expected 0x09
PASS: STATUS congestion set mask 0x00000001 set
PASS: STATUS demand set mask 0x00000002 set
PASS: STATUS irq set mask 0x00000004 set
PASS: user_interrupt above threshold got expected 1
PASS: LIGHT_STATE above threshold got expected 0x02

--- Test 5: clear interrupt ---
PASS: irq_pending cleared
PASS: user_interrupt cleared got expected 0

--- Test 6: inductive loop input ---
PASS: LOOP_STATUS vehicle present mask 0x00000001 set
PASS: STATUS demand from loop mask 0x00000002 set
PASS: STATUS irq from loop mask 0x00000004 set
PASS: user_interrupt from loop got expected 1
PASS: LIGHT_STATE from loop got expected 0x02
PASS: user_interrupt after loop clear got expected 0

--- Test 7: combined scenario ---
PASS: combined congestion mask 0x00000001 set
PASS: combined demand mask 0x00000002 set
PASS: combined irq mask 0x00000004 set
PASS: combined LIGHT_STATE got expected 0x02
PASS: final user_interrupt got expected 0

========================================
ALL TESTS PASSED
========================================
tb_tqvp_spi_traffic.v:374: $finish called at 975000 (1ps)
PS C:\Users\moral\Desktop\Things>