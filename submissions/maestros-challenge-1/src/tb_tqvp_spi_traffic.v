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