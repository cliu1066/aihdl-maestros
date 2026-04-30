# Maestros - Challenge 1 Submission

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
The design implements a WiFi-assisted smart traffic light controller as a peripheral to
the TinyQV RISC-V processor core. This peripheral connects a ESP32 WiFi module to the
RISC-V processor through an SPI communication protocol, allowing vehicles at an 
intersection to be detected and translated to a light-change signal for the processor.
The ESP32 counts WiFi-connected devices in the intersection (representing vehicles) and
communicates this number to the RISC-V core, which then determines whether the light
should change color. When WiFi is unavailable, the system falls back into a traditional
inductive loop detector so the system is always managed.

## Key Features
- Feature 1: Dual-Mode Vehicle Detection
  - Two forms of independent detection paths - WiFi-based counting through ESP32 and
    simple inductive loop for hardware fallback with each working simultaneously.
- Feature 2: Congestion-Aware Thresholding
  - Instead of triggering on any single vehicle, the WiFi path uses a configurable
    threshold register to differentiate between isolated presence and actual congestion.
- Feature 3: Level-Triggered Interrupt
  - The user interrupt stays asserted until explicitly cleared, and if the triggering
    condition is still active while clearing, the interrupt immediately re-asserts to
    prevent a missed event during the ISR.
- Feature 4: Single-Cycle Register Interface
  - Register reads and writes complete in one clock cycle, preventing any pipeline
    stalls.

## AI Tools Used
- Primary LLM: ChatGPT-4, Claude, Gemini
- Additional tools: N/A
- Total AI interactions: 5+

## Results Summary
- **Functionality**: Pass
- **FPGA Implementation**: [Success/Failure]
- **Resource Usage**: [LUTs, FFs, DSPs used]
- **Timing**: [Max frequency achieved]

## Innovation Highlights
Our solution is distinctive because it utilizes a hybrid sensing technology. Instead
of choosing between WiFi and inductive detection, both coexist with equal priority
and independent status bits, making the system resilient to infrastructure failure
even without software intervention. The threshold mechanism reframes the detection
problem from asking whether a car is present to whether there is enough demand to
justify changing the light - reflecting a more realistic model of how smart 
intersections behave. In addition, routing the ESP32 through the RISC-V peripheral
bus instead of directly controlling the lights keeps all decision logic on the 
processor side, making the system behavior entirely programmable without needing to
change any hardware.

## Team Reflection
We learned how to organize our many ideas into one peripheral to the RISC-V core.
Initially, we had many ideas about communication protocols, controlling traffic lights,
and external modules, but we had to evaluate the feasibility of combining these ideas
into one peripheral without being too complicated. We also learned effective prompt
engineering and how to best communicate (and corroborate information) with our 
respective LLMs. We also had to refresh our knowledge on SPI communication, Git, and
RTL code.