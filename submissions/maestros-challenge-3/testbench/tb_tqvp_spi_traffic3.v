`timescale 1ns/1ps
`default_nettype none

module tb_tqvp_spi_traffic3;

    // ------------------------------------------------------------
    // DUT signals
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

    // ------------------------------------------------------------
    // Register map, must match DUT
    // ------------------------------------------------------------

    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_THRESHOLD   = 4'd3;
    localparam [3:0] REG_STATUS      = 4'd4;
    localparam [3:0] REG_SPI_STATUS  = 4'd5;

    // ------------------------------------------------------------
    // External pin map, must match DUT
    // ------------------------------------------------------------

    localparam integer PIN_LOOP_DETECT = 0;
    localparam integer PIN_SPI_SCK     = 1;
    localparam integer PIN_SPI_CS_N    = 2;
    localparam integer PIN_SPI_MOSI    = 3;

    // ------------------------------------------------------------
    // Output pin map, must match DUT
    // ------------------------------------------------------------

    localparam integer OUT_REQUEST    = 0;
    localparam integer OUT_CONGESTION = 1;
    localparam integer OUT_LOOP       = 2;
    localparam integer OUT_IRQ        = 3;

    // ------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------

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
    // Clock generation
    // 100 MHz simulation clock, 10 ns period
    // ------------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Test bookkeeping
    // ------------------------------------------------------------

    integer errors;

    task check_bit;
        input value;
        input expected;
        input [255:0] name;
        begin
            if (value !== expected) begin
                $display("FAIL: %0s expected %b got %b at time %0t",
                         name, expected, value, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s = %b at time %0t",
                         name, value, $time);
            end
        end
    endtask

    task check_4bit;
        input [3:0] value;
        input [3:0] expected;
        input [255:0] name;
        begin
            if (value !== expected) begin
                $display("FAIL: %0s expected 0x%0h got 0x%0h at time %0t",
                         name, expected, value, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s = 0x%0h at time %0t",
                         name, value, $time);
            end
        end
    endtask

    // ------------------------------------------------------------
    // TinyQV bus write task
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // TinyQV bus read task
    // ------------------------------------------------------------

    task bus_read;
        input [3:0] reg_addr;
        begin
            @(negedge clk);
            address      = {reg_addr, 2'b00};
            data_write_n = 2'b11;
            data_read_n  = 2'b00;

            #1;
            $display("BUS READ reg %0d = 0x%08x at time %0t",
                     reg_addr, data_out, $time);

            @(negedge clk);
            data_read_n = 2'b11;
        end
    endtask

    // ------------------------------------------------------------
    // SPI helper tasks
    //
    // DUT expects SPI mode 0:
    // CPOL = 0
    // CPHA = 0
    //
    // Data is sampled on rising SCK while CS_N is low.
    // Send MSB first.
    // ------------------------------------------------------------

    task spi_send_bit;
        input bit_value;
        begin
            ui_in[PIN_SPI_MOSI] = bit_value;

            // Keep values stable for multiple clk cycles so the DUT
            // synchronizers can safely sample them.
            #40;
            ui_in[PIN_SPI_SCK] = 1'b1;
            #80;
            ui_in[PIN_SPI_SCK] = 1'b0;
            #40;
        end
    endtask

    task spi_send_byte;
        input [7:0] byte_value;
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                spi_send_bit(byte_value[i]);
            end
        end
    endtask

    task spi_write_reg;
        input [3:0] reg_addr;
        input [7:0] value;
        reg [7:0] cmd;
        begin
            cmd = {4'b1000, reg_addr};

            $display("SPI WRITE reg %0d <= 0x%02x at time %0t",
                     reg_addr, value, $time);

            // Assert CS_N low
            #80;
            ui_in[PIN_SPI_CS_N] = 1'b0;
            ui_in[PIN_SPI_SCK]  = 1'b0;
            #80;

            spi_send_byte(cmd);
            spi_send_byte(value);

            // Deassert CS_N
            #80;
            ui_in[PIN_SPI_CS_N] = 1'b1;
            ui_in[PIN_SPI_MOSI] = 1'b0;
            ui_in[PIN_SPI_SCK]  = 1'b0;
            #160;
        end
    endtask

    // ------------------------------------------------------------
    // Wait helper
    // ------------------------------------------------------------

    task wait_clks;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------

    initial begin
        $dumpfile("tb_tqvp_spi_traffic3.vcd");
        $dumpvars(0, tb_tqvp_spi_traffic3);

        errors = 0;

        // Initial values
        rst_n        = 1'b0;
        ui_in        = 8'd0;
        address      = 6'd0;
        data_in      = 32'd0;
        data_write_n = 2'b11;
        data_read_n  = 2'b11;
        data_ready   = 1'b0;

        // SPI idle state
        ui_in[PIN_SPI_CS_N] = 1'b1;
        ui_in[PIN_SPI_SCK]  = 1'b0;
        ui_in[PIN_SPI_MOSI] = 1'b0;

        wait_clks(5);
        rst_n = 1'b1;
        wait_clks(5);

        $display("");
        $display("====================================================");
        $display("TEST 1: Reset state");
        $display("====================================================");

        check_bit(uo_out[OUT_REQUEST],    1'b0, "request after reset");
        check_bit(uo_out[OUT_CONGESTION], 1'b0, "congestion after reset");
        check_bit(uo_out[OUT_LOOP],       1'b0, "loop status after reset");
        check_bit(uo_out[OUT_IRQ],        1'b0, "irq output after reset");
        check_bit(user_interrupt,         1'b0, "user_interrupt after reset");

        $display("");
        $display("====================================================");
        $display("TEST 2: Enable controller and set threshold through SPI");
        $display("====================================================");

        // CTRL = 1 means enable, level-request mode
        spi_write_reg(REG_CTRL, 8'h01);

        // Threshold = 8
        spi_write_reg(REG_THRESHOLD, 8'h08);

        wait_clks(10);

        bus_read(REG_CTRL);
        check_4bit(data_out[3:0], 4'h1, "CTRL register after SPI write");

        bus_read(REG_THRESHOLD);
        check_4bit(data_out[3:0], 4'h8, "THRESHOLD register after SPI write");

        $display("");
        $display("====================================================");
        $display("TEST 3: Wi-Fi count below threshold");
        $display("====================================================");

        // Wi-Fi count = 5, below threshold 8
        spi_write_reg(REG_WIFI_COUNT, 8'h05);
        wait_clks(10);

        bus_read(REG_WIFI_COUNT);
        check_4bit(data_out[3:0], 4'h5, "WIFI_COUNT below threshold");

        check_bit(uo_out[OUT_CONGESTION], 1'b0, "congestion below threshold");
        check_bit(uo_out[OUT_REQUEST],    1'b0, "request below threshold");
        check_bit(user_interrupt,         1'b0, "interrupt below threshold");

        $display("");
        $display("====================================================");
        $display("TEST 4: Wi-Fi count above threshold, loop inactive");
        $display("====================================================");

        // Loop inactive
        ui_in[PIN_LOOP_DETECT] = 1'b0;
        wait_clks(5);

        // Wi-Fi count = 10, above threshold 8
        spi_write_reg(REG_WIFI_COUNT, 8'h0A);
        wait_clks(10);

        check_bit(uo_out[OUT_CONGESTION], 1'b1, "congestion above threshold");
        check_bit(uo_out[OUT_LOOP],       1'b0, "loop inactive");
        check_bit(uo_out[OUT_REQUEST],    1'b1, "request above threshold with loop inactive");
        check_bit(user_interrupt,         1'b1, "interrupt latched from Wi-Fi demand");

        bus_read(REG_STATUS);
        check_bit(data_out[4], 1'b1, "STATUS supplemental_request");
        check_bit(data_out[3], 1'b1, "STATUS irq_pending");
        check_bit(data_out[2], 1'b0, "STATUS loop_detect");
        check_bit(data_out[1], 1'b1, "STATUS wifi_demand");
        check_bit(data_out[0], 1'b1, "STATUS congestion");

        $display("");
        $display("====================================================");
        $display("TEST 5: Loop detect active suppresses supplemental request");
        $display("====================================================");

        // Activate loop detector. Original 555/controller is assumed
        // to handle this, so TinyQV should suppress Wi-Fi request.
        ui_in[PIN_LOOP_DETECT] = 1'b1;
        wait_clks(10);

        check_bit(uo_out[OUT_CONGESTION], 1'b1, "congestion still true while loop active");
        check_bit(uo_out[OUT_LOOP],       1'b1, "loop detect active");
        check_bit(uo_out[OUT_REQUEST],    1'b0, "request suppressed while loop active");

        // Interrupt is still high because it latched earlier.
        check_bit(user_interrupt, 1'b1, "interrupt still latched before clear");

        $display("");
        $display("====================================================");
        $display("TEST 6: Clear interrupt while loop is active");
        $display("====================================================");

        // Write CTRL with bit[2] = 1 to clear irq.
        // Keep enable bit set with value 0b101 = 0x5.
        bus_write(REG_CTRL, 32'h00000005);
        wait_clks(5);

        check_bit(user_interrupt, 1'b0, "interrupt cleared");
        check_bit(uo_out[OUT_IRQ], 1'b0, "irq output cleared");
        check_bit(uo_out[OUT_REQUEST], 1'b0, "request remains suppressed with loop active");

        $display("");
        $display("====================================================");
        $display("TEST 7: Loop goes inactive again; Wi-Fi demand reasserts request");
        $display("====================================================");

        ui_in[PIN_LOOP_DETECT] = 1'b0;
        wait_clks(10);

        check_bit(uo_out[OUT_LOOP],    1'b0, "loop inactive again");
        check_bit(uo_out[OUT_REQUEST], 1'b1, "request reasserts after loop inactive");
        check_bit(user_interrupt,      1'b1, "interrupt reasserts after loop inactive");

        $display("");
        $display("====================================================");
        $display("TEST 8: Raise threshold above Wi-Fi count");
        $display("====================================================");

        // Threshold = 12, Wi-Fi count remains 10, so congestion clears.
        spi_write_reg(REG_THRESHOLD, 8'h0C);
        wait_clks(10);

        check_bit(uo_out[OUT_CONGESTION], 1'b0, "congestion clears when threshold raised");
        check_bit(uo_out[OUT_REQUEST],    1'b0, "request clears when threshold raised");

        // Clear old interrupt.
        bus_write(REG_CTRL, 32'h00000005);
        wait_clks(5);
        check_bit(user_interrupt, 1'b0, "interrupt cleared after threshold raise");

        $display("");
        $display("====================================================");
        $display("TEST 9: Pulse request mode");
        $display("====================================================");

        // Enable pulse mode:
        // ctrl_reg[0] = 1 enable
        // ctrl_reg[1] = 1 pulse mode
        spi_write_reg(REG_CTRL, 8'h03);

        // Restore threshold = 8
        spi_write_reg(REG_THRESHOLD, 8'h08);

        // Drop Wi-Fi below threshold first to create a clean rising edge later.
        spi_write_reg(REG_WIFI_COUNT, 8'h02);
        wait_clks(10);

        check_bit(uo_out[OUT_REQUEST], 1'b0, "pulse mode request low before demand");

        // Clear interrupt before pulse test.
        // Keep pulse mode enabled: bits [1:0] = 2'b11, bit[2] = clear.
        bus_write(REG_CTRL, 32'h00000007);
        wait_clks(5);
        check_bit(user_interrupt, 1'b0, "interrupt cleared before pulse test");

        // Now Wi-Fi count rises above threshold.
        spi_write_reg(REG_WIFI_COUNT, 8'h0A);

        // Request should pulse high briefly.
        wait_clks(3);
        check_bit(uo_out[OUT_REQUEST], 1'b1, "pulse request asserted after demand edge");

        // PULSE_WIDTH is 8 DUT clocks. Wait long enough for it to expire.
        wait_clks(20);
        check_bit(uo_out[OUT_REQUEST], 1'b0, "pulse request expired");
        check_bit(user_interrupt,      1'b1, "interrupt latched after pulse demand");

        $display("");
        $display("====================================================");
        $display("TEST SUMMARY");
        $display("====================================================");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TESTS FAILED: %0d error(s)", errors);
        end

        $finish;
    end

endmodule

`default_nettype wire