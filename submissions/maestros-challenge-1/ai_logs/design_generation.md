##results    # Testing and implementation results
                
#simulation/           # Simulation outputs
#simulation/              # Simulation outputs
#simulation/                  # Simulation outputs

[OSS CAD Suite] C:\Users\moral\Desktop\Things>iverilog -o spi_sim.out tqvp_spi_traffic.v tb_tqvp_spi_traffic.v

[OSS CAD Suite] C:\Users\moral\Desktop\Things>vvp spi_sim.out
VCD info: dumpfile tb_tqvp_spi_traffic.vcd opened for output.
========================================
Starting tb_tqvp_spi_traffic
========================================

--- Test 1: reset defaults ---
PASS: CTRL after reset got expected 0x00
PASS: WIFI_COUNT after reset got expected 0x00
PASS: THRESHOLD after reset got expected 0x05
PASS: LIGHT_STATE after reset got expected 0x00
PASS: user_interrupt after reset got expected 0

--- Test 2: write CTRL and THRESHOLD ---
PASS: CTRL programmed got expected 0x03
PASS: THRESHOLD programmed got expected 0x06

--- Test 3: WIFI_COUNT below threshold ---
PASS: WIFI_COUNT = 3 got expected 0x03
PASS: STATUS demand set mask 0x00000002 set
PASS: congestion is 0 below threshold
PASS: user_interrupt below threshold got expected 0
PASS: LIGHT_STATE below threshold got expected 0x00

--- Test 4: WIFI_COUNT above threshold ---
PASS: WIFI_COUNT = 9 got expected 0x09
PASS: STATUS congestion set mask 0x00000001 set
PASS: STATUS demand set mask 0x00000002 set
PASS: STATUS irq set mask 0x00000004 set
PASS: user_interrupt above threshold got expected 1
PASS: LIGHT_STATE above threshold got expected 0x02

--- Test 5: clear interrupt ---
PASS: irq_pending cleared
PASS: user_interrupt cleared got expected 0

--- Test 6: inductive loop input ---
PASS: LOOP_STATUS vehicle present mask 0x00000001 set
PASS: STATUS demand from loop mask 0x00000002 set
PASS: STATUS irq from loop mask 0x00000004 set
PASS: user_interrupt from loop got expected 1
PASS: LIGHT_STATE from loop got expected 0x02
PASS: user_interrupt after loop clear got expected 0

--- Test 7: combined scenario ---
PASS: combined congestion mask 0x00000001 set
PASS: combined demand mask 0x00000002 set
PASS: combined irq mask 0x00000004 set
PASS: combined LIGHT_STATE got expected 0x02
PASS: final user_interrupt got expected 0

========================================
ALL TESTS PASSED
========================================
tb_tqvp_spi_traffic.v:374: $finish called at 975000 (1ps)


#synthesis/            # Synthesis reports
#synthesis/               # Synthesis reports
#synthesis/                  # Synthesis reports

yosys> synth -top tqvp_spi_traffic

7. Executing SYNTH pass.

7.1. Executing HIERARCHY pass (managing design hierarchy).

7.1.1. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic

7.1.2. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic
Removed 0 unused modules.

7.2. Executing PROC pass (convert processes to netlists).

7.2.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

7.2.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Removed a total of 0 dead cases.

7.2.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 0 assignments to connections.

7.2.4. Executing PROC_INIT pass (extract init attributes).

7.2.5. Executing PROC_ARST pass (detect async resets in processes).

7.2.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.

7.2.7. Executing PROC_MUX pass (convert decision trees to multiplexers).

7.2.8. Executing PROC_DLATCH pass (convert process syncs to latches).

7.2.9. Executing PROC_DFF pass (convert process syncs to FFs).

7.2.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

7.2.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

7.2.12. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.3. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.5. Executing CHECK pass (checking for obvious problems).
Checking module tqvp_spi_traffic...
Found and reported 0 problems.

7.6. Executing OPT pass (performing simple optimizations).

7.6.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.6.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.6.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

7.6.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

7.6.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.6.6. Executing OPT_DFF pass (perform DFF optimizations).

7.6.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.6.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.6.9. Finished fast OPT passes. (There is nothing left to do.)

7.7. Executing FSM pass (extract and optimize FSM).

7.7.1. Executing FSM_DETECT pass (finding FSMs in design).

7.7.2. Executing FSM_EXTRACT pass (extracting FSM from design).

7.7.3. Executing FSM_OPT pass (simple optimizations of FSMs).

7.7.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.7.5. Executing FSM_OPT pass (simple optimizations of FSMs).

7.7.6. Executing FSM_RECODE pass (re-assigning FSM state encoding).

7.7.7. Executing FSM_INFO pass (dumping all available information on FSM cells).

7.7.8. Executing FSM_MAP pass (mapping FSMs to basic logic).

7.8. Executing OPT pass (performing simple optimizations).

7.8.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.8.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.8.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

7.8.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

7.8.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.8.6. Executing OPT_DFF pass (perform DFF optimizations).

7.8.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.8.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.8.9. Finished fast OPT passes. (There is nothing left to do.)

7.9. Executing WREDUCE pass (reducing word size of cells).

7.10. Executing PEEPOPT pass (run peephole optimizers).

7.11. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.12. Executing ALUMACC pass (create $alu and $macc cells).
Extracting $alu and $macc cells in module tqvp_spi_traffic:
  created 0 $alu and 0 $macc cells.

7.13. Executing SHARE pass (SAT-based resource sharing).

7.14. Executing OPT pass (performing simple optimizations).

7.14.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.14.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.14.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

7.14.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

7.14.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.14.6. Executing OPT_DFF pass (perform DFF optimizations).

7.14.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.14.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.14.9. Finished fast OPT passes. (There is nothing left to do.)

7.15. Executing MEMORY pass.

7.15.1. Executing OPT_MEM pass (optimize memories).
Performed a total of 0 transformations.

7.15.2. Executing OPT_MEM_PRIORITY pass (removing unnecessary memory write priority relations).
Performed a total of 0 transformations.

7.15.3. Executing OPT_MEM_FEEDBACK pass (finding memory read-to-write feedback paths).

7.15.4. Executing MEMORY_BMUX2ROM pass (converting muxes to ROMs).

7.15.5. Executing MEMORY_DFF pass (merging $dff cells to $memrd).

7.15.6. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.15.7. Executing MEMORY_SHARE pass (consolidating $memrd/$memwr cells).

7.15.8. Executing OPT_MEM_WIDEN pass (optimize memories where all ports are wide).
Performed a total of 0 transformations.

7.15.9. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.15.10. Executing MEMORY_COLLECT pass (generating $mem cells).

7.16. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.17. Executing OPT pass (performing simple optimizations).

7.17.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.
<suppressed ~1 debug messages>

7.17.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.17.3. Executing OPT_DFF pass (perform DFF optimizations).

7.17.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.17.5. Finished fast OPT passes.

7.18. Executing MEMORY_MAP pass (converting memories to logic and flip-flops).

7.19. Executing OPT pass (performing simple optimizations).

7.19.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.19.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.19.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

7.19.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

7.19.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.19.6. Executing OPT_SHARE pass.

7.19.7. Executing OPT_DFF pass (perform DFF optimizations).

7.19.8. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.19.9. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.19.10. Finished fast OPT passes. (There is nothing left to do.)

7.20. Executing TECHMAP pass (map to technology primitives).

7.20.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/techmap.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/techmap.v' to AST representation.
Generating RTLIL representation for module `\_90_simplemap_bool_ops'.
Generating RTLIL representation for module `\_90_simplemap_reduce_ops'.
Generating RTLIL representation for module `\_90_simplemap_logic_ops'.
Generating RTLIL representation for module `\_90_simplemap_compare_ops'.
Generating RTLIL representation for module `\_90_simplemap_various'.
Generating RTLIL representation for module `\_90_simplemap_registers'.
Generating RTLIL representation for module `\_90_shift_ops_shr_shl_sshl_sshr'.
Generating RTLIL representation for module `\_90_shift_shiftx'.
Generating RTLIL representation for module `\_90_fa'.
Generating RTLIL representation for module `\_90_lcu_brent_kung'.
Generating RTLIL representation for module `\_90_alu'.
Generating RTLIL representation for module `\_90_macc'.
Generating RTLIL representation for module `\_90_alumacc'.
Generating RTLIL representation for module `$__div_mod_u'.
Generating RTLIL representation for module `$__div_mod_trunc'.
Generating RTLIL representation for module `\_90_div'.
Generating RTLIL representation for module `\_90_mod'.
Generating RTLIL representation for module `$__div_mod_floor'.
Generating RTLIL representation for module `\_90_divfloor'.
Generating RTLIL representation for module `\_90_modfloor'.
Generating RTLIL representation for module `\_90_pow'.
Generating RTLIL representation for module `\_90_pmux'.
Generating RTLIL representation for module `\_90_demux'.
Generating RTLIL representation for module `\_90_lut'.
Generating RTLIL representation for module `$connect'.
Generating RTLIL representation for module `$input_port'.
Successfully finished Verilog frontend.

