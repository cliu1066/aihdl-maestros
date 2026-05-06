`timescale 1ns/1ps
`default_nettype none

/*
 * Copyright (c) 2026 Daniel Onesimo Dong, Candice Liu, April Morales
 * SPDX-License-Identifier: Apache-2.0
 */

module tb_tqvp_spi_traffic3;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    reg         clk;
    reg         rst_n;
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg  [5:0]  address;
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    reg         data_ready;
    wire        user_interrupt;

    // Short lockout for simulation speed (production = 16'hFFFF)
    tqvp_spi_traffic3 #(
        .WIFI_TIMEOUT_TICK_MAX(8'hFF),
        .WIFI_TIMEOUT_MAX(16'hFFFF),
        .LOCKOUT_CYCLES(16'd2000)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .ui_in(ui_in), .uo_out(uo_out),
        .address(address), .data_in(data_in),
        .data_write_n(data_write_n), .data_read_n(data_read_n),
        .data_out(data_out), .data_ready(data_ready),
        .user_interrupt(user_interrupt)
    );

    // ----------------------------------------------------------------
    // Register map
    // ----------------------------------------------------------------
    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_THRESHOLD   = 4'd3;
    localparam [3:0] REG_STATUS      = 4'd4;
    localparam [3:0] REG_SPI_STATUS  = 4'd5;
    localparam [3:0] REG_SECURITY    = 4'd6;

    // SPI packet constants
    localparam [7:0] CMD_WIFI_WRITE   = 8'hD2; // write=1, class=101, reg=2
    localparam [7:0] CMD_CTRL_WRITE   = 8'hD0; // rejected: bus-only
    localparam [7:0] CMD_THRESH_WRITE = 8'hD3; // rejected: bus-only
    localparam [7:0] AUTH_KEY         = 8'h5C;

    integer errors;
    reg [31:0] rd;

    // ----------------------------------------------------------------
    // 100 MHz clock
    // ----------------------------------------------------------------
    initial begin clk = 0; forever #5 clk = ~clk; end

    // ----------------------------------------------------------------
    // CRC8 helpers — same algorithm as DUT
    // ----------------------------------------------------------------
    function [7:0] crc8_byte;
        input [7:0] crc_in;
        input [7:0] data_byte;
        reg   [7:0] c, d;
        integer i;
        begin
            c = crc_in; d = data_byte;
            for (i = 0; i < 8; i = i + 1) begin
                if (c[7] ^ d[7]) c = {c[6:0], 1'b0} ^ 8'h07;
                else              c = {c[6:0], 1'b0};
                d = {d[6:0], 1'b0};
            end
            crc8_byte = c;
        end
    endfunction

    function [7:0] make_tag;
        input [7:0] cmd, dat, seq;
        reg [7:0] crc;
        begin
            crc = 8'h00;
            crc = crc8_byte(crc, AUTH_KEY);
            crc = crc8_byte(crc, cmd);
            crc = crc8_byte(crc, dat);
            crc = crc8_byte(crc, seq);
            make_tag = crc;
        end
    endfunction

    // ----------------------------------------------------------------
    // Utility tasks
    // ----------------------------------------------------------------
    task check;
        input condition;
        input [1023:0] msg;
        begin
            if (condition) $display("PASS: %0s", msg);
            else begin
                $display("FAIL: %0s  at t=%0t", msg, $time);
                errors = errors + 1;
            end
        end
    endtask

    task wait_cycles;
        input integer n;
        integer i;
        begin for (i = 0; i < n; i = i + 1) @(posedge clk); end
    endtask

    task bus_write;
        input [3:0] reg_addr;
        input [31:0] value;
        begin
            @(negedge clk);
            address = {reg_addr, 2'b00}; data_in = value;
            data_write_n = 2'b00; data_read_n = 2'b11;
            @(negedge clk);
            data_write_n = 2'b11; data_in = 32'd0; address = 6'd0;
        end
    endtask

    task bus_read;
        input  [3:0]  reg_addr;
        output [31:0] value;
        begin
            @(negedge clk);
            address = {reg_addr, 2'b00}; data_write_n = 2'b11; data_read_n = 2'b00;
            #1 value = data_out;
            @(negedge clk);
            data_read_n = 2'b11; address = 6'd0;
        end
    endtask

    task spi_send_bit;
        input bitval;
        begin
            ui_in[3] = bitval;
            #80; ui_in[1] = 1'b1;
            #80; ui_in[1] = 1'b0;
            #80;
        end
    endtask

    task spi_send_packet_raw;
        input [31:0] packet;
        integer i;
        begin
            ui_in[2] = 1'b1; ui_in[1] = 1'b0; ui_in[3] = 1'b0;
            #200;
            ui_in[2] = 1'b0;  // CS_N active
            #200;
            for (i = 31; i >= 0; i = i - 1) spi_send_bit(packet[i]);
            #200;
            ui_in[2] = 1'b1;  // CS_N inactive
            ui_in[3] = 1'b0;
            #300;
        end
    endtask

    task spi_send_packet;
        input [7:0] cmd, dat, seq;
        input       corrupt_tag;
        reg [7:0]  tag;
        reg [31:0] packet;
        begin
            tag = make_tag(cmd, dat, seq);
            if (corrupt_tag) tag = tag ^ 8'h01;
            packet = {cmd, dat, seq, tag};
            spi_send_packet_raw(packet);
        end
    endtask

    // ----------------------------------------------------------------
    // Test sequence
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("tb_tqvp_spi_traffic3.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic3);

        errors       = 0;
        rst_n        = 1'b0;
        ui_in        = 8'b0000_0100; // CS_N high
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        data_ready   = 1'b0;

        wait_cycles(5);
        rst_n = 1'b1;
        wait_cycles(20);

        // ============================================================
        // T1: Reset defaults
        // ============================================================
        $display("\n--- T1: Reset defaults ---");
        check(uo_out[0] == 1'b0, "supplemental request low after reset");
        check(user_interrupt == 1'b0, "interrupt low after reset");

        // Let loop-inactive filter settle (15 cycles minimum)
        wait_cycles(25);
        bus_read(REG_LOOP_STATUS, rd);
        check(rd[1] == 1'b1, "loop_inactive_stable asserts when loop input is low");

        // ============================================================
        // T2: Bus-only CTRL and THRESHOLD configuration
        // ============================================================
        $display("\n--- T2: Bus CTRL and THRESHOLD config ---");
        bus_write(REG_CTRL,      32'h0000_0001); // enable, level mode
        bus_write(REG_THRESHOLD, 32'h0000_0008); // threshold = 8
        bus_read(REG_CTRL, rd);
        check(rd[1:0] == 2'b01, "bus can set CTRL to enable+level");
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd8, "bus can set threshold to 8");

        // ============================================================
        // T3: Threshold clamp — write 0 → clamps to 1
        // ============================================================
        $display("\n--- T3: Threshold clamp ---");
        bus_write(REG_THRESHOLD, 32'h0000_0000);
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd1, "threshold write of 0 clamps to minimum 1");
        bus_write(REG_THRESHOLD, 32'h0000_0008); // restore

        // ============================================================
        // T4: Valid authenticated SPI WiFi count update
        // ============================================================
        $display("\n--- T4: Valid SPI WiFi count update ---");
        spi_send_packet(CMD_WIFI_WRITE, 8'd10, 8'h01, 1'b0);
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4]   == 1'b1,  "wifi_valid set after authenticated SPI packet");
        check(rd[3:0] == 4'd10, "wifi_count updated to 10 by SPI");
        check(uo_out[1] == 1'b1, "congestion output high (count=10 >= threshold=8)");
        check(uo_out[0] == 1'b1, "supplemental request high (loop inactive, wifi demand)");
        check(user_interrupt == 1'b1, "IRQ latches on wifi_demand rising edge");

        // ============================================================
        // T5: Clear IRQ while demand remains — edge-latched model
        // ============================================================
        $display("\n--- T5: Edge-triggered IRQ clear while demand active ---");
        bus_write(REG_CTRL, 32'h0000_0005); // bit0=enable, bit2=irq_clear
        wait_cycles(4);
        check(uo_out[0] == 1'b1, "supplemental request still high after IRQ clear");
        check(user_interrupt == 1'b0, "edge-latched IRQ cleared even with active demand");

        // ============================================================
        // T6: Bad CRC8 tag rejected
        // ============================================================
        $display("\n--- T6: Bad tag rejected ---");
        spi_send_packet(CMD_WIFI_WRITE, 8'd12, 8'h02, 1'b1); // corrupt tag
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[3:0] == 4'd10, "count unchanged after bad-tag packet");
        bus_read(REG_SECURITY, rd);
        check(rd[16] == 1'b0, "spi_last_tag_ok=0 after bad tag");

        // ============================================================
        // T7: Replay attack — same sequence number rejected
        // ============================================================
        $display("\n--- T7: Replay attack rejected ---");
        spi_send_packet(CMD_WIFI_WRITE, 8'd11, 8'h01, 1'b0); // seq 0x01 reused
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[3:0] == 4'd10, "count unchanged after replayed sequence");
        bus_read(REG_SECURITY, rd);
        check(rd[17] == 1'b0, "spi_last_seq_ok=0 for replayed sequence");

        // ============================================================
        // T8: SPI cannot write REG_THRESHOLD (bus-only)
        // ============================================================
        $display("\n--- T8: SPI cannot write REG_THRESHOLD ---");
        spi_send_packet(CMD_THRESH_WRITE, 8'd1, 8'h03, 1'b0);
        wait_cycles(6);
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd8, "threshold unchanged; SPI cannot write it");

        // ============================================================
        // T9: SPI cannot write REG_CTRL (bus-only)
        // ============================================================
        $display("\n--- T9: SPI cannot write REG_CTRL ---");
        spi_send_packet(CMD_CTRL_WRITE, 8'd0, 8'h04, 1'b0);
        wait_cycles(6);
        bus_read(REG_CTRL, rd);
        check(rd[1:0] == 2'b01, "CTRL unchanged; SPI cannot write it");

        // ============================================================
        // T10: Active loop suppresses supplemental WiFi request
        // ============================================================
        $display("\n--- T10: Active loop suppresses supplemental request ---");
        ui_in[0] = 1'b1;
        wait_cycles(8);
        check(uo_out[2] == 1'b1, "uo_out[2] follows loop input");
        wait_cycles(4);
        check(uo_out[1] == 1'b1, "congestion remains high with loop active");
        check(uo_out[0] == 1'b0, "supplemental request suppressed when loop active");

        // ============================================================
        // T11: Loop inactive → supplemental request returns, IRQ re-fires
        // ============================================================
        $display("\n--- T11: Loop inactive → supp request and IRQ return ---");
        ui_in[0] = 1'b0;
        wait_cycles(25);  // loop_inactive_stable needs 15 cycles
        check(uo_out[0] == 1'b1, "supplemental request returns after loop stably inactive");
        check(user_interrupt == 1'b1, "new wifi_demand rising edge reasserts IRQ");
        bus_write(REG_CTRL, 32'h0000_0005); // clear IRQ
        wait_cycles(4);
        check(user_interrupt == 1'b0, "IRQ cleared after second demand event");

        // ============================================================
        // T12: WiFi timeout — reading becomes invalid
        // ============================================================
        $display("\n--- T12: WiFi data freshness timeout ---");
        // Force timeout counter near expiry to avoid long simulation
        force dut.wifi_timeout = 16'd1;
        force dut.wifi_timeout_tick_count = 8'hFF;
        wait_cycles(1);
        release dut.wifi_timeout;
        release dut.wifi_timeout_tick_count;
        wait_cycles(4);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4] == 1'b0, "wifi_valid cleared after timeout");
        check(uo_out[1] == 1'b0, "congestion clears after WiFi timeout");
        check(uo_out[0] == 1'b0, "supplemental request clears after WiFi timeout");

        // Restore: re-enable for security tests
        bus_write(REG_CTRL, 32'h0000_0001);

        // ============================================================
        // T13: Brute-force lockout — 3 bad tags trigger lockout
        // (fail_count increments on each bad packet)
        // ============================================================
        $display("\n--- T13: Brute-force lockout after 3 bad tags ---");

        bus_read(REG_SECURITY, rd);
        check(rd[22:21] == 2'd0, "fail_count=0 before any bad packets");
        check(rd[23]    == 1'b0, "lockout_active=0 before any bad packets");

        // Bad packet 1
        spi_send_packet(CMD_WIFI_WRITE, 8'd5, 8'h10, 1'b1); // corrupt
        wait_cycles(4);
        bus_read(REG_SECURITY, rd);
        check(rd[22:21] == 2'd1, "fail_count=1 after first bad tag");
        check(rd[23]    == 1'b0, "no lockout yet after 1 bad tag");

        // Bad packet 2
        spi_send_packet(CMD_WIFI_WRITE, 8'd5, 8'h11, 1'b1); // corrupt
        wait_cycles(4);
        bus_read(REG_SECURITY, rd);
        check(rd[22:21] == 2'd2, "fail_count=2 after second bad tag");
        check(rd[23]    == 1'b0, "no lockout yet after 2 bad tags");

        // Bad packet 3 → triggers lockout
        spi_send_packet(CMD_WIFI_WRITE, 8'd5, 8'h12, 1'b1); // corrupt
        wait_cycles(4);
        bus_read(REG_SECURITY, rd);
        check(rd[22:21] == 2'd0, "fail_count reset to 0 on lockout trigger");
        check(rd[23]    == 1'b1, "lockout_active=1 after 3 bad tags");
        check(rd[24]    == 1'b1, "sec_alert=1 (sticky) after lockout trigger");
        check(user_interrupt == 1'b1, "sec_alert rising edge fires IRQ");

        // ============================================================
        // T14: Valid packet rejected during lockout window
        // ============================================================
        $display("\n--- T14: Valid packet rejected during lockout ---");
        spi_send_packet(CMD_WIFI_WRITE, 8'd9, 8'h13, 1'b0); // valid tag
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4]   == 1'b0, "wifi_valid still 0; packet rejected during lockout");
        check(rd[3:0] != 4'd9, "wifi_count not updated to new value during lockout");

        // ============================================================
        // T15: Lockout expires → valid packet accepted again
        // ============================================================
        $display("\n--- T15: Valid packet accepted after lockout expires ---");
        // SPI overhead ~918 cycles already elapsed; timer set to 2000.
        // Remaining ≈ 1082 cycles. Wait 1500 to be certain it has expired.
        wait_cycles(1500);
        bus_read(REG_SECURITY, rd);
        check(rd[23] == 1'b0, "lockout_active cleared after LOCKOUT_CYCLES");
        check(rd[24] == 1'b1, "sec_alert remains sticky after lockout expires");

        spi_send_packet(CMD_WIFI_WRITE, 8'd7, 8'h14, 1'b0); // valid tag, new seq
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4]   == 1'b1, "wifi_valid=1 after valid packet post-lockout");
        check(rd[3:0] == 4'd7, "wifi_count=7 accepted after lockout expired");

        // ============================================================
        // T16: sec_alert sticky — cleared only by rst_n
        // ============================================================
        $display("\n--- T16: sec_alert sticky until reset ---");
        // Try IRQ clear — sec_alert_rise already fired; IRQ clearable now
        bus_write(REG_CTRL, 32'h0000_0005);
        wait_cycles(4);
        bus_read(REG_SECURITY, rd);
        check(rd[24] == 1'b1, "sec_alert still set after IRQ clear (sticky)");

        // Hardware reset clears sec_alert
        rst_n = 1'b0;
        wait_cycles(4);
        rst_n = 1'b1;
        wait_cycles(5);
        bus_read(REG_SECURITY, rd);
        check(rd[24] == 1'b0, "sec_alert cleared after rst_n");
        check(rd[23] == 1'b0, "lockout_active cleared after rst_n");
        check(rd[22:21] == 2'd0, "fail_count cleared after rst_n");
        check(user_interrupt == 1'b0, "IRQ cleared after rst_n");

        // ============================================================
        // T17: Design functional after reset + full packet path check
        // ============================================================
        $display("\n--- T17: Full functional check after reset ---");
        wait_cycles(25);  // loop_inactive_stable
        bus_write(REG_CTRL,      32'h0000_0001);
        bus_write(REG_THRESHOLD, 32'h0000_0008);

        spi_send_packet(CMD_WIFI_WRITE, 8'd10, 8'h01, 1'b0);
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4]   == 1'b1,  "wifi_valid after reset + valid packet");
        check(rd[3:0] == 4'd10, "wifi_count=10 after reset + valid packet");
        check(uo_out[1] == 1'b1, "congestion high after reset + count=10");
        check(user_interrupt == 1'b1, "IRQ fires after reset on new demand");

        bus_read(REG_SECURITY, rd);
        // spi_last_pkt_accepted is a one-cycle pulse; check sticky flags instead
        check(rd[16] == 1'b1, "spi_last_tag_ok=1 (sticky) after valid packet");
        check(rd[16] == 1'b1, "spi_last_tag_ok=1 for valid packet");
        check(rd[17] == 1'b1, "spi_last_seq_ok=1 for fresh sequence");

        // ============================================================
        $display("\n============================================");
        if (errors == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  TESTS FAILED: %0d error(s)", errors);
        $display("============================================");
        $finish;
    end

endmodule

`default_nettype wire