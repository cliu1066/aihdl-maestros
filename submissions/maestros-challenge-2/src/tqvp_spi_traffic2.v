`default_nettype none

module tqvp_spi_traffic2 (
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

    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_LIGHT_STATE = 4'd3;
    localparam [3:0] REG_THRESHOLD   = 4'd4;
    localparam [3:0] REG_STATUS      = 4'd5;

    // ----------------------------------------------------------------
    // Synchronizer for inductive-loop input (ui_in[0])
    // Fix 6: no wire alias; loop_s2 referenced directly where needed
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

    // ----------------------------------------------------------------
    // Stored registers
    // ----------------------------------------------------------------
    reg [1:0] ctrl_reg;
    reg [3:0] wifi_count_reg;
    reg       irq_pending;

    wire ctrl_enable = ctrl_reg[0];
    wire ctrl_auto   = ctrl_reg[1];

    // ----------------------------------------------------------------
    // Fix 2: Explicit combinatorial one-hot write enables
    // Gives synthesizer unambiguous single-gate enables for each register
    // rather than letting it infer them from a shared case statement.
    // ----------------------------------------------------------------
    wire [3:0] reg_sel   = address[5:2];
    wire write_en        = (data_write_n != 2'b11);
    wire read_en         = (data_read_n  != 2'b11);

    wire sel_ctrl        = (reg_sel == REG_CTRL);
    wire sel_wifi        = (reg_sel == REG_WIFI_COUNT);

    // Fix 3: per-register write enables -> synthesizer infers clock gates
    wire ctrl_wen        = write_en && sel_ctrl;
    wire wifi_wen        = write_en && sel_wifi;
    wire irq_clear_now   = ctrl_wen && data_in[2];

    // ----------------------------------------------------------------
    // Fix 3: Clock-gated register writes (separate always blocks)
    // Each block has its own enable so synthesis can gate the clock
    // independently, stopping the register from toggling on idle cycles.
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ctrl_reg <= 2'b00;
        else if (ctrl_wen) ctrl_reg <= data_in[1:0];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) wifi_count_reg <= 4'd0;
        else if (wifi_wen) wifi_count_reg <= data_in[3:0];
    end

    // ----------------------------------------------------------------
    // Fix 1: Register status signals to break the critical path
    //
    // Old path: SPI shift reg -> wifi_count_reg -> congestion ->
    //           trigger -> irq_pending -> user_interrupt
    //
    // New path: SPI shift reg -> wifi_count_reg  (cycle N)
    //           wifi_count_reg -> congestion_r    (cycle N+1)
    //           congestion_r   -> irq_pending     (cycle N+2)
    //
    // Adds one cycle of latency to congestion detection -- acceptable
    // for a traffic-light controller.
    // ----------------------------------------------------------------
    reg congestion_r;
    reg loop_detect_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            congestion_r  <= 1'b0;
            loop_detect_r <= 1'b0;
        end else begin
            congestion_r  <= ctrl_enable && wifi_count_reg[3];
            loop_detect_r <= loop_s2;
        end
    end

    // trigger is now a short combinatorial path from registered values
    wire trigger = congestion_r || (ctrl_enable && loop_detect_r);

    // Status wires for the read mux (use registered values consistently)
    wire congestion_present = congestion_r;
    wire demand_present     = ctrl_enable &&
                              ((wifi_count_reg != 4'd0) || loop_detect_r);

    // ----------------------------------------------------------------
    // Fix 5: Merge irq_pending into a single Boolean expression
    // Replaces the if/else-if chain with one equation the synthesizer
    // maps directly to a 3-input gate, saving area and shortening the path.
    //
    //   set   when trigger is true
    //   clear when software pulses irq_clear_now AND trigger is false
    //   hold  otherwise
    //
    // Equivalent to: irq_pending = trigger | (irq_pending & ~irq_clear_now)
    // ----------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            irq_pending <= 1'b0;
        else
            irq_pending <= trigger | (irq_pending & ~irq_clear_now);
    end

    // ----------------------------------------------------------------
    // Fix 7: 1-bit internal light state
    // YELLOW is never used, so light state is binary: green or red.
    // LIGHT_RED=8'h00, LIGHT_GREEN=8'h02 -> only bit[1] differs.
    // Eliminates the 8-bit auto_light mux entirely; just drive bit[1].
    // ----------------------------------------------------------------
    wire light_green = trigger;  // 1 = green, 0 = red

    // ----------------------------------------------------------------
    // Read mux (combinatorial, single-cycle)
    // Uses registered loop_detect_r and congestion_r for consistency.
    // data_out stays combinatorial to preserve the wrapper's read interface.
    // ----------------------------------------------------------------
    reg [31:0] read_data;
    always @(*) begin
        if (!read_en) begin
            read_data = 32'd0;
        end else begin
            case (reg_sel)
                // Fix 2: each branch driven by its own decoded condition
                REG_CTRL:
                    read_data = {30'd0, ctrl_reg};

                REG_LOOP_STATUS:
                    read_data = {31'd0, loop_detect_r};

                REG_WIFI_COUNT:
                    read_data = {28'd0, wifi_count_reg};

                REG_LIGHT_STATE:
                    // Fix 7: 1-bit expand into 8'h02 / 8'h00
                    // bit[1] = light_green, bit[0] = 0 always
                    read_data = {24'd0, 6'd0,
                                 (ctrl_auto ? light_green : 1'b0),
                                 1'b0};

                REG_THRESHOLD:
                    read_data = 32'd0;  // reserved; threshold fixed at 8

                REG_STATUS:
                    read_data = {29'd0,
                                 irq_pending,
                                 demand_present,
                                 congestion_present};

                default:
                    read_data = 32'd0;
            endcase
        end
    end

    assign data_out       = read_data;
    assign user_interrupt = irq_pending;
    assign uo_out         = 8'h01;  // SPI CS_N deasserted, SCK/MOSI idle

    wire _unused = &{
        ui_in[7:1],
        address[1:0],
        data_in[31:4],
        data_read_n,
        data_ready,
        1'b0
    };

endmodule

`default_nettype wire