7.20.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~77 debug messages>

7.21. Executing OPT pass (performing simple optimizations).

7.21.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.21.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.21.3. Executing OPT_DFF pass (perform DFF optimizations).

7.21.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

7.21.5. Finished fast OPT passes.

7.22. Executing ABC pass (technology mapping using ABC).

7.22.1. Extracting gate netlist of module `\tqvp_spi_traffic' to `<abc-temp-dir>/input.blif'..

7.22.1.1. Executed ABC.
Extracted 99 gates and 126 wires to a netlist network with 27 inputs and 13 outputs.
Running ABC script: <abc-temp-dir>/abc.script
ABC: ======== ABC command line "source <abc-temp-dir>/abc.script"
ABC: + read_blif <abc-temp-dir>/input.blif
ABC: + read_library <abc-temp-dir>/stdcells.genlib
ABC: + strash
ABC: + &get -n
ABC: + &fraig -x
ABC: + &put
ABC: + scorr
ABC: Warning: The network is combinational (run "fraig" or "fraig_sweep").
ABC: + dc2
ABC: + dretime
ABC: + strash
ABC: + &get -n
ABC: + &dch -f
ABC: + &nf
ABC: + &put
ABC: + write_blif <abc-temp-dir>/output.blif

7.22.1.2. Re-integrating ABC results.
ABC RESULTS:               AND cells:       24
ABC RESULTS:            ANDNOT cells:        4
ABC RESULTS:              NAND cells:       45
ABC RESULTS:               NOR cells:        6
ABC RESULTS:                OR cells:        1
ABC RESULTS:             ORNOT cells:       18
ABC RESULTS:        internal signals:       86
ABC RESULTS:           input signals:       27
ABC RESULTS:          output signals:       13
Removing temp directory.
Removing global temp directory.

7.23. Executing OPT pass (performing simple optimizations).

7.23.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

7.23.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

7.23.3. Executing OPT_DFF pass (perform DFF optimizations).

7.23.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..
Removed 0 unused cells and 126 unused wires.
<suppressed ~1 debug messages>

7.23.5. Finished fast OPT passes.

7.24. Executing HIERARCHY pass (managing design hierarchy).
Attribute `top' found on module `tqvp_spi_traffic'. Setting top module to tqvp_spi_traffic.

7.24.1. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic

7.24.2. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic
Removed 0 unused modules.

7.25. Printing statistics.

=== tqvp_spi_traffic ===

        +----------Local Count, excluding submodules.
        |
      115 wires
      224 wire bits
       25 public wires
      134 public wire bits
       11 ports
       94 port bits
      119 cells
        4   $_ANDNOT_
       24   $_AND_
       17   $_DFFE_PN0P_
        2   $_DFFE_PN1P_
        2   $_DFF_PN0_
       45   $_NAND_
        6   $_NOR_
       18   $_ORNOT_
        1   $_OR_

7.26. Executing CHECK pass (checking for obvious problems).
Checking module tqvp_spi_traffic...
Found and reported 0 problems.

yosys> stat

8. Printing statistics.

=== tqvp_spi_traffic ===

        +----------Local Count, excluding submodules.
        |
      115 wires
      224 wire bits
       25 public wires
      134 public wire bits
       11 ports
       94 port bits
      119 cells
        4   $_ANDNOT_
       24   $_AND_
       17   $_DFFE_PN0P_
        2   $_DFFE_PN1P_
        2   $_DFF_PN0_
       45   $_NAND_
        6   $_NOR_
       18   $_ORNOT_
        1   $_OR_



#fpga/                # FPGA implementation results
#fpga/                   # FPGA implementation results
#fpga/                     # FPGA implementation results

yosys> synth_ice40 -top tqvp_spi_traffic -json my_design.json

9. Executing SYNTH_ICE40 pass.

9.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v' to AST representation.
Generating RTLIL representation for module `\SB_IO'.
Generating RTLIL representation for module `\SB_GB_IO'.
Generating RTLIL representation for module `\SB_GB'.
Generating RTLIL representation for module `\SB_LUT4'.
Generating RTLIL representation for module `\SB_CARRY'.
Generating RTLIL representation for module `\SB_DFF'.
Generating RTLIL representation for module `\SB_DFFE'.
Generating RTLIL representation for module `\SB_DFFSR'.
Generating RTLIL representation for module `\SB_DFFR'.
Generating RTLIL representation for module `\SB_DFFSS'.
Generating RTLIL representation for module `\SB_DFFS'.
Generating RTLIL representation for module `\SB_DFFESR'.
Generating RTLIL representation for module `\SB_DFFER'.
Generating RTLIL representation for module `\SB_DFFESS'.
Generating RTLIL representation for module `\SB_DFFES'.
Generating RTLIL representation for module `\SB_DFFN'.
Generating RTLIL representation for module `\SB_DFFNE'.
Generating RTLIL representation for module `\SB_DFFNSR'.
Generating RTLIL representation for module `\SB_DFFNR'.
Generating RTLIL representation for module `\SB_DFFNSS'.
Generating RTLIL representation for module `\SB_DFFNS'.
Generating RTLIL representation for module `\SB_DFFNESR'.
Generating RTLIL representation for module `\SB_DFFNER'.
Generating RTLIL representation for module `\SB_DFFNESS'.
Generating RTLIL representation for module `\SB_DFFNES'.
Generating RTLIL representation for module `\SB_RAM40_4K'.
Generating RTLIL representation for module `\SB_RAM40_4KNR'.
Generating RTLIL representation for module `\SB_RAM40_4KNW'.
Generating RTLIL representation for module `\SB_RAM40_4KNRNW'.
Generating RTLIL representation for module `\ICESTORM_LC'.
Generating RTLIL representation for module `\SB_PLL40_CORE'.
Generating RTLIL representation for module `\SB_PLL40_PAD'.
Generating RTLIL representation for module `\SB_PLL40_2_PAD'.
Generating RTLIL representation for module `\SB_PLL40_2F_CORE'.
Generating RTLIL representation for module `\SB_PLL40_2F_PAD'.
Generating RTLIL representation for module `\SB_WARMBOOT'.
Generating RTLIL representation for module `\SB_SPRAM256KA'.
Generating RTLIL representation for module `\SB_HFOSC'.
Generating RTLIL representation for module `\SB_LFOSC'.
Generating RTLIL representation for module `\SB_RGBA_DRV'.
Generating RTLIL representation for module `\SB_LED_DRV_CUR'.
Generating RTLIL representation for module `\SB_RGB_DRV'.
Generating RTLIL representation for module `\SB_I2C'.
Generating RTLIL representation for module `\SB_SPI'.
Generating RTLIL representation for module `\SB_LEDDA_IP'.
Generating RTLIL representation for module `\SB_FILTER_50NS'.
Generating RTLIL representation for module `\SB_IO_I3C'.
Generating RTLIL representation for module `\SB_IO_OD'.
Generating RTLIL representation for module `\SB_MAC16'.
Generating RTLIL representation for module `\ICESTORM_RAM'.
Successfully finished Verilog frontend.

9.2. Executing HIERARCHY pass (managing design hierarchy).

9.2.1. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic

9.2.2. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic
Removed 0 unused modules.

9.3. Executing PROC pass (convert processes to netlists).

9.3.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

9.3.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Removed a total of 0 dead cases.

9.3.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 0 assignments to connections.

9.3.4. Executing PROC_INIT pass (extract init attributes).

9.3.5. Executing PROC_ARST pass (detect async resets in processes).

9.3.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.

9.3.7. Executing PROC_MUX pass (convert decision trees to multiplexers).

9.3.8. Executing PROC_DLATCH pass (convert process syncs to latches).

9.3.9. Executing PROC_DFF pass (convert process syncs to FFs).

9.3.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

9.3.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

9.3.12. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.4. Executing FLATTEN pass (flatten design).

9.5. Executing TRIBUF pass.

9.6. Executing DEMINOUT pass (demote inout ports to input or output).

9.7. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.8. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.9. Executing CHECK pass (checking for obvious problems).
Checking module tqvp_spi_traffic...
Found and reported 0 problems.

