##results    # Testing and implementation results
                
#simulation/           # Simulation outputs
#synthesis/            # Synthesis reports
#fpga/                # FPGA implementation results
#timing/              # Timing analysis

#simulation

#synthesis

#fpga



#timing

yosys> nextpnr-ice40 --json my_design.json
ERROR: No such command: nextpnr-ice40 (type 'help' for a command overview)

yosys> exit

End of script. Logfile hash: c22dc53c2e
Yosys 0.64+172 (git sha1 92287d485-dirty, x86_64-w64-mingw32-g++ 13.2.1 -O3)
Time spent: 1% 53x opt_expr (0 sec), 1% 49x opt_clean (0 sec), ...

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

[OSS CAD Suite] C:\Users\moral\Desktop\Things>