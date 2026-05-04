# AI Conversation Log - [Session 2]

## Conversation 1: Resolve Max Fanout
**Timestamp**: 2026-05-02 13:07:20
**Tool**: Claude Sonnet
**Purpose**: Resolve max fanout violations from OpenLane analysis.

**Prompt**: 
File:
File:
File:

how to resolve max fanout violations?
`default_nettype none  module spi_reg #(     parameter ADDR_W = 6,     parameter REG_W  = 32 )(     input  wire              clk,     input  wire              rstb,     input  wire              ena,          input  wire              spi_clk,     input  wire              spi_mosi,     input  wire              spi_cs_n,     output reg               spi_miso,          output reg  [ADDR_W-1:0] reg_addr,     output reg  [REG_W-1:0]  reg_data_o,     output reg               reg_wen,        // This is the pin the linter was missing!     input  wire [REG_W-1:0]  reg_data_i,          output reg               reg_addr_v,     output reg               reg_data_i_dv,     output reg               reg_data_o_dv,     output reg               reg_rw,     input  wire [1:0]        txn_width       // Declared and now "used" );      reg [1:0]  state;     reg [5:0]  bit_cnt;     reg [REG_W-1:0] shift_reg;      // Fix for UNUSEDSIGNAL: We'll acknowledge txn_width even if we don't use it logic-wise     wire [1:0] _unused_width = txn_width;      reg sclk_d;     always @(posedge clk) sclk_d <= spi_clk;     wire sclk_rose = (spi_clk && !sclk_d);     wire sclk_fell = (!spi_clk && sclk_d);      always @(posedge clk) begin         if (!rstb || spi_cs_n || !ena) begin             state         <= 2'b00;             bit_cnt       <= 0;             reg_wen       <= 0;             spi_miso      <= 0;             reg_addr_v    <= 0;             reg_data_i_dv <= 0;             reg_data_o_dv <= 0;             reg_rw        <= 0;         end else begin             reg_wen <= 0;               case (state)                 2'b00: begin // IDLE/ADDR                     if (sclk_rose) begin                         if (bit_cnt == 0) reg_rw <= spi_mosi;                         else reg_addr <= {reg_addr[ADDR_W-2:0], spi_mosi};                                                  if (bit_cnt == ADDR_W) begin                             state <= 2'b01;                             bit_cnt <= 0;                             reg_addr_v <= 1;                             if (!reg_rw) shift_reg <= reg_data_i;                         end else bit_cnt <= bit_cnt + 1;                     end                 end                  2'b01: begin // DATA                     reg_addr_v <= 0;                     if (sclk_rose) begin                         shift_reg <= {shift_reg[REG_W-2:0], spi_mosi};                         if (bit_cnt == REG_W-1) begin                             if (reg_rw) begin                                 reg_data_o    <= {shift_reg[REG_W-2:0], spi_mosi};                                 reg_wen       <= 1;                                 reg_data_o_dv <= 1;                             end                             state <= 2'b00;                         end else bit_cnt <= bit_cnt + 1;                     end                     if (sclk_fell && !reg_rw) begin                         spi_miso      <= shift_reg[REG_W-1];                         shift_reg     <= {shift_reg[REG_W-2:0], 1'b0};                         reg_data_i_dv <= 1;                     end                 end                  // Fix for CASEINCOMPLETE: Tell the linter what to do in "impossible" states                 default: state <= 2'b00;              endcase         end     end  endmodule


`default_nettype none  module synchronizer #(     parameter STAGES = 2,  // Number of flip-flops in the chain     parameter WIDTH  = 1   // Number of bits to synchronize )(     input  wire             clk,      // The destination clock domain     input  wire [WIDTH-1:0] data_in,  // Asynchronous input from the outside world     output wire [WIDTH-1:0] data_out  // Synchronized, safe output );      // Create a multi-dimensional array of flip-flops:      // [STAGES] is how many layers deep, [WIDTH] is how wide the signal is.     reg [WIDTH-1:0] sync_regs [STAGES-1:0];      integer i;      always @(posedge clk) begin         // The first stage always grabs the raw input         sync_regs[0] <= data_in;          // Every subsequent stage grabs the output of the previous one         for (i = 1; i < STAGES; i = i + 1) begin             sync_regs[i] <= sync_regs[i-1];         end     end      // The output of the very last stage is the "clean" signal     assign data_out = sync_regs[STAGES-1];  endmodule