9.10. Executing OPT pass (performing simple optimizations).

9.10.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.10.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.10.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.10.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

9.10.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.10.6. Executing OPT_DFF pass (perform DFF optimizations).

9.10.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.10.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.10.9. Finished fast OPT passes. (There is nothing left to do.)

9.11. Executing FSM pass (extract and optimize FSM).

9.11.1. Executing FSM_DETECT pass (finding FSMs in design).

9.11.2. Executing FSM_EXTRACT pass (extracting FSM from design).

9.11.3. Executing FSM_OPT pass (simple optimizations of FSMs).

9.11.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.11.5. Executing FSM_OPT pass (simple optimizations of FSMs).

9.11.6. Executing FSM_RECODE pass (re-assigning FSM state encoding).

9.11.7. Executing FSM_INFO pass (dumping all available information on FSM cells).

9.11.8. Executing FSM_MAP pass (mapping FSMs to basic logic).

9.12. Executing OPT pass (performing simple optimizations).

9.12.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.12.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.12.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.12.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

9.12.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.12.6. Executing OPT_DFF pass (perform DFF optimizations).

9.12.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.12.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.12.9. Finished fast OPT passes. (There is nothing left to do.)

9.13. Executing WREDUCE pass (reducing word size of cells).

9.14. Executing PEEPOPT pass (run peephole optimizers).

9.15. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.16. Executing SHARE pass (SAT-based resource sharing).

9.17. Executing TECHMAP pass (map to technology primitives).

9.17.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/cmp2lut.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/cmp2lut.v' to AST representation.
Generating RTLIL representation for module `\_90_lut_cmp_'.
Successfully finished Verilog frontend.

9.17.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~6 debug messages>

9.18. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.19. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.20. Executing ALUMACC pass (create $alu and $macc cells).
Extracting $alu and $macc cells in module tqvp_spi_traffic:
  created 0 $alu and 0 $macc cells.

9.21. Executing OPT pass (performing simple optimizations).

9.21.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.21.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.21.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.21.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

9.21.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.21.6. Executing OPT_DFF pass (perform DFF optimizations).

9.21.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.21.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.21.9. Finished fast OPT passes. (There is nothing left to do.)

9.22. Executing MEMORY pass.

9.22.1. Executing OPT_MEM pass (optimize memories).
Performed a total of 0 transformations.

9.22.2. Executing OPT_MEM_PRIORITY pass (removing unnecessary memory write priority relations).
Performed a total of 0 transformations.

9.22.3. Executing OPT_MEM_FEEDBACK pass (finding memory read-to-write feedback paths).

9.22.4. Executing MEMORY_BMUX2ROM pass (converting muxes to ROMs).

9.22.5. Executing MEMORY_DFF pass (merging $dff cells to $memrd).

9.22.6. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.22.7. Executing MEMORY_SHARE pass (consolidating $memrd/$memwr cells).

9.22.8. Executing OPT_MEM_WIDEN pass (optimize memories where all ports are wide).
Performed a total of 0 transformations.

9.22.9. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.22.10. Executing MEMORY_COLLECT pass (generating $mem cells).

9.23. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.24. Executing MEMORY_LIBMAP pass (mapping memories to cells).

9.25. Executing TECHMAP pass (map to technology primitives).

9.25.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/brams_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/brams_map.v' to AST representation.
Generating RTLIL representation for module `$__ICE40_RAM4K_'.
Successfully finished Verilog frontend.

9.25.2. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/spram_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/spram_map.v' to AST representation.
Generating RTLIL representation for module `$__ICE40_SPRAM_'.
Successfully finished Verilog frontend.

9.25.3. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~4 debug messages>

9.26. Executing ICE40_BRAMINIT pass.

9.27. Executing OPT pass (performing simple optimizations).

9.27.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.27.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.27.3. Executing OPT_DFF pass (perform DFF optimizations).

9.27.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.27.5. Finished fast OPT passes.

9.28. Executing MEMORY_MAP pass (converting memories to logic and flip-flops).

9.29. Executing OPT pass (performing simple optimizations).

9.29.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.29.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.29.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.29.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

9.29.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.29.6. Executing OPT_DFF pass (perform DFF optimizations).

9.29.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.29.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.29.9. Finished fast OPT passes. (There is nothing left to do.)

9.30. Executing ICE40_WRAPCARRY pass (wrap carries).

9.31. Executing TECHMAP pass (map to technology primitives).

9.31.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/techmap.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/techmap.v' to AST representation.
Generating RTLIL representation for module `\_90_simplemap_bool_ops'.
Generating RTLIL representation for module `\_90_simplemap_reduce_ops'.
Generating RTLIL representation for module `\_90_simplemap_logic_ops'.
Generating RTLIL representation for module `\_90_simplemap_compare_ops'.
Generating RTLIL representation for module `\_90_simplemap_various'.
Generating RTLIL representation for module `\_90_simplemap_registers'.
Generating RTLIL representation for module `\_90_shift_ops_shr_shl_sshl_sshr'.
Generating RTLIL representation for module `\_90_shift_shiftx'.
Generating RTLIL representation for module `\_90_fa'.
Generating RTLIL representation for module `\_90_lcu_brent_kung'.
Generating RTLIL representation for module `\_90_alu'.
Generating RTLIL representation for module `\_90_macc'.
Generating RTLIL representation for module `\_90_alumacc'.
Generating RTLIL representation for module `$__div_mod_u'.
Generating RTLIL representation for module `$__div_mod_trunc'.
Generating RTLIL representation for module `\_90_div'.
Generating RTLIL representation for module `\_90_mod'.
Generating RTLIL representation for module `$__div_mod_floor'.
Generating RTLIL representation for module `\_90_divfloor'.
Generating RTLIL representation for module `\_90_modfloor'.
Generating RTLIL representation for module `\_90_pow'.
Generating RTLIL representation for module `\_90_pmux'.
Generating RTLIL representation for module `\_90_demux'.
Generating RTLIL representation for module `\_90_lut'.
Generating RTLIL representation for module `$connect'.
Generating RTLIL representation for module `$input_port'.
Successfully finished Verilog frontend.

9.31.2. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/arith_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/arith_map.v' to AST representation.
Generating RTLIL representation for module `\_80_ice40_alu'.
Successfully finished Verilog frontend.

9.31.3. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~77 debug messages>

9.32. Executing OPT pass (performing simple optimizations).

9.32.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.32.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.32.3. Executing OPT_DFF pass (perform DFF optimizations).

9.32.4. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.32.5. Finished fast OPT passes.

9.33. Executing ICE40_OPT pass (performing simple optimizations).

9.33.1. Running ICE40 specific optimizations.

9.33.2. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.33.3. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 119 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.33.4. Executing OPT_DFF pass (perform DFF optimizations).

9.33.5. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.33.6. Finished OPT passes. (There is nothing left to do.)

9.34. Executing DFFLEGALIZE pass (convert FFs to types supported by the target).

9.35. Executing TECHMAP pass (map to technology primitives).

9.35.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v' to AST representation.
Generating RTLIL representation for module `$_DFF_N_'.
Generating RTLIL representation for module `$_DFF_P_'.
Generating RTLIL representation for module `$_DFFE_NP_'.
Generating RTLIL representation for module `$_DFFE_PP_'.
Generating RTLIL representation for module `$_DFF_NP0_'.
Generating RTLIL representation for module `$_DFF_NP1_'.
Generating RTLIL representation for module `$_DFF_PP0_'.
Generating RTLIL representation for module `$_DFF_PP1_'.
Generating RTLIL representation for module `$_DFFE_NP0P_'.
Generating RTLIL representation for module `$_DFFE_NP1P_'.
Generating RTLIL representation for module `$_DFFE_PP0P_'.
Generating RTLIL representation for module `$_DFFE_PP1P_'.
Generating RTLIL representation for module `$_SDFF_NP0_'.
Generating RTLIL representation for module `$_SDFF_NP1_'.
Generating RTLIL representation for module `$_SDFF_PP0_'.
Generating RTLIL representation for module `$_SDFF_PP1_'.
Generating RTLIL representation for module `$_SDFFCE_NP0P_'.
Generating RTLIL representation for module `$_SDFFCE_NP1P_'.
Generating RTLIL representation for module `$_SDFFCE_PP0P_'.
Generating RTLIL representation for module `$_SDFFCE_PP1P_'.
Successfully finished Verilog frontend.

9.35.2. Continuing TECHMAP pass.
Using template $_DFF_PP0_ for cells of type $_DFF_PP0_.
Using template $_DFFE_PP0P_ for cells of type $_DFFE_PP0P_.
Using template $_DFFE_PP1P_ for cells of type $_DFFE_PP1P_.
No more expansions possible.
<suppressed ~43 debug messages>

