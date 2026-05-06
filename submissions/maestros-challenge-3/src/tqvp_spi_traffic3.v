/*
 * Copyright (c) 2026 Daniel Onesimo Dong, Candice Liu, April Morales
 * SPDX-License-Identifier: Apache-2.0
 *
 * tqvp_spi_traffic3
 *
 * Register map (byte address):
 *   0x00 REG_CTRL        [1:0] {pulse_mode, enable}        bus-only write
 *   0x04 REG_LOOP_STATUS [1:0] {loop_inactive_stable, loop_detect_r}
 *   0x08 REG_WIFI_COUNT  [4:0] {wifi_valid, count[3:0]}
 *   0x0C REG_THRESHOLD   [3:0] 1-15, default 8            bus-only write
 *   0x10 REG_STATUS      [6:0] status flags
 *   0x14 REG_SPI_STATUS        debug: byte_num, bit_cnt, cmd, flags
 *   0x18 REG_SECURITY          tag/seq/lockout/alert fields
 *
 * SPI packet format (32 bits, Mode 0, MSB first):
 *   Byte 0: cmd   [7]=write  [6:4]=3b101  [3:0]=reg_addr
 *   Byte 1: data  [7:0]
 *   Byte 2: seq   [7:0]  sequence number (replay protection)
 *   Byte 3: tag   [7:0]  = CRC8(KEY, cmd, data, seq)
 *
 * CRC8 polynomial 0x07 (x^8+x^2+x+1).
 * KEY = 0x5C.  CRC_INIT = CRC8(0x00, 0x5C) = 0x93  (pre-computed constant).
 *
 * Pin map:
 *   ui_in[0] = inductive loop detect
 *   ui_in[1] = SPI SCK  (from ESP32)
 *   ui_in[2] = SPI CS_N (from ESP32, active-low)
 *   ui_in[3] = SPI MOSI (from ESP32)
 *   uo_out[0] = supplemental request to external traffic controller
 *   uo_out[1] = WiFi congestion flag
 *   uo_out[2] = filtered loop detect status
 *   uo_out[3] = IRQ pending
 *   uo_out[4] = MISO (tied 0, write-only SPI)
 *   uo_out[7:5] = 0
 */

