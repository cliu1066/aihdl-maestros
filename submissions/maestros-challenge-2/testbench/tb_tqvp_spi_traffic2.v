`default_nettype none

module tb_tqvp_spi_traffic2;

    reg         clk;
    reg         rst_n;
    reg  [7:0]  ui_in;
    wire [7:0]  uo_out;
    reg  [5:0]  address;
    reg  [31:0] data_in;
    reg  [1:0]  data_write_n;
    reg  [1:0]  data_read_n;
    wire [31:0] data_out;
    wire        data_ready;
    wire        user_interrupt;

    // Register addresses from DUT
    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_LIGHT_STATE = 4'd3;
    localparam [3:0] REG_THRESHOLD   = 4'd4;
    localparam [3:0] REG_STATUS      = 4'd5;

    localparam [7:0] LIGHT_RED   = 8'd0;
    localparam [7:0] LIGHT_GREEN = 8'd2;

    integer errors;

    tqvp_spi_traffic2 dut (
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

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

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
        end
    endtask

    task bus_read;
        input [3:0] reg_addr;
        output [31:0] value;
        begin
            @(negedge clk);
            address      = {reg_addr, 2'b00};
            data_write_n = 2'b11;
            data_read_n  = 2'b00;

            #1;
            value = data_out;

            @(negedge clk);
            data_read_n = 2'b11;
        end
    endtask

    task check_value;
        input [255:0] name;
        input [31:0] actual;
        input [31:0] expected;
        begin
            if (actual !== expected) begin
                $display("FAIL: %0s | expected = 0x%08h, actual = 0x%08h",
                         name, expected, actual);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s | value = 0x%08h", name, actual);
            end
        end
    endtask

    reg [31:0] readback;

    initial begin
        $dumpfile("tqvp_spi_traffic2_tb.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic2);

        errors = 0;

        // Initial values
        rst_n        = 1'b0;
        ui_in        = 8'd0;
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("\n--- Test 1: Reset state ---");

        bus_read(REG_CTRL, readback);
        check_value("CTRL after reset", readback, 32'd0);

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT after reset", readback, 32'd0);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE after reset", readback, {24'd0, LIGHT_RED});

        bus_read(REG_STATUS, readback);
        check_value("STATUS after reset", readback, 32'd0);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: user_interrupt should be low after reset");
            errors = errors + 1;
        end else begin
            $display("PASS: user_interrupt low after reset");
        end

        if (uo_out !== 8'h01) begin
            $display("FAIL: uo_out expected 0x01, got 0x%02h", uo_out);
            errors = errors + 1;
        end else begin
            $display("PASS: uo_out idle value is 0x01");
        end

        $display("\n--- Test 2: Enable auto mode, no demand ---");

        // ctrl_reg[0] = enable
        // ctrl_reg[1] = auto
        bus_write(REG_CTRL, 32'h00000003);

        bus_read(REG_CTRL, readback);
        check_value("CTRL enable + auto", readback, 32'h00000003);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE no demand", readback, {24'd0, LIGHT_RED});

        bus_read(REG_STATUS, readback);
        check_value("STATUS no demand", readback, 32'd0);

        $display("\n--- Test 3: WiFi count below threshold ---");

        // wifi_count = 5
        // demand_present should be 1 because count != 0
        // congestion_present should be 0 because count < 8
        // trigger should be 0 because no congestion and no loop detect
        bus_write(REG_WIFI_COUNT, 32'd5);
        repeat (2) @(posedge clk);

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT = 5", readback, 32'd5);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE wifi count 5", readback, {24'd0, LIGHT_RED});

        bus_read(REG_STATUS, readback);
        check_value("STATUS wifi count 5", readback, 32'b00000000000000000000000000000010);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: user_interrupt should be low for wifi count 5");
            errors = errors + 1;
        end else begin
            $display("PASS: user_interrupt low for wifi count 5");
        end

        $display("\n--- Test 4: WiFi congestion at threshold ---");

        // wifi_count = 8
        // bit[3] = 1, so congestion_present = 1
        // trigger = 1
        // light should become green
        // irq_pending should become 1
        bus_write(REG_WIFI_COUNT, 32'd8);
        repeat (2) @(posedge clk);

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT = 8", readback, 32'd8);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE wifi count 8", readback, {24'd0, LIGHT_GREEN});

        bus_read(REG_STATUS, readback);
        check_value("STATUS wifi congestion", readback, 32'b00000000000000000000000000000111);

        if (user_interrupt !== 1'b1) begin
            $display("FAIL: user_interrupt should be high during congestion");
            errors = errors + 1;
        end else begin
            $display("PASS: user_interrupt high during congestion");
        end

        $display("\n--- Test 5: Clear interrupt after congestion removed ---");

        // Remove congestion first
        bus_write(REG_WIFI_COUNT, 32'd0);
        repeat (2) @(posedge clk);

        // Write bit[2] of REG_CTRL to clear IRQ.
        // Also keep enable + auto bits set.
        bus_write(REG_CTRL, 32'h00000007);
        repeat (2) @(posedge clk);

        bus_read(REG_STATUS, readback);
        check_value("STATUS after IRQ clear", readback, 32'd0);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: user_interrupt should be low after clear");
            errors = errors + 1;
        end else begin
            $display("PASS: user_interrupt cleared");
        end

        $display("\n--- Test 6: External loop detector input ---");

        // ui_in[0] is loop detector.
        // Two flip-flop synchronizer means wait a few clocks.
        ui_in[0] = 1'b1;
        repeat (4) @(posedge clk);

        bus_read(REG_LOOP_STATUS, readback);
        check_value("LOOP_STATUS active", readback, 32'd1);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE loop active", readback, {24'd0, LIGHT_GREEN});

        bus_read(REG_STATUS, readback);
        check_value("STATUS loop active", readback, 32'b00000000000000000000000000000110);

        if (user_interrupt !== 1'b1) begin
            $display("FAIL: user_interrupt should be high from loop trigger");
            errors = errors + 1;
        end else begin
            $display("PASS: user_interrupt high from loop trigger");
        end

        $display("\n--- Test 7: Auto disabled forces red light ---");

        // Keep enable = 1, auto = 0
        // Loop is still active, but readback light state should be red because ctrl_auto = 0.
        bus_write(REG_CTRL, 32'h00000001);
        repeat (2) @(posedge clk);

        bus_read(REG_CTRL, readback);
        check_value("CTRL enable only", readback, 32'h00000001);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE auto disabled", readback, {24'd0, LIGHT_RED});

        $display("\n--- Test 8: Disable system ---");

        ui_in[0] = 1'b0;
        repeat (4) @(posedge clk);

        bus_write(REG_CTRL, 32'h00000000);
        bus_write(REG_WIFI_COUNT, 32'd15);
        repeat (2) @(posedge clk);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE disabled", readback, {24'd0, LIGHT_RED});

        bus_read(REG_STATUS, readback);
        check_value("STATUS disabled with wifi count 15", readback, 32'b00000000000000000000000000000100);

        $display("\n--- Simulation finished ---");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end

endmodule

`default_nettype wire