9.36. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.37. Executing SIMPLEMAP pass (map simple cells to gate primitives).

9.38. Executing ICE40_OPT pass (performing simple optimizations).

9.38.1. Running ICE40 specific optimizations.

9.38.2. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.38.3. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 140 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
<suppressed ~60 debug messages>
Removed a total of 20 cells.

9.38.4. Executing OPT_DFF pass (perform DFF optimizations).

9.38.5. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..
Removed 0 unused cells and 144 unused wires.
<suppressed ~1 debug messages>

9.38.6. Rerunning OPT passes. (Removed registers in this run.)

9.38.7. Running ICE40 specific optimizations.

9.38.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.38.9. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 120 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.38.10. Executing OPT_DFF pass (perform DFF optimizations).

9.38.11. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.38.12. Finished OPT passes. (There is nothing left to do.)

9.39. Executing TECHMAP pass (map to technology primitives).

9.39.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/latches_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/latches_map.v' to AST representation.
Generating RTLIL representation for module `$_DLATCH_N_'.
Generating RTLIL representation for module `$_DLATCH_P_'.
Successfully finished Verilog frontend.

9.39.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~4 debug messages>

9.40. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/abc9_model.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/abc9_model.v' to AST representation.
Generating RTLIL representation for module `$__ICE40_CARRY_WRAPPER'.
Successfully finished Verilog frontend.

9.41. Executing ABC9 pass.

9.41.1. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.2. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.3. Executing PROC pass (convert processes to netlists).

9.41.3.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

9.41.3.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 1 switch rules as full_case in process $proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105 in module SB_DFFER.
Removed a total of 0 dead cases.

9.41.3.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 1 assignment to connection.

9.41.3.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:660$1108'.
  Set init value: \Q = 1'0

9.41.3.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \R in `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105'.

9.41.3.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.
<suppressed ~1 debug messages>

9.41.3.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:660$1108'.
Creating decoders for process `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105'.
     1/1: $0\Q[0:0]

9.41.3.8. Executing PROC_DLATCH pass (convert process syncs to latches).

9.41.3.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `\SB_DFFER.\Q' using process `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105'.
  created $adff cell `$procdff$1471' with positive edge clock and positive level reset.

9.41.3.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

9.41.3.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:660$1108'.
Found and cleaned up 1 empty switch in `\SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105'.
Removing empty process `SB_DFFER.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:662$1105'.
Cleaned up 1 empty switch.

9.41.4. Executing PROC pass (convert processes to netlists).

9.41.4.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

9.41.4.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 1 switch rules as full_case in process $proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116 in module SB_DFFES.
Removed a total of 0 dead cases.

9.41.4.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 0 redundant assignments.
Promoted 1 assignment to connection.

9.41.4.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:801$1119'.
  Set init value: \Q = 1'0

9.41.4.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \S in `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116'.

9.41.4.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.
<suppressed ~1 debug messages>

9.41.4.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:801$1119'.
Creating decoders for process `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116'.
     1/1: $0\Q[0:0]

9.41.4.8. Executing PROC_DLATCH pass (convert process syncs to latches).

9.41.4.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `\SB_DFFES.\Q' using process `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116'.
  created $adff cell `$procdff$1476' with positive edge clock and positive level reset.

9.41.4.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

9.41.4.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:801$1119'.
Found and cleaned up 1 empty switch in `\SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116'.
Removing empty process `SB_DFFES.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:803$1116'.
Cleaned up 1 empty switch.

9.41.5. Executing PROC pass (convert processes to netlists).

9.41.5.1. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Cleaned up 0 empty switches.

9.41.5.2. Executing PROC_RMDEAD pass (remove dead branches from decision trees).
Marked 1 switch rules as full_case in process $proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:406$1089 in module SB_DFFR.
Removed a total of 0 dead cases.

9.41.5.3. Executing PROC_PRUNE pass (remove redundant assignments in processes).
Removed 1 redundant assignment.
Promoted 1 assignment to connection.

9.41.5.4. Executing PROC_INIT pass (extract init attributes).
Found init rule in `\SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:404$1091'.
  Set init value: \Q = 1'0

