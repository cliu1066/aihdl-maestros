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
    reg         data_ready;   // input to DUT, driven by TB
    wire        user_interrupt;

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
        .clk(clk), .rst_n(rst_n),
        .ui_in(ui_in), .uo_out(uo_out),
        .address(address), .data_in(data_in),
        .data_write_n(data_write_n), .data_read_n(data_read_n),
        .data_out(data_out), .data_ready(data_ready),
        .user_interrupt(user_interrupt)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

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
        input  [3:0]  reg_addr;
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
        input [31:0]  actual;
        input [31:0]  expected;
    begin
        if (actual !== expected) begin
            $display("FAIL: %0s | expected=0x%08h actual=0x%08h", name, expected, actual);
            errors = errors + 1;
        end else
            $display("PASS: %0s | 0x%08h", name, actual);
    end
    endtask

    reg [31:0] readback;

    initial begin
        $dumpfile("tb_tqvp_spi_traffic2.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic2);
        errors       = 0;
        rst_n        = 0;
        ui_in        = 8'd0;
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        data_ready   = 1'b1;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // ----------------------------------------------------------
        // Test 1: Reset state
        // ----------------------------------------------------------
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
            $display("FAIL: user_interrupt high after reset");
            errors = errors + 1;
        end else
            $display("PASS: user_interrupt low after reset");

        if (uo_out !== 8'h01) begin
            $display("FAIL: uo_out expected 0x01 got 0x%02h", uo_out);
            errors = errors + 1;
        end else
            $display("PASS: uo_out idle = 0x01");

        // ----------------------------------------------------------
        // Test 2: Enable + AUTO mode, no traffic
        // ----------------------------------------------------------
        $display("\n--- Test 2: Enable auto mode, no demand ---");

        bus_write(REG_CTRL, 32'h00000003);  // enable=1 auto=1
        bus_read(REG_CTRL, readback);
        check_value("CTRL enable+auto", readback, 32'h00000003);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE no demand", readback, {24'd0, LIGHT_RED});

        bus_read(REG_STATUS, readback);
        check_value("STATUS no demand", readback, 32'd0);

        // ----------------------------------------------------------
        // Test 3: WiFi count below threshold (count=5, threshold=8)
        // Fix 1 adds one register stage: need extra clocks for
        // congestion_r and irq to propagate.
        // ----------------------------------------------------------
        $display("\n--- Test 3: WiFi count below threshold (5 < 8) ---");

        bus_write(REG_WIFI_COUNT, 32'd5);
        repeat (4) @(posedge clk);   // +2 for Fix 1 pipeline

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT = 5", readback, 32'd5);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE wifi count 5", readback, {24'd0, LIGHT_RED});

        // demand=1 (count!=0), congestion=0 (bit[3]=0), irq=0
        bus_read(REG_STATUS, readback);
        check_value("STATUS wifi count 5", readback, 32'h00000002);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: user_interrupt high below threshold");
            errors = errors + 1;
        end else
            $display("PASS: user_interrupt low below threshold");

        // ----------------------------------------------------------
        // Test 4: WiFi congestion at threshold (count=8, bit[3]=1)
        // Two-stage pipeline: wifi_count_reg -> congestion_r -> irq_pending
        // Need 4+ clocks for full propagation.
        // ----------------------------------------------------------
        $display("\n--- Test 4: WiFi congestion at threshold (8) ---");

        bus_write(REG_WIFI_COUNT, 32'd8);
        repeat (4) @(posedge clk);

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT = 8", readback, 32'd8);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE wifi count 8", readback, {24'd0, LIGHT_GREEN});

        // congestion=1 demand=1 irq=1 -> STATUS = 0x07
        bus_read(REG_STATUS, readback);
        check_value("STATUS wifi congestion", readback, 32'h00000007);

        if (user_interrupt !== 1'b1) begin
            $display("FAIL: user_interrupt low during congestion");
            errors = errors + 1;
        end else
            $display("PASS: user_interrupt high during congestion");

        // ----------------------------------------------------------
        // Test 5: Clear interrupt after removing source
        // ----------------------------------------------------------
        $display("\n--- Test 5: Clear interrupt after congestion removed ---");

        bus_write(REG_WIFI_COUNT, 32'd0);
        repeat (4) @(posedge clk);   // let congestion_r drain

        // bit[2]=1 clears IRQ; keep enable+auto
        bus_write(REG_CTRL, 32'h00000007);
        repeat (4) @(posedge clk);

        bus_read(REG_STATUS, readback);
        check_value("STATUS after IRQ clear", readback, 32'd0);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: user_interrupt still high after clear");
            errors = errors + 1;
        end else
            $display("PASS: user_interrupt cleared");

        // Remove the irq_clear pulse bit for subsequent tests
        bus_write(REG_CTRL, 32'h00000003);

        // ----------------------------------------------------------
        // Test 6: Inductive loop detector only (WiFi count = 0)
        // Three register stages: ui_in->loop_s1->loop_s2->loop_detect_r
        // Need at least 4 clocks.
        // ----------------------------------------------------------
        $display("\n--- Test 6: External loop detector input ---");

        ui_in[0] = 1'b1;
        repeat (5) @(posedge clk);  // 3-stage pipeline + margin

        bus_read(REG_LOOP_STATUS, readback);
        check_value("LOOP_STATUS active", readback, 32'd1);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE loop active", readback, {24'd0, LIGHT_GREEN});

        // loop only: demand=1 irq=1 congestion=0 -> 0x06
        bus_read(REG_STATUS, readback);
        check_value("STATUS loop active", readback, 32'h00000006);

        if (user_interrupt !== 1'b1) begin
            $display("FAIL: user_interrupt low from loop trigger");
            errors = errors + 1;
        end else
            $display("PASS: user_interrupt high from loop trigger");

        // ----------------------------------------------------------
        // Test 7: AUTO disabled -> light forced RED regardless of traffic
        // ----------------------------------------------------------
        $display("\n--- Test 7: Auto disabled forces red light ---");

        bus_write(REG_CTRL, 32'h00000001);  // enable=1 auto=0
        repeat (2) @(posedge clk);

        bus_read(REG_CTRL, readback);
        check_value("CTRL enable only", readback, 32'h00000001);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE auto disabled", readback, {24'd0, LIGHT_RED});

        // ----------------------------------------------------------
        // Test 8: Disable system entirely
        // irq_pending was set by loop in test 6, never explicitly cleared,
        // so it persists. ctrl_enable=0 kills demand+congestion but not
        // the latched irq. STATUS expected = 0x04 (irq bit only).
        // ----------------------------------------------------------
        $display("\n--- Test 8: Disable system ---");

        ui_in[0] = 1'b0;
        repeat (5) @(posedge clk);  // let loop_detect_r drain

        bus_write(REG_CTRL,       32'h00000000);
        bus_write(REG_WIFI_COUNT, 32'd15);
        repeat (4) @(posedge clk);

        bus_read(REG_LIGHT_STATE, readback);
        check_value("LIGHT_STATE disabled", readback, {24'd0, LIGHT_RED});

        // ctrl_enable=0 -> congestion=0 demand=0; irq_pending still set
        bus_read(REG_STATUS, readback);
        check_value("STATUS disabled wifi 15", readback, 32'h00000004);

        // ----------------------------------------------------------
        // Test 9: THRESHOLD register is reserved, always reads 0
        // ----------------------------------------------------------
        $display("\n--- Test 9: THRESHOLD reserved ---");

        bus_write(REG_THRESHOLD, 32'hFFFFFFFF);
        repeat (2) @(posedge clk);
        bus_read(REG_THRESHOLD, readback);
        check_value("THRESHOLD reads 0 after write", readback, 32'd0);

        // ----------------------------------------------------------
        // Test 10: Write truncation (4-bit count, 0xFF -> 0x0F)
        // ----------------------------------------------------------
        $display("\n--- Test 10: Write truncation (0xFF -> 0x0F) ---");

        bus_write(REG_CTRL,       32'h00000003);  // re-enable
        bus_write(REG_WIFI_COUNT, 32'hFF);
        repeat (2) @(posedge clk);

        bus_read(REG_WIFI_COUNT, readback);
        check_value("WIFI_COUNT truncated to 0x0F", readback, 32'h0000000F);

        // ----------------------------------------------------------
        // Test 11: IRQ sticky - re-asserts if cleared while source active
        // ----------------------------------------------------------
        $display("\n--- Test 11: IRQ sticky while source active ---");

        bus_write(REG_WIFI_COUNT, 32'd10);  // congestion (bit[3]=1)
        repeat (4) @(posedge clk);

        if (user_interrupt !== 1'b1) begin
            $display("FAIL: irq not raised with count=10");
            errors = errors + 1;
        end else
            $display("PASS: irq raised for count=10");

        // Try to clear while source still active
        bus_write(REG_CTRL, 32'h00000007);  // bit[2]=irq_clear + enable + auto
        repeat (4) @(posedge clk);

        bus_read(REG_STATUS, readback);
        if (readback[2] !== 1'b1) begin
            $display("FAIL: irq should re-assert while source active, STATUS=0x%08h", readback);
            errors = errors + 1;
        end else
            $display("PASS: irq re-asserts while source active");

        // Remove source, then clear
        bus_write(REG_WIFI_COUNT, 32'd0);
        repeat (4) @(posedge clk);
        bus_write(REG_CTRL, 32'h00000007);
        repeat (4) @(posedge clk);

        if (user_interrupt !== 1'b0) begin
            $display("FAIL: irq still set after source+clear");
            errors = errors + 1;
        end else
            $display("PASS: irq cleared after source removed and clear pulsed");

        // ----------------------------------------------------------
        // Done
        // ----------------------------------------------------------
        $display("\n==========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);
        $display("==========================================");
        $finish;
    end

endmodule

`default_nettype wire