**Response**:
Thought process: Diagnosed fanout violations and synthesized configuration and RTL solutions.

The user is asking about resolving max fanout violations from their OpenLane run. Let me analyze the design to identify what's likely causing fanout issues and provide concrete fixes.

Looking at the uploaded code, I can see:

1. `tqvp_spi_traffic2` - the peripheral (note `data_ready` is now an **input** not output - that's a bug difference from v1)
2. `wrapper.v` with `tt_um_tqv_peripheral_harness`
3. `spi_reg` module
4. `synchronizer` module

The max fanout warning says: "There are max fanout violations in the design at the typical corner."


The culprits are likely reset signals, control enables, or clock-related signals driving too many loads. I can fix this by adjusting the `MAX_FANOUT_CONSTRAINT` in the OpenLane config or adding buffer insertion hints to reduce the load on high-fanout nets. I should walk through both the configuration and RTL-level approaches to address these fanout issues, starting with the simpler config change and then moving to more targeted buffer insertion strategies for the high-fanout nets.


What Causes Max Fanout Violations


A fanout violation means one net drives too many gate inputs — the signal has to charge too much capacitance, which slows it down and can cause timing failures. In your design the most likely culprits are:


rst_reg_n — drives every single flip-flop in tqvp_spi_traffic2, spi_reg, and the synchronizers all at once. That's the #1 suspect in small designs.


ctrl_enable — feeds congestion_present, demand_present, trigger, and the read mux simultaneously.


spi_cs_n inside spi_reg — resets all internal state registers together.


There are three levels at which you can fix this, from easiest to most thorough:



Fix 1 — OpenLane config (easiest, try first)


In your designs/Second_iteration/config.json, raise the fanout constraint that the synthesizer targets:


{
  "DESIGN_NAME": "tt_um_tqv_peripheral_harness",
  "SYNTH_MAX_FANOUT": 12,
  "MAX_FANOUT_CONSTRAINT": 12
}


The default is often 4–6, which is aggressive for a design this size. Setting it to 10–16 gives the router more flexibility without hurting your timing since you have no setup violations.



Fix 2 — RTL buffer registers for ctrl_enable


Add an explicit registered copy of ctrl_enable so the synthesizer has a dedicated driver rather than tapping ctrl_reg[0] everywhere:


// Add this register alongside ctrl_reg
reg ctrl_enable_r;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ctrl_enable_r <= 1'b0;
    else
        ctrl_enable_r <= ctrl_reg[0];  // registered buffer
end

// Replace ctrl_enable wire with the registered version
wire ctrl_enable = ctrl_enable_r;


This adds one cycle of latency to enable changes, which is fine — the peripheral isn't cycle-critical on control writes.



Fix 3 — Replicated reset tree with (* keep *) attribute


This tells the synthesizer not to merge or optimize away your buffer, forcing it to create separate reset drivers:


(* keep = "true" *) reg rst_sync_periph_n;
(* keep = "true" *) reg rst_sync_spi_n;

always @(negedge clk) begin
    rst_sync_periph_n <= rst_reg_n;  // copy 1 for peripheral regs
    rst_sync_spi_n    <= rst_reg_n;  // copy 2 for SPI regs
end


Then pass rst_sync_periph_n into tqvp_spi_traffic2 and rst_sync_spi_n into spi_reg instead of the shared rst_reg_n. Each copy drives half the load.



Fix 4 — Constrain in SDC (if using custom constraints)


If you have a constraints.sdc file, you can directly annotate the max fanout on the reset net:


set_max_fanout 12 [get_ports rst_n]
set_max_fanout 8  [get_nets rst_reg_n]



Recommended order


Since you already have a clean flow with no DRC or timing violations, start with Fix 1 alone and re-run. If the violation count goes to zero, you're done. If violations remain on ctrl_enable specifically, add Fix 2. The reset tree fix (Fix 3) is only worth doing if the STA report shows the reset path itself is the bottleneck.


To confirm exactly which net is violating, check the report OpenLane pointed you to:


designs/Second_iteration/runs/RUN_2026.05.02_19.51.20/reports/signoff/31-rcx_sta.checks.rpt


Look for lines starting with max_fanout — it will name the exact net and tell you the actual vs allowed fanout count.