9.41.5.5. Executing PROC_ARST pass (detect async resets in processes).
Found async reset \R in `\SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:406$1089'.

9.41.5.6. Executing PROC_ROM pass (convert switches to ROMs).
Converted 0 switches.

9.41.5.7. Executing PROC_MUX pass (convert decision trees to multiplexers).
Creating decoders for process `\SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:404$1091'.
Creating decoders for process `\SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:406$1089'.
     1/1: $0\Q[0:0]

9.41.5.8. Executing PROC_DLATCH pass (convert process syncs to latches).

9.41.5.9. Executing PROC_DFF pass (convert process syncs to FFs).
Creating register for signal `\SB_DFFR.\Q' using process `\SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:406$1089'.
  created $adff cell `$procdff$1479' with positive edge clock and positive level reset.

9.41.5.10. Executing PROC_MEMWR pass (convert process memory writes to cells).

9.41.5.11. Executing PROC_CLEAN pass (remove empty switches from decision trees).
Removing empty process `SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:404$1091'.
Removing empty process `SB_DFFR.$proc$C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:406$1089'.
Cleaned up 0 empty switches.

9.41.6. Executing SCC pass (detecting logic loops).
Found 0 SCCs in module tqvp_spi_traffic.
Found 0 SCCs.

9.41.7. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.8. Executing TECHMAP pass (map to technology primitives).

9.41.8.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/techmap.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/techmap.v' to AST representation.
Generating RTLIL representation for module `\_90_simplemap_bool_ops'.
Generating RTLIL representation for module `\_90_simplemap_reduce_ops'.
Generating RTLIL representation for module `\_90_simplemap_logic_ops'.
Generating RTLIL representation for module `\_90_simplemap_compare_ops'.
Generating RTLIL representation for module `\_90_simplemap_various'.
Generating RTLIL representation for module `\_90_simplemap_registers'.
Generating RTLIL representation for module `\_90_shift_ops_shr_shl_sshl_sshr'.
Generating RTLIL representation for module `\_90_shift_shiftx'.
Generating RTLIL representation for module `\_90_fa'.
Generating RTLIL representation for module `\_90_lcu_brent_kung'.
Generating RTLIL representation for module `\_90_alu'.
Generating RTLIL representation for module `\_90_macc'.
Generating RTLIL representation for module `\_90_alumacc'.
Generating RTLIL representation for module `$__div_mod_u'.
Generating RTLIL representation for module `$__div_mod_trunc'.
Generating RTLIL representation for module `\_90_div'.
Generating RTLIL representation for module `\_90_mod'.
Generating RTLIL representation for module `$__div_mod_floor'.
Generating RTLIL representation for module `\_90_divfloor'.
Generating RTLIL representation for module `\_90_modfloor'.
Generating RTLIL representation for module `\_90_pow'.
Generating RTLIL representation for module `\_90_pmux'.
Generating RTLIL representation for module `\_90_demux'.
Generating RTLIL representation for module `\_90_lut'.
Generating RTLIL representation for module `$connect'.
Generating RTLIL representation for module `$input_port'.
Successfully finished Verilog frontend.

9.41.8.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~132 debug messages>

9.41.9. Executing OPT pass (performing simple optimizations).

9.41.9.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module SB_DFFER.
Optimizing module SB_DFFES.
Optimizing module SB_DFFR.

9.41.9.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\SB_DFFER'.
Computing hashes of 2 cells of `\SB_DFFER'.
Finding duplicate cells in `\SB_DFFER'.
Finding identical cells in module `\SB_DFFES'.
Computing hashes of 2 cells of `\SB_DFFES'.
Finding duplicate cells in `\SB_DFFES'.
Finding identical cells in module `\SB_DFFR'.
Computing hashes of 2 cells of `\SB_DFFR'.
Finding duplicate cells in `\SB_DFFR'.
Removed a total of 0 cells.

9.41.9.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \SB_DFFER..
  Creating internal representation of mux trees.
  No muxes found in this module.
Running muxtree optimizer on module \SB_DFFES..
  Creating internal representation of mux trees.
  No muxes found in this module.
Running muxtree optimizer on module \SB_DFFR..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.41.9.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \SB_DFFER.
  Optimizing cells in module \SB_DFFES.
  Optimizing cells in module \SB_DFFR.
Performed a total of 0 changes.

9.41.9.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\SB_DFFER'.
Computing hashes of 2 cells of `\SB_DFFER'.
Finding duplicate cells in `\SB_DFFER'.
Finding identical cells in module `\SB_DFFES'.
Computing hashes of 2 cells of `\SB_DFFES'.
Finding duplicate cells in `\SB_DFFES'.
Finding identical cells in module `\SB_DFFR'.
Computing hashes of 2 cells of `\SB_DFFR'.
Finding duplicate cells in `\SB_DFFR'.
Removed a total of 0 cells.

9.41.9.6. Executing OPT_DFF pass (perform DFF optimizations).

9.41.9.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \SB_DFFER..
Finding unused cells or wires in module \SB_DFFES..
Finding unused cells or wires in module \SB_DFFR..

9.41.9.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module SB_DFFER.
Optimizing module SB_DFFES.
Optimizing module SB_DFFR.

9.41.9.9. Finished fast OPT passes. (There is nothing left to do.)

9.41.10. Executing TECHMAP pass (map to technology primitives).

9.41.10.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/abc9_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/abc9_map.v' to AST representation.
Successfully finished Verilog frontend.

9.41.10.2. Continuing TECHMAP pass.
Using template SB_DFFR for cells of type SB_DFFR.
Using template SB_DFFER for cells of type SB_DFFER.
Using template SB_DFFES for cells of type SB_DFFES.
No more expansions possible.
<suppressed ~26 debug messages>

9.41.11. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/abc9_model.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/abc9_model.v' to AST representation.
Generating RTLIL representation for module `$__ABC9_DELAY'.
Generating RTLIL representation for module `$__ABC9_SCC_BREAKER'.
Generating RTLIL representation for module `$__DFF_N__$abc9_flop'.
Generating RTLIL representation for module `$__DFF_P__$abc9_flop'.
Successfully finished Verilog frontend.

9.41.12. Executing ABC9_OPS pass (helper functions for ABC9).
<suppressed ~2 debug messages>

9.41.13. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.14. Executing ABC9_OPS pass (helper functions for ABC9).
<suppressed ~2 debug messages>

9.41.15. Executing TECHMAP pass (map to technology primitives).

9.41.15.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/techmap.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/techmap.v' to AST representation.
Generating RTLIL representation for module `\_90_simplemap_bool_ops'.
Generating RTLIL representation for module `\_90_simplemap_reduce_ops'.
Generating RTLIL representation for module `\_90_simplemap_logic_ops'.
Generating RTLIL representation for module `\_90_simplemap_compare_ops'.
Generating RTLIL representation for module `\_90_simplemap_various'.
Generating RTLIL representation for module `\_90_simplemap_registers'.
Generating RTLIL representation for module `\_90_shift_ops_shr_shl_sshl_sshr'.
Generating RTLIL representation for module `\_90_shift_shiftx'.
Generating RTLIL representation for module `\_90_fa'.
Generating RTLIL representation for module `\_90_lcu_brent_kung'.
Generating RTLIL representation for module `\_90_alu'.
Generating RTLIL representation for module `\_90_macc'.
Generating RTLIL representation for module `\_90_alumacc'.
Generating RTLIL representation for module `$__div_mod_u'.
Generating RTLIL representation for module `$__div_mod_trunc'.
Generating RTLIL representation for module `\_90_div'.
Generating RTLIL representation for module `\_90_mod'.
Generating RTLIL representation for module `$__div_mod_floor'.
Generating RTLIL representation for module `\_90_divfloor'.
Generating RTLIL representation for module `\_90_modfloor'.
Generating RTLIL representation for module `\_90_pow'.
Generating RTLIL representation for module `\_90_pmux'.
Generating RTLIL representation for module `\_90_demux'.
Generating RTLIL representation for module `\_90_lut'.
Generating RTLIL representation for module `$connect'.
Generating RTLIL representation for module `$input_port'.
Successfully finished Verilog frontend.

9.41.15.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~136 debug messages>

9.41.16. Executing OPT pass (performing simple optimizations).

9.41.16.1. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.41.16.2. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 0 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.41.16.3. Executing OPT_MUXTREE pass (detect dead branches in mux trees).
Running muxtree optimizer on module \tqvp_spi_traffic..
  Creating internal representation of mux trees.
  No muxes found in this module.
Removed 0 multiplexer ports.

9.41.16.4. Executing OPT_REDUCE pass (consolidate $*mux and $reduce_* inputs).
  Optimizing cells in module \tqvp_spi_traffic.
Performed a total of 0 changes.

9.41.16.5. Executing OPT_MERGE pass (detect identical cells).
Finding identical cells in module `\tqvp_spi_traffic'.
Computing hashes of 0 cells of `\tqvp_spi_traffic'.
Finding duplicate cells in `\tqvp_spi_traffic'.
Removed a total of 0 cells.

9.41.16.6. Executing OPT_DFF pass (perform DFF optimizations).

9.41.16.7. Executing OPT_CLEAN pass (remove unused cells and wires).
Finding unused cells or wires in module \tqvp_spi_traffic..

9.41.16.8. Executing OPT_EXPR pass (perform const folding).
Optimizing module tqvp_spi_traffic.

9.41.16.9. Finished fast OPT passes. (There is nothing left to do.)

9.41.17. Executing AIGMAP pass (map logic to AIG).

9.41.18. Executing AIGMAP pass (map logic to AIG).
Module tqvp_spi_traffic: replaced 74 cells with 174 new cells, skipped 67 cells.
  replaced 5 cell types:
       4 $_ANDNOT_
      45 $_NAND_
       6 $_NOR_
      18 $_ORNOT_
       1 $_OR_
  not replaced 8 cell types:
      24 $_AND_
       1 $_NOT_
       2 SB_DFFES
      17 SB_DFFER
       2 SB_DFFR
       2 SB_DFFR_$abc9_byp
       2 SB_DFFES_$abc9_byp
      17 SB_DFFER_$abc9_byp

9.41.18.1. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.18.2. Executing ABC9_OPS pass (helper functions for ABC9).

