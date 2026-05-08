# Maestros - Challenge 3 Submission

## Team Information
- **Team Name**: Maestros
- **Institution**: University of Arizona
- **Division**: Lower
- **Team Members**: 
  - Candice Liu - Team Member - [candiceliu@arizona.edu]
  - Daniel Onesimo Dong - Team Member - [onesimod@arizona.edu]
  - April Morales - Team Member - [aprilmorales@arizona.edu]
- **Mentor**: Harish Kumar Dharavath [harrydhara16@arizona.edu]

## Challenge Summary
  The goal of this challenge was to take the secure design from challenge 3 and turn it into a final physical layout. While we already had passing DRC and LVS checks, we wanted to ensure as little violations as possible, so we ran a highly iterative process to reduce the antenna (pin and net) and max fanout violations to be as small as possible. The end result of the challenge was to get a complete GDSII file for tapeout.

## Key Features
- Feature 1: Authenticated SPI Interface
  - 32-bit packet format (command, data, sequence, tag) with CRC8-keyed
    authentication using polynomial x⁸+x²+x+1
    - Replay attack protection via per-packet sequence number tracking,
      rejecting reused sequence numbers from previous valid transactions
- Feature 2: Privilege Separation & Access Control
  - SPI is restricted exclusively to REG_WIFI_COUNT writes; REG_CTRL
    and REG_THRESHOLD are bus-only, preventing remote enable/disable
    - Security tie-offs explicitly hold SPI CTRL and THRESHOLD write
      enables permanently low in hardware
- Feature 3: Inductive Loop Detection
  - 3-stage synchronizer feeding a 15-cycle glitch filter, ensuring
    loop inactivity is stable before any supplemental request is issued
    - Wi-Fi supplemental request is suppressed while loop is active,
      preventing false congestion signals during occupied intersections
- Feature 4: Wi-Fi Congestion Monitoring
  - Configurable threshold register (1–15) with bus-side clamping to
    prevent a zero threshold from flagging every count as congested
    - Low-power prescaled timeout watchdog: a small 8-bit prescaler
      gates the wide 16-bit timeout counter, minimizing switching activity
- Feature 5: Flexible Output Modes
  - Software-selectable level mode (sustained request while demand is
    present) or one-shot pulse mode (fixed-width pulse on rising demand)
    - Edge-latched interrupt with software-clearable pending flag,
      allowing firmware acknowledgment without losing subsequent events
- Feature 6: Physical Implementation Closure
  - Manual antenna diode instantiation under `SYNTHESIS` guard for
    marginal met1 side-area violations unfixable through automated flow
    - Clean Magic DRC (0 violations) and Netgen LVS signoff on sky130A
      130nm process at 300×300 µm die area

## AI Tools Used
- Primary LLM: ChatGPT-4, Claude, Gemini
- Additional tools: N/A
- Total AI interactions: 18

## Results Summary
- **Functionality**: Pass
- **FPGA Implementation**: Success
- **Resource Usage**: 689 cells, Area = 8132.8 μm^2
- **Timing**: 163 MHz

## Innovation Highlights
The design evolved across three generations before physical tapeout. The initial implementation (Design 1) established the core traffic control logic — inductive loop detection, Wi-Fi congestion monitoring, and a supplemental request output — but used wide combinatorial paths and unsynchronized inputs unsuitable for silicon. Design 2 focused on PPA optimization: outputs were registered to break long combinatorial chains, the Wi-Fi timeout counter adopted a prescaler architecture to minimize switching power on the wide counter, and the read mux was gated on read_en to eliminate unnecessary toggling on idle cycles. Design 3 introduced the security architecture, adding a 32-bit SPI packet format with CRC8-keyed authentication, replay protection via sequence tracking, brute-force lockout after repeated authentication failures, and explicit privilege separation restricting SPI to a single writable register. The final implementation consolidated these features while resolving physical closure challenges encountered during OpenLane tapeout, including manual antenna diode insertion for marginal routing violations and reset tree staging to manage the fanout demands of a 137-flop design within a tight floorplan.
  
## Team Reflection
The entire AI-HDL project taught us that a strong hardware design is not only about making the code work. It also requires defining trust boundaries, limiting external authority, protecting configuration registers, handling stale data, verifying failure cases, and choosing tradeoffs that match the real application. The final TinyQV peripheral is more secure, more realistic, and more defensible because it evolved from a general WiFi traffic-light idea into a constrained supplemental sensor interface with clear safety and security behavior.