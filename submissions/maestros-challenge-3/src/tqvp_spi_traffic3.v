`default_nettype none

module tqvp_spi_traffic3 (
    input         clk,
    input         rst_n,

    // External pins
    input  [7:0]  ui_in,
    output [7:0]  uo_out,

    // TinyQV peripheral bus
    input  [5:0]  address,
    input  [31:0] data_in,
    input  [1:0]  data_write_n,
    input  [1:0]  data_read_n,
    output [31:0] data_out,
    input         data_ready,
    output        user_interrupt
);

    // ------------------------------------------------------------
    // Register map
    // ------------------------------------------------------------
    localparam [3:0] REG_CTRL        = 4'd0;
    localparam [3:0] REG_LOOP_STATUS = 4'd1;
    localparam [3:0] REG_WIFI_COUNT  = 4'd2;
    localparam [3:0] REG_THRESHOLD   = 4'd3;
    localparam [3:0] REG_STATUS      = 4'd4;
    localparam [3:0] REG_SPI_STATUS  = 4'd5;

    // ------------------------------------------------------------
    // External pin map
    //
    // ui_in[0] = inductive loop detect input
    // ui_in[1] = SPI SCK from ESP32
    // ui_in[2] = SPI CS_N from ESP32, active low
    // ui_in[3] = SPI MOSI from ESP32
    //
    // uo_out[0] = supplemental request to original 555/controller
    // uo_out[1] = Wi-Fi congestion present
    // uo_out[2] = synchronized loop detect status
    // uo_out[3] = latched interrupt pending
    // uo_out[4] = SPI MISO, unused/tied low in this write-only version
    // uo_out[7:5] = unused
    // ------------------------------------------------------------

    wire loop_raw  = ui_in[0];
    wire spi_sck_i = ui_in[1];
    wire spi_cs_ni = ui_in[2];
    wire spi_mosi_i = ui_in[3];

    // ------------------------------------------------------------
    // Control register bits
    //
    // ctrl_reg[0] = enable
    // ctrl_reg[1] = request mode:
    //               0 = level request while Wi-Fi demand is present
    //               1 = one-shot pulse request when Wi-Fi demand appears
    //
    // Write-only CTRL bit:
    // data_in[2] = clear irq_pending
    // ------------------------------------------------------------

    reg [1:0] ctrl_reg;

    wire ctrl_enable     = ctrl_reg[0];
    wire ctrl_pulse_mode = ctrl_reg[1];

    // ------------------------------------------------------------
    // Stored system registers
    // ------------------------------------------------------------

    reg [3:0] wifi_count_reg;
    reg [3:0] threshold_reg;
    reg       irq_pending;

    // ------------------------------------------------------------
    // TinyQV bus decode
    // ------------------------------------------------------------

    wire [3:0] reg_sel  = address[5:2];
    wire       write_en = (data_write_n != 2'b11);
    wire       read_en  = (data_read_n  != 2'b11);

    wire sel_ctrl      = (reg_sel == REG_CTRL);
    wire sel_wifi      = (reg_sel == REG_WIFI_COUNT);
    wire sel_threshold = (reg_sel == REG_THRESHOLD);

    wire ctrl_wen      = write_en && sel_ctrl;
    wire wifi_bus_wen  = write_en && sel_wifi;
    wire thresh_wen    = write_en && sel_threshold;

    wire irq_clear_now = ctrl_wen && data_in[2];

    // ------------------------------------------------------------
    // Synchronize loop detector input
    // ------------------------------------------------------------

    reg loop_s1;
    reg loop_s2;
    reg loop_detect_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            loop_s1       <= 1'b0;
            loop_s2       <= 1'b0;
            loop_detect_r <= 1'b0;
        end else begin
            loop_s1       <= loop_raw;
            loop_s2       <= loop_s1;
            loop_detect_r <= loop_s2;
        end
    end

    // ------------------------------------------------------------
    // SPI input synchronization
    //
    // This SPI receiver samples external SPI using the TinyQV clk.
    // Assumption: clk is several times faster than SPI SCK.
    //
    // Suggested ESP32 SPI mode:
    //   CPOL = 0
    //   CPHA = 0
    //
    // Data is sampled on rising SCK while CS_N is low.
    //
    // Packet format, 16 bits total:
    //
    //   byte 0: command/address
    //   byte 1: data
    //
    // Command byte:
    //   bit[7]   = 1 for write
    //   bit[3:0] = register address
    //
    // Examples:
    //   0x82, 0x0A  -> write REG_WIFI_COUNT = 10
    //   0x83, 0x08  -> write REG_THRESHOLD  = 8
    //   0x80, 0x01  -> write REG_CTRL       = enable
    // ------------------------------------------------------------

    reg spi_sck_s1;
    reg spi_sck_s2;
    reg spi_cs_s1;
    reg spi_cs_s2;
    reg spi_mosi_s1;
    reg spi_mosi_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_sck_s1  <= 1'b0;
            spi_sck_s2  <= 1'b0;
            spi_cs_s1   <= 1'b1;
            spi_cs_s2   <= 1'b1;
            spi_mosi_s1 <= 1'b0;
            spi_mosi_s2 <= 1'b0;
        end else begin
            spi_sck_s1  <= spi_sck_i;
            spi_sck_s2  <= spi_sck_s1;

            spi_cs_s1   <= spi_cs_ni;
            spi_cs_s2   <= spi_cs_s1;

            spi_mosi_s1 <= spi_mosi_i;
            spi_mosi_s2 <= spi_mosi_s1;
        end
    end

    wire spi_cs_active = ~spi_cs_s2;
    wire spi_sck_rise  = spi_cs_active && (spi_sck_s1 && !spi_sck_s2);

    reg [15:0] spi_shift;
    reg [3:0]  spi_bit_count;
    reg        spi_packet_ready;
    reg [7:0]  spi_cmd_byte;
    reg [7:0]  spi_data_byte;
    reg        spi_write_seen;

    wire [15:0] spi_shift_next = {spi_shift[14:0], spi_mosi_s2};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spi_shift        <= 16'd0;
            spi_bit_count    <= 4'd0;
            spi_packet_ready <= 1'b0;
            spi_cmd_byte     <= 8'd0;
            spi_data_byte    <= 8'd0;
            spi_write_seen   <= 1'b0;
        end else begin
            spi_packet_ready <= 1'b0;

            if (!spi_cs_active) begin
                spi_bit_count <= 4'd0;
                spi_shift     <= 16'd0;
            end else if (spi_sck_rise) begin
                spi_shift <= spi_shift_next;

                if (spi_bit_count == 4'd15) begin
                    spi_bit_count    <= 4'd0;
                    spi_packet_ready <= 1'b1;
                    spi_cmd_byte     <= spi_shift_next[15:8];
                    spi_data_byte    <= spi_shift_next[7:0];
                    spi_write_seen   <= spi_shift_next[15];
                end else begin
                    spi_bit_count <= spi_bit_count + 4'd1;
                end
            end
        end
    end

    // ------------------------------------------------------------
    // Decode SPI writes
    // ------------------------------------------------------------

    wire       spi_is_write = spi_packet_ready && spi_write_seen;
    wire [3:0] spi_reg_addr = spi_cmd_byte[3:0];

    wire spi_ctrl_wen      = spi_is_write && (spi_reg_addr == REG_CTRL);
    wire spi_wifi_wen      = spi_is_write && (spi_reg_addr == REG_WIFI_COUNT);
    wire spi_threshold_wen = spi_is_write && (spi_reg_addr == REG_THRESHOLD);

    // ------------------------------------------------------------
    // Register writes
    //
    // Both SPI and TinyQV bus can write the same internal registers.
    // Bus write has priority if both somehow occur in same clk cycle.
    // ------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 2'b00;
        end else if (ctrl_wen) begin
            ctrl_reg <= data_in[1:0];
        end else if (spi_ctrl_wen) begin
            ctrl_reg <= spi_data_byte[1:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wifi_count_reg <= 4'd0;
        end else if (wifi_bus_wen) begin
            wifi_count_reg <= data_in[3:0];
        end else if (spi_wifi_wen) begin
            wifi_count_reg <= spi_data_byte[3:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_reg <= 4'd8;
        end else if (thresh_wen) begin
            threshold_reg <= data_in[3:0];
        end else if (spi_threshold_wen) begin
            threshold_reg <= spi_data_byte[3:0];
        end
    end

    // ------------------------------------------------------------
    // Demand detection
    //
    // Important behavior:
    //
    //   If loop_detect_r == 1:
    //       original loop/555 controller already has demand.
    //       TinyQV suppresses supplemental Wi-Fi request.
    //
    //   If loop_detect_r == 0 and Wi-Fi count >= threshold:
    //       TinyQV asserts supplemental demand request.
    //
    // This does NOT turn the lights directly.
    // It only requests service from the original controller.
    // ------------------------------------------------------------

    reg congestion_r;
    reg wifi_demand_r;
    reg supplemental_request_level;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            congestion_r               <= 1'b0;
            wifi_demand_r              <= 1'b0;
            supplemental_request_level <= 1'b0;
        end else begin
            congestion_r <= ctrl_enable &&
                            (wifi_count_reg >= threshold_reg);

            wifi_demand_r <= ctrl_enable &&
                             (wifi_count_reg >= threshold_reg) &&
                             !loop_detect_r;

            supplemental_request_level <= ctrl_enable &&
                                          (wifi_count_reg >= threshold_reg) &&
                                          !loop_detect_r;
        end
    end

    // ------------------------------------------------------------
    // Optional one-shot request pulse
    //
    // If ctrl_reg[1] = 0:
    //   uo_out[0] is a level signal while demand remains present.
    //
    // If ctrl_reg[1] = 1:
    //   uo_out[0] generates a short pulse when Wi-Fi demand appears.
    //
    // This is useful if the old 555/controller expects a trigger pulse
    // instead of a held request level.
    // ------------------------------------------------------------

    localparam [3:0] PULSE_WIDTH = 4'd8;

    reg wifi_demand_d;
    reg [3:0] pulse_count;

    wire wifi_demand_rise = wifi_demand_r && !wifi_demand_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wifi_demand_d <= 1'b0;
            pulse_count   <= 4'd0;
        end else begin
            wifi_demand_d <= wifi_demand_r;

            if (!ctrl_enable) begin
                pulse_count <= 4'd0;
            end else if (wifi_demand_rise) begin
                pulse_count <= PULSE_WIDTH;
            end else if (pulse_count != 4'd0) begin
                pulse_count <= pulse_count - 4'd1;
            end
        end
    end

    wire supplemental_request_pulse = (pulse_count != 4'd0);

    wire supplemental_request =
        ctrl_pulse_mode ? supplemental_request_pulse :
                          supplemental_request_level;

    // ------------------------------------------------------------
    // Interrupt latch
    //
    // Interrupt asserts only for supplemental Wi-Fi demand.
    // It does not assert just because the loop detector is active.
    // ------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            irq_pending <= 1'b0;
        end else begin
            irq_pending <= wifi_demand_r | (irq_pending & ~irq_clear_now);
        end
    end

    // ------------------------------------------------------------
    // Read mux
    // ------------------------------------------------------------

    reg [31:0] read_data;

    always @(*) begin
        if (!read_en) begin
            read_data = 32'd0;
        end else begin
            case (reg_sel)
                REG_CTRL:
                    read_data = {30'd0, ctrl_reg};

                REG_LOOP_STATUS:
                    read_data = {31'd0, loop_detect_r};

                REG_WIFI_COUNT:
                    read_data = {28'd0, wifi_count_reg};

                REG_THRESHOLD:
                    read_data = {28'd0, threshold_reg};

                REG_STATUS:
                    read_data = {27'd0,
                                 supplemental_request,
                                 irq_pending,
                                 loop_detect_r,
                                 wifi_demand_r,
                                 congestion_r};

                REG_SPI_STATUS:
                    read_data = {22'd0,
                                 spi_cs_active,
                                 spi_packet_ready,
                                 spi_write_seen,
                                 spi_bit_count,
                                 spi_cmd_byte};

                default:
                    read_data = 32'd0;
            endcase
        end
    end

    assign data_out = read_data;

    // ------------------------------------------------------------
    // Outputs
    // ------------------------------------------------------------

    assign user_interrupt = irq_pending;

    assign uo_out[0] = supplemental_request;
    assign uo_out[1] = congestion_r;
    assign uo_out[2] = loop_detect_r;
    assign uo_out[3] = irq_pending;
    assign uo_out[4] = 1'b0;  // MISO unused in this write-only SPI version
    assign uo_out[7:5] = 3'b000;

    // ------------------------------------------------------------
    // Unused signals
    // ------------------------------------------------------------

    wire _unused = &{
        ui_in[7:4],
        address[1:0],
        data_in[31:4],
        data_ready,
        1'b0
    };

endmodule

`default_nettype wire