9.41.18.3. Executing XAIGER backend.
<suppressed ~32 debug messages>
Extracted 98 AND gates and 341 wires from module `tqvp_spi_traffic' to a netlist network with 73 inputs and 49 outputs.

9.41.18.4. Executing ABC9_EXE pass (technology mapping using ABC9).

9.41.18.5. Executing ABC9.
Running ABC command: "<yosys-exe-dir>/yosys-abc" -s -f <abc-temp-dir>/abc.script 2>&1
ABC: ======== ABC command line "source <abc-temp-dir>/abc.script"
ABC: + read_lut <abc-temp-dir>/input.lut
ABC: + read_box <abc-temp-dir>/input.box
ABC: + &read <abc-temp-dir>/input.xaig
ABC: + &ps
ABC: <abc-temp-dir>/input : i/o =     73/     49  and =      98  lev =   13 (   0.98)  mem = 0.01 MB  box = 21  bb = 21
ABC: + &scorr
ABC: Warning: The network is combinational.
ABC: + &sweep
ABC: + &dc2
ABC: + &dch -f -r
ABC: + &ps
ABC: <abc-temp-dir>/input : i/o =     73/     49  and =     126  lev =   13 (   0.98)  mem = 0.01 MB  ch =   11  box = 21  bb = 21
ABC: cst =       0  cls =      9  lit =      11  unused =     200  proof =     0
ABC: + &if -W 250 -v
ABC: K = 4. Memory (bytes): Truth =    0. Cut =   64. Obj =  144. Set =  672. CutMin = no
ABC: Node =     126.  Ch =     9.  Total mem =    0.05 MB. Peak cut mem =    0.01 MB.
ABC: P:  Del = 3625.00.  Ar =      58.0.  Edge =      198.  Cut =      563.  T =     0.00 sec
ABC: P:  Del = 3625.00.  Ar =      55.0.  Edge =      194.  Cut =      554.  T =     0.00 sec
ABC: P:  Del = 5393.00.  Ar =      44.0.  Edge =      154.  Cut =      568.  T =     0.00 sec
ABC: F:  Del = 5393.00.  Ar =      41.0.  Edge =      147.  Cut =      572.  T =     0.00 sec
ABC: A:  Del = 4827.00.  Ar =      40.0.  Edge =      144.  Cut =      574.  T =     0.00 sec
ABC: A:  Del = 4827.00.  Ar =      40.0.  Edge =      144.  Cut =      576.  T =     0.00 sec
ABC: Total time =     0.00 sec
ABC: + &write -n <abc-temp-dir>/output.aig
ABC: + &mfs
ABC: The network is not changed by "&mfs".
ABC: + &ps -l
ABC: <abc-temp-dir>/input : i/o =     73/     49  and =     108  lev =   13 (   0.98)  mem = 0.01 MB  box = 21  bb = 21
ABC: Mapping (K=4)  :  lut =     40  edge =     144  lev =    7 (0.51)  levB =    8  mem = 0.00 MB
ABC: LUT = 40 : 2=5 12.5 %  3=6 15.0 %  4=29 72.5 %  Ave = 3.60
ABC: + &write -n <abc-temp-dir>/output.aig
ABC: + &verify
ABC: Networks are equivalent.  Time =     0.00 sec
ABC: + time
ABC: elapse: 0.01 seconds, total: 0.01 seconds

9.41.18.6. Executing AIGER frontend.
<suppressed ~255 debug messages>
Removed 144 unused cells and 298 unused wires.

9.41.18.7. Executing ABC9_OPS pass (helper functions for ABC9).
ABC RESULTS:              $lut cells:       41
ABC RESULTS:   \SB_DFFR_$abc9_byp cells:        2
ABC RESULTS:   \SB_DFFES_$abc9_byp cells:        2
ABC RESULTS:   \SB_DFFER_$abc9_byp cells:       17
ABC RESULTS:           input signals:       28
ABC RESULTS:          output signals:       11
Removing temp directory.

9.41.19. Executing TECHMAP pass (map to technology primitives).

9.41.19.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/abc9_unmap.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/abc9_unmap.v' to AST representation.
Generating RTLIL representation for module `$__DFF_x__$abc9_flop'.
Generating RTLIL representation for module `$__ABC9_SCC_BREAKER'.
Successfully finished Verilog frontend.

9.41.19.2. Continuing TECHMAP pass.
Using template SB_DFFER_$abc9_byp for cells of type SB_DFFER_$abc9_byp.
Using template SB_DFFES_$abc9_byp for cells of type SB_DFFES_$abc9_byp.
Using template SB_DFFR_$abc9_byp for cells of type SB_DFFR_$abc9_byp.
No more expansions possible.
<suppressed ~29 debug messages>

9.42. Executing ICE40_WRAPCARRY pass (wrap carries).

9.43. Executing TECHMAP pass (map to technology primitives).

9.43.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v' to AST representation.
Generating RTLIL representation for module `$_DFF_N_'.
Generating RTLIL representation for module `$_DFF_P_'.
Generating RTLIL representation for module `$_DFFE_NP_'.
Generating RTLIL representation for module `$_DFFE_PP_'.
Generating RTLIL representation for module `$_DFF_NP0_'.
Generating RTLIL representation for module `$_DFF_NP1_'.
Generating RTLIL representation for module `$_DFF_PP0_'.
Generating RTLIL representation for module `$_DFF_PP1_'.
Generating RTLIL representation for module `$_DFFE_NP0P_'.
Generating RTLIL representation for module `$_DFFE_NP1P_'.
Generating RTLIL representation for module `$_DFFE_PP0P_'.
Generating RTLIL representation for module `$_DFFE_PP1P_'.
Generating RTLIL representation for module `$_SDFF_NP0_'.
Generating RTLIL representation for module `$_SDFF_NP1_'.
Generating RTLIL representation for module `$_SDFF_PP0_'.
Generating RTLIL representation for module `$_SDFF_PP1_'.
Generating RTLIL representation for module `$_SDFFCE_NP0P_'.
Generating RTLIL representation for module `$_SDFFCE_NP1P_'.
Generating RTLIL representation for module `$_SDFFCE_PP0P_'.
Generating RTLIL representation for module `$_SDFFCE_PP1P_'.
Successfully finished Verilog frontend.

9.43.2. Continuing TECHMAP pass.
No more expansions possible.
<suppressed ~22 debug messages>
Removed 10 unused cells and 654 unused wires.

9.44. Executing OPT_LUT pass (optimize LUTs).
Discovering LUTs.
Number of LUTs:       41
  1-LUT                1
  2-LUT                5
  3-LUT                6
  4-LUT               29
  with \SB_CARRY    (#0)    0
  with \SB_CARRY    (#1)    0

Eliminating LUTs.
Number of LUTs:       41
  1-LUT                1
  2-LUT                5
  3-LUT                6
  4-LUT               29
  with \SB_CARRY    (#0)    0
  with \SB_CARRY    (#1)    0

Combining LUTs.
Number of LUTs:       41
  1-LUT                1
  2-LUT                5
  3-LUT                6
  4-LUT               29
  with \SB_CARRY    (#0)    0
  with \SB_CARRY    (#1)    0

Eliminated 0 LUTs.
Combined 0 LUTs.
<suppressed ~215 debug messages>

9.45. Executing TECHMAP pass (map to technology primitives).

9.45.1. Executing Verilog-2005 frontend: C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v
Parsing Verilog input from `C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v' to AST representation.
Generating RTLIL representation for module `$lut'.
Successfully finished Verilog frontend.

9.45.2. Continuing TECHMAP pass.
Using template $paramod$658b9ed803f0d3d335616d3858b53e0a2522f1e8$lut for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000011\LUT=8'00101010 for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000010\LUT=4'0100 for cells of type $lut.
Using template $paramod$65d5d5c1e01bf41ee659754efba932f3d99198e5$lut for cells of type $lut.
Using template $paramod$43779580bfffd5d5a9f321249a174febf1dac288$lut for cells of type $lut.
Using template $paramod$6f3f060a82077d7722793a80a7f81ffcda8e7f4d$lut for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000010\LUT=4'0010 for cells of type $lut.
Using template $paramod$2f927054f797a5706e69053a974d4b702d1f3194$lut for cells of type $lut.
Using template $paramod$a23abd5573f0b1eda1acce323f6ae8f8e92a28a1$lut for cells of type $lut.
Using template $paramod$25003f26a78bb2f583f23824f1e0b8cc16b88761$lut for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000011\LUT=8'00000111 for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000011\LUT=8'01110000 for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000010\LUT=4'1000 for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000010\LUT=4'0111 for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000010\LUT=4'1011 for cells of type $lut.
Using template $paramod$c28a8b7ce0535d090c4cfb52e9c74affd52b110c$lut for cells of type $lut.
Using template $paramod$5e9374f44a27c3f8a1c38af244ec43ceb4fb8d4f$lut for cells of type $lut.
Using template $paramod$6e238df02989b317f10820a22773676e71120644$lut for cells of type $lut.
Using template $paramod$f8f63b209b7230e81958663ff24fef1613156af7$lut for cells of type $lut.
Using template $paramod$101238f3d8d49ab12a9b49a2f01cd503b26e9c61$lut for cells of type $lut.
Using template $paramod$1bf3509a544426de1daa8b6919ee1df60c7165ec$lut for cells of type $lut.
Using template $paramod$f7cbd8f5974233f70d25c33ef6a692898e4f6377$lut for cells of type $lut.
Using template $paramod$097592bb16245531f0716c5ddb18d7090f9c7d9d$lut for cells of type $lut.
Using template $paramod$272652f6c6fbe9a75eff76e45cc7e2788835518b$lut for cells of type $lut.
Using template $paramod$1c2286bef9a6702a426ede0fc9afc3ceab10d154$lut for cells of type $lut.
Using template $paramod$873c285bdccf0ac2b60d2304ea5cd14bf211d2a6$lut for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000011\LUT=8'10001111 for cells of type $lut.
Using template $paramod$0d3ac82cf5b8a192d5ff4c23e3143360366ae882$lut for cells of type $lut.
Using template $paramod$5dc745bb48e2cf535179547ba13f0fe5364d6d54$lut for cells of type $lut.
Using template $paramod$lut\WIDTH=32'00000000000000000000000000000001\LUT=2'01 for cells of type $lut.
No more expansions possible.
<suppressed ~434 debug messages>
Removed 0 unused cells and 106 unused wires.

9.46. Executing AUTONAME pass.
Renamed 90 objects in module tqvp_spi_traffic (29 iterations).
<suppressed ~90 debug messages>

9.47. Executing HIERARCHY pass (managing design hierarchy).
Attribute `top' found on module `tqvp_spi_traffic'. Setting top module to tqvp_spi_traffic.

9.47.1. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic

9.47.2. Analyzing design hierarchy..
Top module:  \tqvp_spi_traffic
Removed 0 unused modules.

9.48. Printing statistics.

=== tqvp_spi_traffic ===

        +----------Local Count, excluding submodules.
        |
       46 wires
      198 wire bits
       46 public wires
      198 public wire bits
       11 ports
       94 port bits
       62 submodules
       17   SB_DFFER
        2   SB_DFFES
        2   SB_DFFR
       41   SB_LUT4

