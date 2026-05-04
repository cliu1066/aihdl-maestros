`timescale 1ns/1ps
`default_nettype none

module tb_tqvp_spi_traffic3;

    // ------------------------------------------------------------
    // DUT interface
    // ------------------------------------------------------------
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

    tqvp_spi_traffic3 dut (
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

    // ------------------------------------------------------------
    // Register map matching DUT
    // ------------------------------------------------------------
    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_THRESHOLD   = 4'd3;
    localparam [3:0] REG_STATUS      = 4'd4;
    localparam [3:0] REG_SPI_STATUS  = 4'd5;
    localparam [3:0] REG_SECURITY    = 4'd6;

    localparam [7:0] CMD_WIFI_WRITE  = 8'hD2; // write=1, class=101, reg=2
    localparam [7:0] CMD_CTRL_WRITE  = 8'hD0; // should be rejected by DUT
    localparam [7:0] CMD_THRESH_WRITE= 8'hD3; // should be rejected by DUT
    localparam [7:0] AUTH_KEY        = 8'h5C;

    integer errors;
    reg [31:0] rd;

    // ------------------------------------------------------------
    // 100 MHz test clock
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // CRC8 helpers: same algorithm as DUT
    // ------------------------------------------------------------
    function [7:0] crc8_byte;
        input [7:0] crc_in;
        input [7:0] data_byte;
        reg   [7:0] crc;
        reg   [7:0] data;
        integer i;
        begin
            crc  = crc_in;
            data = data_byte;
            for (i = 0; i < 8; i = i + 1) begin
                if ((crc[7] ^ data[7]) == 1'b1)
                    crc = {crc[6:0], 1'b0} ^ 8'h07;
                else
                    crc = {crc[6:0], 1'b0};
                data = {data[6:0], 1'b0};
            end
            crc8_byte = crc;
        end
    endfunction

    function [7:0] make_tag;
        input [7:0] cmd;
        input [7:0] dat;
        input [7:0] seq;
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

    // ------------------------------------------------------------
    // Utility tasks
    // ------------------------------------------------------------
    task check;
        input condition;
        input [1023:0] msg;
        begin
            if (condition) begin
                $display("PASS: %0s", msg);
            end else begin
                $display("FAIL: %0s at t=%0t", msg, $time);
                errors = errors + 1;
            end
        end
    endtask

    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    task bus_write;
        input [3:0] reg_addr;
        input [31:0] value;
        begin
            @(negedge clk);
            address      = {reg_addr, 2'b00};
            data_in      = value;
            data_write_n = 2'b00;
            data_read_n  = 2'b11;
            @(negedge clk);
            data_write_n = 2'b11;
            data_in      = 32'd0;
            address      = 6'd0;
        end
    endtask

    task bus_read;
        input  [3:0] reg_addr;
        output [31:0] value;
        begin
            @(negedge clk);
            address      = {reg_addr, 2'b00};
            data_write_n = 2'b11;
            data_read_n  = 2'b00;
            #1 value     = data_out;
            @(negedge clk);
            data_read_n  = 2'b11;
            address      = 6'd0;
        end
    endtask

    task spi_send_bit;
        input bitval;
        begin
            // SPI mode 0 style. DUT samples MOSI on synchronized rising SCK.
            ui_in[3] = bitval;
            #80;
            ui_in[1] = 1'b1;
            #80;
            ui_in[1] = 1'b0;
            #80;
        end
    endtask

    task spi_send_packet_raw;
        input [31:0] packet;
        integer i;
        begin
            ui_in[2] = 1'b1; // CS_N idle high
            ui_in[1] = 1'b0; // SCK low
            ui_in[3] = 1'b0; // MOSI low
            #200;
            ui_in[2] = 1'b0; // CS_N active low
            #200;
            for (i = 31; i >= 0; i = i - 1)
                spi_send_bit(packet[i]);
            #200;
            ui_in[2] = 1'b1; // CS_N inactive
            ui_in[3] = 1'b0;
            #300;
        end
    endtask

    task spi_send_packet;
        input [7:0] cmd;
        input [7:0] dat;
        input [7:0] seq;
        input       corrupt_tag;
        reg [7:0] tag;
        reg [31:0] packet;
        begin
            tag = make_tag(cmd, dat, seq);
            if (corrupt_tag)
                tag = tag ^ 8'h01;
            packet = {cmd, dat, seq, tag};
            spi_send_packet_raw(packet);
        end
    endtask

    // ------------------------------------------------------------
    // Main verification sequence
    // ------------------------------------------------------------
    initial begin
        $dumpfile("tb_tqvp_spi_traffic3.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic3);

        errors       = 0;
        rst_n        = 1'b0;
        ui_in        = 8'b0000_0100; // CS_N high, SCK low, MOSI low, loop low
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        data_ready   = 1'b0;

        wait_cycles(5);
        rst_n = 1'b1;
        wait_cycles(20);

        check(uo_out[0] == 1'b0, "reset/default supplemental request is low");
        check(user_interrupt == 1'b0, "reset/default interrupt is low");

        // Let loop-inactive filter settle with loop detector inactive.
        wait_cycles(25);
        bus_read(REG_LOOP_STATUS, rd);
        check(rd[1] == 1'b1, "loop inactive stable bit eventually asserts when loop input is low");

        // Bus-only configuration: enable design and set threshold.
        bus_write(REG_CTRL, 32'h0000_0001);      // enable, level mode
        bus_write(REG_THRESHOLD, 32'h0000_0008); // threshold = 8
        bus_read(REG_CTRL, rd);
        check(rd[1:0] == 2'b01, "bus can enable CTRL in level mode");
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd8, "bus can set threshold to 8");

        // Threshold clamp test.
        bus_write(REG_THRESHOLD, 32'h0000_0000);
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd1, "bus threshold write of 0 clamps to minimum 1");
        bus_write(REG_THRESHOLD, 32'h0000_0008);

        // Valid authenticated SPI Wi-Fi count update.
        spi_send_packet(CMD_WIFI_WRITE, 8'd10, 8'h01, 1'b0);
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4] == 1'b1, "valid SPI packet makes Wi-Fi reading valid");
        check(rd[3:0] == 4'd10, "valid SPI packet updates Wi-Fi count to 10");
        check(uo_out[1] == 1'b1, "congestion output asserts for count >= threshold");
        check(uo_out[0] == 1'b1, "supplemental request asserts when loop inactive and Wi-Fi demand valid");
        check(user_interrupt == 1'b1, "interrupt latches on Wi-Fi demand rising edge");

        // Clear IRQ while level request remains high. Edge-latched IRQ should stay clear.
        bus_write(REG_CTRL, 32'h0000_0005); // bit0 enable=1, bit2 clear_irq=1
        wait_cycles(4);
        check(uo_out[0] == 1'b1, "level supplemental request remains high after IRQ clear");
        check(user_interrupt == 1'b0, "edge-latched IRQ clears even while demand level remains high");

        // Invalid tag should be rejected and must not change Wi-Fi count.
        spi_send_packet(CMD_WIFI_WRITE, 8'd12, 8'h02, 1'b1);
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[3:0] == 4'd10, "packet with bad tag is rejected and count remains 10");
        bus_read(REG_SECURITY, rd);
        check(rd[16] == 1'b0, "security status reports last tag check failed");

        // Replay same sequence number should be rejected.
        spi_send_packet(CMD_WIFI_WRITE, 8'd11, 8'h01, 1'b0);
        wait_cycles(6);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[3:0] == 4'd10, "replayed sequence number is rejected");
        bus_read(REG_SECURITY, rd);
        check(rd[17] == 1'b0, "security status reports replayed sequence not fresh");

        // SPI should not be able to write threshold even with a valid tag.
        spi_send_packet(CMD_THRESH_WRITE, 8'd1, 8'h03, 1'b0);
        wait_cycles(6);
        bus_read(REG_THRESHOLD, rd);
        check(rd[3:0] == 4'd8, "SPI cannot write threshold; threshold remains bus-owned");

        // SPI should not be able to write CTRL even with a valid tag.
        spi_send_packet(CMD_CTRL_WRITE, 8'd0, 8'h04, 1'b0);
        wait_cycles(6);
        bus_read(REG_CTRL, rd);
        check(rd[1:0] == 2'b01, "SPI cannot write CTRL; enable remains bus-owned");

        // Loop detector active suppresses supplemental request but congestion can remain high.
        ui_in[0] = 1'b1; // loop detector active
        wait_cycles(8);
        check(uo_out[2] == 1'b1, "loop detect status follows active loop input after synchronization");
        wait_cycles(4);
        check(uo_out[1] == 1'b1, "congestion can remain high while loop detector is active");
        check(uo_out[0] == 1'b0, "active loop detector suppresses supplemental Wi-Fi request");

        // Loop inactive again; after filter delay, supplemental request returns and IRQ rises again.
        ui_in[0] = 1'b0;
        wait_cycles(25);
        check(uo_out[0] == 1'b1, "supplemental request returns after loop is stably inactive");
        check(user_interrupt == 1'b1, "new Wi-Fi demand rising edge reasserts IRQ after loop suppression ends");
        bus_write(REG_CTRL, 32'h0000_0005); // clear IRQ again
        wait_cycles(4);
        check(user_interrupt == 1'b0, "IRQ clears after second demand event");

        // Timeout expiration test. The real timeout is intentionally long, so force the
        // internal timeout near expiration to keep simulation fast.
        force dut.wifi_timeout = 16'd1;
        force dut.wifi_timeout_tick_count = 8'hFF;
        wait_cycles(1);
        release dut.wifi_timeout;
        release dut.wifi_timeout_tick_count;
        wait_cycles(3);
        bus_read(REG_WIFI_COUNT, rd);
        check(rd[4] == 1'b0, "Wi-Fi reading becomes invalid after timeout expires");
        check(uo_out[1] == 1'b0, "congestion clears after Wi-Fi timeout");
        check(uo_out[0] == 1'b0, "supplemental request clears after Wi-Fi timeout");

        if (errors == 0) begin
            $display("\nALL TESTS PASSED\n");
        end else begin
            $display("\nTESTS FAILED: %0d error(s)\n", errors);
        end

        $finish;
    end

endmodule

`default_nettype wire
