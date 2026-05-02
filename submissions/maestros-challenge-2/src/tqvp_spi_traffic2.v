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
    output        data_ready,
    output        user_interrupt
);

    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_LIGHT_STATE = 4'd3;
    localparam [3:0] REG_THRESHOLD   = 4'd4;  // reserved now
    localparam [3:0] REG_STATUS      = 4'd5;

    localparam [7:0] LIGHT_RED   = 8'd0;
    localparam [7:0] LIGHT_GREEN = 8'd2;

    // Reduced storage
    reg [1:0] ctrl_reg;        // [0]=enable, [1]=auto
    reg [3:0] wifi_count_reg;  // only stores counts 0–15
    reg       irq_pending;

    // Synchronizer for external loop input
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

    wire ctrl_enable = ctrl_reg[0];
    wire ctrl_auto   = ctrl_reg[1];

    // Fixed congestion threshold:
    // wifi_count >= 8 means bit[3] is high.
    wire congestion_present = ctrl_enable && wifi_count_reg[3];

    wire demand_present = ctrl_enable &&
                          ((wifi_count_reg != 4'd0) || loop_detect);

    wire trigger = congestion_present ||
                   (ctrl_enable && loop_detect);

    wire write_en = (data_write_n != 2'b11);
    wire read_en  = (data_read_n  != 2'b11);
    wire [3:0] reg_sel = address[5:2];

    wire irq_clear_now = write_en &&
                         (reg_sel == REG_CTRL) &&
                         data_in[2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg       <= 2'b00;
            wifi_count_reg <= 4'd0;
            irq_pending    <= 1'b0;
        end else begin
            if (write_en) begin
                case (reg_sel)
                    REG_CTRL: begin
                        ctrl_reg <= data_in[1:0];
                    end

                    REG_WIFI_COUNT: begin
                        wifi_count_reg <= data_in[3:0];
                    end

                    // REG_THRESHOLD intentionally ignored.
                    // Fixed threshold is count >= 8.
                    default: ;
                endcase
            end

            if (irq_clear_now)
                irq_pending <= trigger;
            else if (trigger)
                irq_pending <= 1'b1;
        end
    end

    wire [7:0] auto_light = trigger ? LIGHT_GREEN : LIGHT_RED;

    reg [31:0] read_data;

    always @(*) begin
        if (!read_en) begin
            read_data = 32'd0;
        end else begin
            case (reg_sel)
                REG_CTRL: begin
                    read_data = {30'd0, ctrl_reg};
                end

                REG_LOOP_STATUS: begin
                    read_data = {31'd0, loop_detect};
                end

                REG_WIFI_COUNT: begin
                    read_data = {28'd0, wifi_count_reg};
                end

                REG_LIGHT_STATE: begin
                    read_data = {24'd0, ctrl_auto ? auto_light : LIGHT_RED};
                end

                REG_THRESHOLD: begin
                    // Reserved. Threshold is fixed at 8.
                    read_data = 32'd0;
                end

                REG_STATUS: begin
                    read_data = {29'd0,
                                 irq_pending,
                                 demand_present,
                                 congestion_present};
                end

                default: begin
                    read_data = 32'd0;
                end
            endcase
        end
    end

    assign data_out       = read_data;
    assign data_ready     = 1'b1;
    assign user_interrupt = irq_pending;

    // Idle outputs
    assign uo_out = 8'h01;

    wire _unused = &{
        ui_in[7:1],
        address[1:0],
        data_in[31:4],
        data_read_n,
        1'b0
    };

endmodule

`default_nettype wire