=== design hierarchy ===

        +----------Count including submodules.
        |
        - tqvp_spi_traffic

        +----------Count including submodules.
        |
       46 wires
      198 wire bits
       46 public wires
      198 public wire bits
       11 ports
       94 port bits
        - memories
        - memory bits
        - processes
        - cells
       62 submodules
       17   SB_DFFER
        2   SB_DFFES
        2   SB_DFFR
       41   SB_LUT4

9.49. Executing CHECK pass (checking for obvious problems).
Checking module tqvp_spi_traffic...
Found and reported 0 problems.

9.50. Executing JSON backend.


#timing/              # Timing analysis

#timing/              # Timing analysis

[OSS CAD Suite] C:\Users\moral\Desktop\Things>nextpnr-ice40 --json my_design.json
Warning: Use of default value for --package is deprecated. Please add '--package ' to arguments.
Warning: No PCF file specified; IO pins will be placed automatically

Info: Packing constants..
Info: Packing IOs..
Info: Packing LUT-FFs..
Info:       40 LCs used as LUT4 only
Info:        1 LCs used as LUT4 and DFF
Info: Packing non-LUT FFs..
Info:       20 LCs used as DFF only
Info: Packing carries..
Info:        0 LCs used as CARRY only
Info: Packing indirect carry+LUT pairs...
Info:        0 LUTs merged into carry LCs
Info: Packing RAMs..
Info: Placing PLLs..
Info: Packing special functions..
Info: Packing PLLs..
Info: Promoting globals..
Info: promoting clk$SB_IO_IN (fanout 21)
Info: promoting rst_n_SB_LUT4_I3_O [reset] (fanout 21)
Info: Constraining chains...
Info:        0 LCs used to legalise carry chains.
Info: Checksum: 0x5072b725

Info: Device utilisation:
Info:            ICESTORM_LC:      63/   1280     4%
Info:           ICESTORM_RAM:       0/     16     0%
Info:                  SB_IO:      94/     96    97%
Info:                  SB_GB:       2/      8    25%
Info:           ICESTORM_PLL:       0/      1     0%
Info:            SB_WARMBOOT:       0/      1     0%

Info: Placed 0 cells based on constraints.
Info: Creating initial analytic placement for 65 cells, random placement wirelen = 1246.
Info:     at initial placer iter 0, wirelen = 309
Info:     at initial placer iter 1, wirelen = 316
Info:     at initial placer iter 2, wirelen = 329
Info:     at initial placer iter 3, wirelen = 311
Info: Running main analytical placer, max placement attempts per cell = 10000.
Info:     at iteration #1, type SB_GB: wirelen solved = 311, spread = 314, legal = 314; time = 0.00s
Info:     at iteration #1, type ICESTORM_LC: wirelen solved = 328, spread = 382, legal = 396; time = 0.00s
Info:     at iteration #1, type ALL: wirelen solved = 310, spread = 379, legal = 400; time = 0.00s
Info:     at iteration #2, type SB_GB: wirelen solved = 397, spread = 399, legal = 400; time = 0.00s
Info:     at iteration #2, type ICESTORM_LC: wirelen solved = 332, spread = 378, legal = 399; time = 0.00s
Info:     at iteration #2, type ALL: wirelen solved = 317, spread = 382, legal = 413; time = 0.00s
Info:     at iteration #3, type SB_GB: wirelen solved = 409, spread = 412, legal = 413; time = 0.00s
Info:     at iteration #3, type ICESTORM_LC: wirelen solved = 335, spread = 384, legal = 401; time = 0.00s
Info:     at iteration #3, type ALL: wirelen solved = 324, spread = 386, legal = 413; time = 0.00s
Info:     at iteration #4, type SB_GB: wirelen solved = 409, spread = 412, legal = 413; time = 0.00s
Info:     at iteration #4, type ICESTORM_LC: wirelen solved = 339, spread = 385, legal = 410; time = 0.00s
Info:     at iteration #4, type ALL: wirelen solved = 328, spread = 387, legal = 413; time = 0.00s
Info:     at iteration #5, type SB_GB: wirelen solved = 409, spread = 412, legal = 413; time = 0.00s
Info:     at iteration #5, type ICESTORM_LC: wirelen solved = 342, spread = 379, legal = 400; time = 0.00s
Info:     at iteration #5, type ALL: wirelen solved = 340, spread = 382, legal = 395; time = 0.00s
Info: HeAP Placer Time: 0.04s
Info:   of which solving equations: 0.02s
Info:   of which spreading cells: 0.00s
Info:   of which strict legalisation: 0.00s

Info: Running simulated annealing placer for refinement.
Info:   at iteration #1: temp = 0.000000, timing cost = 16, wirelen = 395
Info:   at iteration #5: temp = 0.000000, timing cost = 17, wirelen = 223
Info:   at iteration #10: temp = 0.000000, timing cost = 17, wirelen = 222
Info:   at iteration #15: temp = 0.000000, timing cost = 17, wirelen = 215
Info:   at iteration #17: temp = 0.000000, timing cost = 17, wirelen = 212
Info: SA placement time 0.05s

Info: Max frequency for clock 'clk$SB_IO_IN_$glb_clk': 123.40 MHz (PASS at 12.00 MHz)

Info: Max delay <async>                       -> <async>                      : 6.38 ns
Info: Max delay <async>                       -> posedge clk$SB_IO_IN_$glb_clk: 5.61 ns
Info: Max delay posedge clk$SB_IO_IN_$glb_clk -> <async>                      : 8.97 ns

Info: Slack histogram:
Info:  legend: * represents 1 endpoint(s)
Info:          + represents [1,1) endpoint(s)
Info: [ 75229,  75555) |*
Info: [ 75555,  75881) |
Info: [ 75881,  76207) |*
Info: [ 76207,  76533) |
Info: [ 76533,  76859) |
Info: [ 76859,  77185) |
Info: [ 77185,  77511) |
Info: [ 77511,  77837) |
Info: [ 77837,  78163) |
Info: [ 78163,  78489) |
Info: [ 78489,  78815) |
Info: [ 78815,  79141) |
Info: [ 79141,  79467) |
Info: [ 79467,  79793) |
Info: [ 79793,  80119) |
Info: [ 80119,  80445) |
Info: [ 80445,  80771) |
Info: [ 80771,  81097) |
Info: [ 81097,  81423) |
Info: [ 81423,  81749) |*
Info: Checksum: 0x22a65df5

Info: Routing..
Info: Setting up routing queue.
Info: Routing 232 arcs.
Info:            |   (re-)routed arcs  |   delta    | remaining|       time spent     |
Info:    IterCnt |  w/ripup   wo/ripup |  w/r  wo/r |      arcs| batch(sec) total(sec)|
Info:        255 |       19        236 |   19   236 |         0|       0.06       0.06|
Info: Routing complete.
Info: Router1 time 0.06s
Info: Checksum: 0x86733065

Info: Critical path report for clock 'clk$SB_IO_IN_$glb_clk' (posedge -> posedge):
Info:       type curr  total name
Info:   clk-to-q  0.54  0.54 Source data_out_SB_LUT4_O_5_I0_SB_DFFER_Q_DFFLC.O
Info:    routing  0.59  1.13 Net data_out_SB_LUT4_O_5_I0[0] (2,2) -> (1,2)
Info:                          Sink data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_LC.I0
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.45  1.58 Source data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_LC.O
Info:    routing  0.59  2.16 Net data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_O[0] (1,2) -> (1,2)
Info:                          Sink data_out_SB_LUT4_O_I1_SB_LUT4_O_1_LC.I0
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.45  2.61 Source data_out_SB_LUT4_O_I1_SB_LUT4_O_1_LC.O
Info:    routing  0.59  3.20 Net data_out_SB_LUT4_O_I1[3] (1,2) -> (2,2)
Info:                          Sink data_out_SB_LUT4_O_3_I1_SB_LUT4_O_1_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  3.52 Source data_out_SB_LUT4_O_3_I1_SB_LUT4_O_1_LC.O
Info:    routing  0.59  4.10 Net data_out_SB_LUT4_O_3_I1[3] (2,2) -> (2,3)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  4.42 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3_SB_LUT4_O_LC.O
Info:    routing  0.59  5.01 Net loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3[3] (2,3) -> (2,4)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  5.32 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_O_LC.O
Info:    routing  0.59  5.91 Net data_out_SB_LUT4_O_7_I2[3] (2,4) -> (2,5)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_I3_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  6.22 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_I3_LC.O
Info:    routing  0.59  6.81 Net data_out_SB_LUT4_O_6_I2[3] (2,5) -> (2,6)
Info:                          Sink user_interrupt_SB_DFFER_Q_E_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  7.13 Source user_interrupt_SB_DFFER_Q_E_SB_LUT4_O_LC.O
Info:    routing  1.30  8.43 Net user_interrupt_SB_DFFER_Q_E (2,6) -> (2,6)
Info:                          Sink user_interrupt_SB_DFFER_Q_D_SB_LUT4_O_LC.CEN
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:121.5-149.8
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v:14.63-14.116
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:656.8-656.9
Info:      setup  0.10  8.53 Source user_interrupt_SB_DFFER_Q_D_SB_LUT4_O_LC.CEN
Info: 3.11 ns logic, 5.42 ns routing