`default_nettype none

module tqvp_spi_traffic3 #(
    parameter [7:0]  WIFI_TIMEOUT_TICK_MAX = 8'hFF,
    parameter [15:0] WIFI_TIMEOUT_MAX      = 16'hFFFF,
    parameter [15:0] LOCKOUT_CYCLES        = 16'd64   // use 16'hFFFF for tapeout
)(
    input         clk,
    input         rst_n,
    input  [7:0]  ui_in,
    output [7:0]  uo_out,
    input  [5:0]  address,
    input  [31:0] data_in,
    input  [1:0]  data_write_n,
    input  [1:0]  data_read_n,
    output [31:0] data_out,
    input         data_ready,
    output        user_interrupt
);

    // ----------------------------------------------------------------
    // Register addresses
    // ----------------------------------------------------------------
    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_THRESHOLD   = 4'd3;
    localparam [3:0] REG_STATUS      = 4'd4;
    localparam [3:0] REG_SPI_STATUS  = 4'd5;
    localparam [3:0] REG_SECURITY    = 4'd6;

    // ----------------------------------------------------------------
    // Security / protocol constants
    // ----------------------------------------------------------------
    localparam [7:0] SPI_AUTH_KEY      = 8'h5C;
    // CRC_INIT = CRC8(0x00, SPI_AUTH_KEY = 0x5C) = 0x93
    // Pre-computed so the key is never processed in live combinatorial logic.
    localparam [7:0] CRC_INIT          = 8'h93;
    localparam [7:0] SPI_CMD_CLASS_MSK = 8'h70;   // cmd[6:4] mask
    localparam [7:0] SPI_CMD_CLASS     = 8'h50;   // cmd[6:4] must be 3'b101
    localparam [1:0] MAX_SPI_FAILS     = 2'd3;
    localparam [3:0] MIN_THRESHOLD     = 4'd1;
    localparam [3:0] MAX_THRESHOLD     = 4'd15;
    localparam [3:0] PULSE_WIDTH       = 4'd8;

    // ----------------------------------------------------------------
    // CRC8 function — poly 0x07
    // Called once per byte boundary inside a registered block.
    // Max combinatorial depth = 8 XOR levels per call.
    // ----------------------------------------------------------------
    function automatic [7:0] crc8_update;
        input [7:0] crc_in;
        input [7:0] data_byte;
        reg   [7:0] c, d;
        integer     k;
        begin
            c = crc_in;
            d = data_byte;
            for (k = 0; k < 8; k = k + 1) begin
                if (c[7] ^ d[7])
                    c = {c[6:0], 1'b0} ^ 8'h07;
                else
                    c = {c[6:0], 1'b0};
                d = {d[6:0], 1'b0};
            end
            crc8_update = c;
        end
    endfunction

    // ----------------------------------------------------------------
    // Bus decode — explicit clock-gate enables (Design 2 style)
    // ----------------------------------------------------------------
    wire [3:0] reg_sel  = address[5:2];
    wire write_en       = (data_write_n != 2'b11);
    wire read_en        = (data_read_n  != 2'b11);

    wire ctrl_wen       = write_en && (reg_sel == REG_CTRL);
    wire thresh_wen     = write_en && (reg_sel == REG_THRESHOLD);
    wire wifi_bus_wen   = write_en && (reg_sel == REG_WIFI_COUNT);
    wire irq_clear_now  = ctrl_wen && data_in[2];

    // Threshold clamp: 0 maps to 1; 4-bit register can never exceed 15
    wire [3:0] threshold_from_bus =
        (data_in[3:0] == 4'd0) ? MIN_THRESHOLD : data_in[3:0];

    // ----------------------------------------------------------------
    // Inductive loop: 3-stage synchronizer + 15-cycle glitch filter
    // ----------------------------------------------------------------
    reg loop_s1, loop_s2, loop_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            loop_s1   <= 1'b0;
            loop_s2   <= 1'b0;
            loop_sync <= 1'b0;
        end else begin
            loop_s1   <= ui_in[0];
            loop_s2   <= loop_s1;
            loop_sync <= loop_s2;
        end
    end

    reg [3:0] loop_inactive_cnt;
    reg       loop_inactive_stable;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            loop_inactive_cnt    <= 4'd0;
            loop_inactive_stable <= 1'b0;
        end else if (loop_sync) begin
            loop_inactive_cnt    <= 4'd0;
            loop_inactive_stable <= 1'b0;
        end else if (loop_inactive_cnt != 4'hF) begin
            loop_inactive_cnt    <= loop_inactive_cnt + 4'd1;
            loop_inactive_stable <= 1'b0;
        end else begin
            loop_inactive_stable <= 1'b1;
        end
    end

    // ----------------------------------------------------------------
    // SPI input synchronization
    // ----------------------------------------------------------------
    reg spi_sck_s1,  spi_sck_s2;
    reg spi_cs_s1,   spi_cs_s2;
    reg spi_mosi_s1, spi_mosi_s2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_sck_s1  <= 1'b0; spi_sck_s2  <= 1'b0;
            spi_cs_s1   <= 1'b1; spi_cs_s2   <= 1'b1;
            spi_mosi_s1 <= 1'b0; spi_mosi_s2 <= 1'b0;
        end else begin
            spi_sck_s1  <= ui_in[1]; spi_sck_s2  <= spi_sck_s1;
            spi_cs_s1   <= ui_in[2]; spi_cs_s2   <= spi_cs_s1;
            spi_mosi_s1 <= ui_in[3]; spi_mosi_s2 <= spi_mosi_s1;
        end
    end

    wire spi_cs_active = ~spi_cs_s2;
    wire spi_sck_rise  = spi_cs_active && spi_sck_s1 && !spi_sck_s2;

    // ----------------------------------------------------------------
    // SPI packet receiver with incremental CRC
    //
    // 4 bytes received one bit at a time, MSB first (SPI Mode 0).
    //   Byte 0 (cmd):  store, update CRC   → spi_crc = CRC8(INIT, cmd)
    //   Byte 1 (data): store, update CRC   → spi_crc = CRC8(prev, data)
    //   Byte 2 (seq):  store, update CRC   → spi_crc = expected tag
    //   Byte 3 (tag):  store, compare      → spi_tag_match registered
    //
    // spi_new_byte: the complete incoming byte assembled combinatorially.
    // Used once per always-block activation at the byte boundary.
    // ----------------------------------------------------------------
    reg [2:0] spi_bit_cnt;    // bit position within current byte
    reg [1:0] spi_byte_num;   // which byte: 0=cmd 1=dat 2=seq 3=tag
    reg [7:0] spi_byte_buf;   // accumulator for current byte

    reg [7:0] spi_crc;        // running CRC, initialized to CRC_INIT
    reg [7:0] spi_cmd_r;
    reg [7:0] spi_dat_r;
    reg [7:0] spi_seq_r;
    reg [7:0] spi_tag_r;

    reg spi_tag_match;         // registered: received tag == expected tag
    reg spi_pkt_ready;         // one-cycle pulse when byte 3 is latched
    reg spi_frame_done;        // inhibit extra bits after 32 are received
    reg spi_write_seen;        // registered cmd[7] (write flag)
    reg spi_cmd_class_ok_r;    // registered cmd class validity

    // spi_new_byte: the byte assembled by shifting in the new MOSI bit.
    // Evaluated once combinatorially; avoids re-writing the expression
    // in every case branch (reduces synthesis net duplication).
    wire [7:0] spi_new_byte = {spi_byte_buf[6:0], spi_mosi_s2};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_bit_cnt        <= 3'd0;
            spi_byte_num       <= 2'd0;
            spi_byte_buf       <= 8'd0;
            spi_crc            <= CRC_INIT;
            spi_cmd_r          <= 8'd0;
            spi_dat_r          <= 8'd0;
            spi_seq_r          <= 8'd0;
            spi_tag_r          <= 8'd0;
            spi_tag_match      <= 1'b0;
            spi_pkt_ready      <= 1'b0;
            spi_frame_done     <= 1'b0;
            spi_write_seen     <= 1'b0;
            spi_cmd_class_ok_r <= 1'b0;
        end else begin
            spi_pkt_ready <= 1'b0;   // default pulse-low

            if (!spi_cs_active) begin
                // CS_N idle: reset FSM and pre-load CRC with CRC8(0x00, KEY)
                spi_bit_cnt    <= 3'd0;
                spi_byte_num   <= 2'd0;
                spi_byte_buf   <= 8'd0;
                spi_crc        <= CRC_INIT;
                spi_frame_done <= 1'b0;
                spi_tag_match  <= 1'b0;
            end else if (spi_sck_rise && !spi_frame_done) begin
                spi_byte_buf <= spi_new_byte;   // shift in new MOSI bit

                if (spi_bit_cnt == 3'd7) begin
                    // Byte boundary: process completed byte
                    spi_bit_cnt <= 3'd0;

                    case (spi_byte_num)
                        2'd0: begin  // Command byte
                            spi_cmd_r          <= spi_new_byte;
                            spi_write_seen     <= spi_new_byte[7];
                            spi_cmd_class_ok_r <= ((spi_new_byte & SPI_CMD_CLASS_MSK)
                                                    == SPI_CMD_CLASS);
                            // TIMING FIX: CRC updated in registered block
                            // Max comb depth from spi_crc register: 8 XOR levels
                            spi_crc      <= crc8_update(spi_crc, spi_new_byte);
                            spi_byte_num <= 2'd1;
                        end

                        2'd1: begin  // Data byte
                            spi_dat_r    <= spi_new_byte;
                            spi_crc      <= crc8_update(spi_crc, spi_new_byte);
                            spi_byte_num <= 2'd2;
                        end

                        2'd2: begin  // Sequence byte
                            spi_seq_r    <= spi_new_byte;
                            // After this edge: spi_crc = CRC8(INIT,cmd,dat,seq)
                            //                         = expected authentication tag
                            spi_crc      <= crc8_update(spi_crc, spi_new_byte);
                            spi_byte_num <= 2'd3;
                        end

                        2'd3: begin  // Tag byte — compare, do NOT update CRC
                            spi_tag_r  <= spi_new_byte;
                            // TIMING FIX: spi_crc is a stable register here
                            // (set at byte 2 boundary, 8+ clocks earlier).
                            // Compare depth: 8-bit XOR+NOR tree ≈ 3 gate levels.
                            spi_tag_match  <= (spi_new_byte == spi_crc);
                            spi_pkt_ready  <= 1'b1;
                            spi_frame_done <= 1'b1;
                            spi_byte_num   <= 2'd0;
                        end

                        default: spi_byte_num <= 2'd0;
                    endcase
                end else begin
                    spi_bit_cnt <= spi_bit_cnt + 3'd1;
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // Sequence freshness: replay protection
    // ----------------------------------------------------------------
    reg [7:0] last_spi_seq;
    reg       last_spi_seq_valid;
    wire      spi_seq_fresh = !last_spi_seq_valid ||
                              (spi_seq_r != last_spi_seq);

    // ----------------------------------------------------------------
    // SPI brute-force lockout (Design 2 countermeasure, applied to SPI)
    //
    // 3 consecutive bad-tag packets → lockout for LOCKOUT_CYCLES clocks.
    // sec_alert is sticky: cleared only by rst_n.
    // ----------------------------------------------------------------
    reg [1:0]  spi_fail_count;
    reg        spi_lockout_active;
    reg [15:0] spi_lockout_timer;
    reg        sec_alert;
    reg        sec_alert_d;    // for edge detection

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_fail_count     <= 2'd0;
            spi_lockout_active <= 1'b0;
            spi_lockout_timer  <= 16'd0;
            sec_alert          <= 1'b0;
            sec_alert_d        <= 1'b0;
        end else begin
            sec_alert_d <= sec_alert;

            // Lockout countdown
            if (spi_lockout_active) begin
                if (spi_lockout_timer == 16'd0)
                    spi_lockout_active <= 1'b0;
                else
                    spi_lockout_timer <= spi_lockout_timer - 1'b1;
            end

            if (spi_pkt_ready && !spi_lockout_active) begin
                if (spi_tag_match) begin
                    spi_fail_count <= 2'd0;
                end else begin
                    if (spi_fail_count == MAX_SPI_FAILS - 1) begin
                        spi_lockout_active <= 1'b1;
                        spi_lockout_timer  <= LOCKOUT_CYCLES;
                        sec_alert          <= 1'b1;  // sticky
                        spi_fail_count     <= 2'd0;
                    end else begin
                        spi_fail_count <= spi_fail_count + 2'd1;
                    end
                end
            end
        end
    end

    // sec_alert rising edge for IRQ (fires once, then firmware can clear IRQ)
    wire sec_alert_rise = sec_alert && !sec_alert_d;

    // ----------------------------------------------------------------
    // Full packet validation
    // All conditions must hold for a packet to be acted upon.
    // SPI can ONLY write REG_WIFI_COUNT (privilege separation).
    // ----------------------------------------------------------------
    wire spi_is_write = spi_pkt_ready       &&
                        spi_write_seen      &&
                        spi_cmd_class_ok_r  &&
                        spi_tag_match       &&
                        spi_seq_fresh       &&
                        !spi_lockout_active;

    wire spi_wifi_wen = spi_is_write && (spi_cmd_r[3:0] == REG_WIFI_COUNT);

    // ----------------------------------------------------------------
    // Security status registers (REG_SECURITY readback)
    // Bit positions [17:16] kept compatible with Design 3 testbench.
    // ----------------------------------------------------------------
    reg spi_last_tag_ok;        // [16]
    reg spi_last_seq_ok;        // [17]
    reg spi_last_cmd_ok;        // [18]
    reg spi_last_pkt_accepted;  // [19]

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_spi_seq          <= 8'd0;
            last_spi_seq_valid    <= 1'b0;
            spi_last_tag_ok       <= 1'b0;
            spi_last_seq_ok       <= 1'b0;
            spi_last_cmd_ok       <= 1'b0;
            spi_last_pkt_accepted <= 1'b0;
        end else begin
            spi_last_pkt_accepted <= 1'b0;

            if (spi_pkt_ready) begin
                spi_last_tag_ok <= spi_tag_match;
                spi_last_seq_ok <= spi_seq_fresh;
                spi_last_cmd_ok <= spi_write_seen &&
                                   spi_cmd_class_ok_r &&
                                   (spi_cmd_r[3:0] == REG_WIFI_COUNT);

                if (spi_wifi_wen) begin
                    last_spi_seq          <= spi_seq_r;
                    last_spi_seq_valid    <= 1'b1;
                    spi_last_pkt_accepted <= 1'b1;
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // Control register — bus-only, separate clock-gated block
    // ----------------------------------------------------------------
    reg [1:0] ctrl_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ctrl_reg <= 2'b00;
        else if (ctrl_wen) ctrl_reg <= data_in[1:0];
    end

    wire ctrl_enable     = ctrl_reg[0];
    wire ctrl_pulse_mode = ctrl_reg[1];

    // ----------------------------------------------------------------
    // Threshold register — bus-only, clamped 1-15
    // ----------------------------------------------------------------
    reg [3:0] threshold_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) threshold_reg <= 4'd8;
        else if (thresh_wen) threshold_reg <= threshold_from_bus;
    end

    // ----------------------------------------------------------------
    // WiFi count register + freshness timeout with low-power prescaler
    // The 16-bit timeout counter only decrements when the 8-bit prescaler
    // overflows, greatly reducing switching on the wide counter.
    // ----------------------------------------------------------------
    reg [3:0]  wifi_count_reg;
    reg [15:0] wifi_timeout;
    reg [7:0]  wifi_timeout_tick_count;
    reg        wifi_valid;

    wire wifi_timeout_active = (wifi_timeout != 16'd0);
    wire wifi_timeout_tick   = wifi_timeout_active &&
                               (wifi_timeout_tick_count == WIFI_TIMEOUT_TICK_MAX);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wifi_count_reg          <= 4'd0;
            wifi_timeout            <= 16'd0;
            wifi_timeout_tick_count <= 8'd0;
            wifi_valid              <= 1'b0;
        end else if (wifi_bus_wen) begin
            wifi_count_reg          <= data_in[3:0];
            wifi_timeout            <= WIFI_TIMEOUT_MAX;
            wifi_timeout_tick_count <= 8'd0;
            wifi_valid              <= 1'b1;
        end else if (spi_wifi_wen) begin
            wifi_count_reg          <= spi_dat_r[3:0];
            wifi_timeout            <= WIFI_TIMEOUT_MAX;
            wifi_timeout_tick_count <= 8'd0;
            wifi_valid              <= 1'b1;
        end else if (wifi_timeout_active) begin
            wifi_valid <= 1'b1;
            if (wifi_timeout_tick) begin
                wifi_timeout            <= wifi_timeout - 16'd1;
                wifi_timeout_tick_count <= 8'd0;
            end else begin
                wifi_timeout_tick_count <= wifi_timeout_tick_count + 8'd1;
            end
        end else begin
            wifi_timeout_tick_count <= 8'd0;
            wifi_valid              <= 1'b0;
        end
    end

    // ----------------------------------------------------------------
    // Demand / congestion pipeline (Design 2 Fix 1: registered)
    // Breaking the combinatorial path from SPI shift register to output.
    // WiFi supplemental request is suppressed while loop is active.
    // ----------------------------------------------------------------
    wire wifi_above_threshold = wifi_valid &&
                                ctrl_enable &&
                                (wifi_count_reg >= threshold_reg);

    reg congestion_r;
    reg loop_detect_r;
    reg wifi_demand_r;
    reg supplemental_request_level;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            congestion_r               <= 1'b0;
            loop_detect_r              <= 1'b0;
            wifi_demand_r              <= 1'b0;
            supplemental_request_level <= 1'b0;
        end else begin
            congestion_r  <= wifi_above_threshold;
            loop_detect_r <= loop_sync;

            // WiFi request only fires when loop is stably absent
            wifi_demand_r              <= wifi_above_threshold && loop_inactive_stable;
            supplemental_request_level <= wifi_above_threshold && loop_inactive_stable;
        end
    end

    // ----------------------------------------------------------------
    // Optional one-shot pulse mode
    // ----------------------------------------------------------------
    reg        wifi_demand_d;
    reg [3:0]  pulse_count;
    wire wifi_demand_rise = wifi_demand_r && !wifi_demand_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wifi_demand_d <= 1'b0;
            pulse_count   <= 4'd0;
        end else begin
            wifi_demand_d <= wifi_demand_r;
            if (!ctrl_enable)
                pulse_count <= 4'd0;
            else if (wifi_demand_rise)
                pulse_count <= PULSE_WIDTH;
            else if (pulse_count != 4'd0)
                pulse_count <= pulse_count - 4'd1;
        end
    end

    wire supplemental_request_pulse = (pulse_count != 4'd0);
    wire supplemental_request = ctrl_pulse_mode ? supplemental_request_pulse
                                                : supplemental_request_level;

    // ----------------------------------------------------------------
    // Edge-triggered interrupt latch
    // Fires on wifi_demand rising edge OR security alert rising edge.
    // Clearable by software even while demand remains active.
    // sec_alert_rise is used (not sec_alert level) so firmware can
    // acknowledge the event without being stuck in a permanent IRQ loop.
    // ----------------------------------------------------------------
    reg irq_pending;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_pending <= 1'b0;
        else
            irq_pending <= wifi_demand_rise |
                           sec_alert_rise   |
                           (irq_pending & ~irq_clear_now);
    end

    // ----------------------------------------------------------------
    // Read mux — gated by read_en (Design 2: zero switching on idle)
    // ----------------------------------------------------------------
    reg [31:0] read_data;
    always @(*) begin
        if (!read_en) begin
            read_data = 32'd0;
        end else begin
            case (reg_sel)
                REG_CTRL:
                    read_data = {30'd0, ctrl_reg};

                REG_LOOP_STATUS:
                    read_data = {30'd0, loop_inactive_stable, loop_detect_r};

                REG_WIFI_COUNT:
                    read_data = {27'd0, wifi_valid, wifi_count_reg};

                REG_THRESHOLD:
                    read_data = {28'd0, threshold_reg};

                REG_STATUS:
                    read_data = {25'd0,
                                 loop_inactive_stable,  // [6]
                                 wifi_valid,            // [5]
                                 supplemental_request,  // [4]
                                 irq_pending,           // [3]
                                 loop_detect_r,         // [2]
                                 wifi_demand_r,         // [1]
                                 congestion_r};         // [0]

                REG_SPI_STATUS:
                    read_data = {8'd0,
                                 spi_cs_active,     // [23]
                                 spi_frame_done,    // [22]
                                 spi_pkt_ready,     // [21]
                                 spi_write_seen,    // [20]
                                 1'b0,              // [19]
                                 spi_byte_num,      // [18:17]
                                 spi_bit_cnt,       // [16:14]
                                 spi_cmd_r};        // [7:0]

                REG_SECURITY:
                    // Bits [17:16] kept at same positions as Design 3 testbench
                    read_data = {7'd0,
                                 sec_alert,             // [24] sticky alert (Design 2)
                                 spi_lockout_active,    // [23] lockout active (Design 2)
                                 spi_fail_count,        // [22:21] fail counter (Design 2)
                                 last_spi_seq_valid,    // [20]
                                 spi_last_pkt_accepted, // [19]
                                 spi_last_cmd_ok,       // [18]
                                 spi_last_seq_ok,       // [17] — must stay at 17
                                 spi_last_tag_ok,       // [16] — must stay at 16
                                 last_spi_seq,          // [15:8]
                                 spi_tag_r};            // [7:0]

                default:
                    read_data = 32'd0;
            endcase
        end
    end

    // ----------------------------------------------------------------
    // Outputs
    // ----------------------------------------------------------------
    assign data_out       = read_data;
    assign user_interrupt = irq_pending;

    assign uo_out[0] = supplemental_request;
    assign uo_out[1] = congestion_r;
    assign uo_out[2] = loop_detect_r;
    assign uo_out[3] = irq_pending;
    assign uo_out[4] = 1'b0;
    assign uo_out[7:5] = 3'b000;

    wire _unused = &{
        ui_in[7:4],
        address[1:0],
        data_in[31:4],
        data_ready,
        1'b0
    };

endmodule

`default_nettype wire