Info: Critical path report for cross-domain path '<async>' -> '<async>':
Info:       type curr  total name
Info:     source  0.00  0.00 Source address[2]$sb_io.D_IN_0
Info:    routing  1.28  1.28 Net address[2]$SB_IO_IN (0,8) -> (1,5)
Info:                          Sink data_out_SB_LUT4_O_I2_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:116.16-116.23
Info:      logic  0.31  1.60 Source data_out_SB_LUT4_O_I2_SB_LUT4_O_LC.O
Info:    routing  0.59  2.18 Net data_out_SB_LUT4_O_6_I2_SB_LUT4_O_I3[2] (1,5) -> (1,4)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_I1_O_SB_LUT4_O_LC.I2
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.38  2.56 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_I1_O_SB_LUT4_O_LC.O
Info:    routing  0.59  3.15 Net loop_s1_SB_DFFR_D_Q_SB_LUT4_I1_O[2] (1,4) -> (1,4)
Info:                          Sink data_out_SB_LUT4_O_6_I2_SB_LUT4_O_1_LC.I2
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.38  3.53 Source data_out_SB_LUT4_O_6_I2_SB_LUT4_O_1_LC.O
Info:    routing  0.59  4.12 Net data_out_SB_LUT4_O_6_I2[2] (1,4) -> (1,5)
Info:                          Sink data_out_SB_LUT4_O_6_LC.I2
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.38  4.49 Source data_out_SB_LUT4_O_6_LC.O
Info:    routing  1.90  6.40 Net data_out[1]$SB_IO_OUT (1,5) -> (13,6)
Info:                          Sink data_out[1]$sb_io.D_OUT_0
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:48.19-48.27
Info: 1.45 ns logic, 4.95 ns routing

Info: Critical path report for cross-domain path '<async>' -> 'posedge clk$SB_IO_IN_$glb_clk':
Info:       type curr  total name
Info:     source  0.00  0.00 Source address[2]$sb_io.D_IN_0
Info:    routing  1.28  1.28 Net address[2]$SB_IO_IN (0,8) -> (1,5)
Info:                          Sink data_write_n_SB_LUT4_I2_1_I3_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:116.16-116.23
Info:      logic  0.31  1.60 Source data_write_n_SB_LUT4_I2_1_I3_SB_LUT4_O_LC.O
Info:    routing  0.59  2.18 Net data_out_SB_LUT4_O_6_I2_SB_LUT4_O_I3[3] (1,5) -> (2,4)
Info:                          Sink data_write_n_SB_LUT4_I2_1_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  2.50 Source data_write_n_SB_LUT4_I2_1_LC.O
Info:    routing  0.59  3.09 Net data_write_n_SB_LUT4_I2_1_O (2,4) -> (2,4)
Info:                          Sink data_out_SB_LUT4_O_6_I3_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:121.5-149.8
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v:14.63-14.116
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:656.8-656.9
Info:      logic  0.31  3.40 Source data_out_SB_LUT4_O_6_I3_SB_LUT4_O_LC.O
Info:    routing  0.96  4.36 Net data_out_SB_LUT4_O_6_I3[0] (2,4) -> (2,6)
Info:                          Sink user_interrupt_SB_DFFER_Q_E_SB_LUT4_O_LC.I2
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.38  4.74 Source user_interrupt_SB_DFFER_Q_E_SB_LUT4_O_LC.O
Info:    routing  1.30  6.04 Net user_interrupt_SB_DFFER_Q_E (2,6) -> (2,6)
Info:                          Sink user_interrupt_SB_DFFER_Q_D_SB_LUT4_O_LC.CEN
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:121.5-149.8
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/ff_map.v:14.63-14.116
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_sim.v:656.8-656.9
Info:      setup  0.10  6.14 Source user_interrupt_SB_DFFER_Q_D_SB_LUT4_O_LC.CEN
Info: 1.42 ns logic, 4.72 ns routing

Info: Critical path report for cross-domain path 'posedge clk$SB_IO_IN_$glb_clk' -> '<async>':
Info:       type curr  total name
Info:   clk-to-q  0.54  0.54 Source data_out_SB_LUT4_O_5_I0_SB_DFFER_Q_DFFLC.O
Info:    routing  0.59  1.13 Net data_out_SB_LUT4_O_5_I0[0] (2,2) -> (1,2)
Info:                          Sink data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_LC.I0
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.45  1.58 Source data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_LC.O
Info:    routing  0.59  2.16 Net data_out_SB_LUT4_O_2_I0_SB_LUT4_I2_O[0] (1,2) -> (1,2)
Info:                          Sink data_out_SB_LUT4_O_I1_SB_LUT4_O_1_LC.I0
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.45  2.61 Source data_out_SB_LUT4_O_I1_SB_LUT4_O_1_LC.O
Info:    routing  0.59  3.20 Net data_out_SB_LUT4_O_I1[3] (1,2) -> (2,2)
Info:                          Sink data_out_SB_LUT4_O_3_I1_SB_LUT4_O_1_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  3.52 Source data_out_SB_LUT4_O_3_I1_SB_LUT4_O_1_LC.O
Info:    routing  0.59  4.10 Net data_out_SB_LUT4_O_3_I1[3] (2,2) -> (2,3)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  4.42 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3_SB_LUT4_O_LC.O
Info:    routing  0.59  5.01 Net loop_s1_SB_DFFR_D_Q_SB_LUT4_O_I3[3] (2,3) -> (2,4)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_O_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  5.32 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_O_LC.O
Info:    routing  0.59  5.91 Net data_out_SB_LUT4_O_7_I2[3] (2,4) -> (2,5)
Info:                          Sink loop_s1_SB_DFFR_D_Q_SB_LUT4_I3_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  6.22 Source loop_s1_SB_DFFR_D_Q_SB_LUT4_I3_LC.O
Info:    routing  0.59  6.81 Net data_out_SB_LUT4_O_6_I2[3] (2,5) -> (1,5)
Info:                          Sink data_out_SB_LUT4_O_6_LC.I3
Info:                          Defined in:
Info:                               C:\oss-cad-suite\bin\../share/yosys/ice40/cells_map.v:6.21-6.22
Info:      logic  0.31  7.13 Source data_out_SB_LUT4_O_6_LC.O
Info:    routing  1.90  9.03 Net data_out[1]$SB_IO_OUT (1,5) -> (13,6)
Info:                          Sink data_out[1]$sb_io.D_OUT_0
Info:                          Defined in:
Info:                               tqvp_spi_traffic.v:48.19-48.27
Info: 3.01 ns logic, 6.02 ns routing

Info: Max frequency for clock 'clk$SB_IO_IN_$glb_clk': 117.23 MHz (PASS at 12.00 MHz)

Info: Max delay <async>                       -> <async>                      : 6.40 ns
Info: Max delay <async>                       -> posedge clk$SB_IO_IN_$glb_clk: 6.14 ns
Info: Max delay posedge clk$SB_IO_IN_$glb_clk -> <async>                      : 9.03 ns

Info: Slack histogram:
Info:  legend: * represents 1 endpoint(s)
Info:          + represents [1,1) endpoint(s)
Info: [ 74803,  75150) |*
Info: [ 75150,  75497) |
Info: [ 75497,  75844) |
Info: [ 75844,  76191) |*
Info: [ 76191,  76538) |
Info: [ 76538,  76885) |
Info: [ 76885,  77232) |
Info: [ 77232,  77579) |
Info: [ 77579,  77926) |
Info: [ 77926,  78273) |
Info: [ 78273,  78620) |
Info: [ 78620,  78967) |
Info: [ 78967,  79314) |
Info: [ 79314,  79661) |
Info: [ 79661,  80008) |
Info: [ 80008,  80355) |
Info: [ 80355,  80702) |
Info: [ 80702,  81049) |
Info: [ 81049,  81396) |
Info: [ 81396,  81743) |*
2 warnings, 0 errors

Info: Program finished normally.

