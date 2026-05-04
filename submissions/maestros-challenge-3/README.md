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
  [TO DO]

## Key Features
- Feature 1: True SPI input from ESP32
  - The design includes a simple SPI slave receiver. The ESP32 can send a Wi-Fi device count into TinyQV using external pins:
    - ui_in[1] = SPI SCK
    - ui_in[2] = SPI CS_N
    - ui_in[3] = SPI MOSI
- Feature 2: Internal register storage
  - The Wi-Fi count and threshold is stored internally in wifi_count_reg and threshold_reg. It remembers the last valid Wi-Fi count from the ESP32 and uses that value until a new SPI update arrives. The TinyQV bus can also read or write these registers, which is useful for debugging and simulation.
- Feature 3: Programmable threshold under a 15 count value
  - Instead of hardcoding congestion, we check if wifi_count_reg >= threshold_reg. Although a small value, this peripheral is more of a helper tool, so the decreased value is acceptable. 
- Feature 4: Loop detector monitoring
  - The inductive loop detector is connected to ui_in[0] and the signal is synchronized with flip-flops before being used internally:
    - loop_s1
    - loop_s2
    - loop_detect_r
  - That reduces metastability risk when the external loop-detect signal changes asynchronously relative to the TinyQV clock.
- Feature 5: Loop detector has priority
  - The design only asserts a supplemental Wi-Fi request when the loop detector is inactive AND Wi-Fi count is greater than or equal to threshold AND controller is enabled. So if the loop detector is active, the TinyQV Wi-Fi request is suppressed, keeping the original legacy traffic light loop the primary traffic-control input.
- Feature 6: Level mode and pulse mode
  - The design supports two output styles where the mode is selected with ctrl_reg[1] where: 
    - ctrl_reg[1] = 0 -> level mode
    - ctrl_reg[1] = 1 -> pulse mode
  - Level request mode
    - The request stays high as long as demand is present which is useful if the legacy controller expects a held demand signal.
  - Pulse request mode (This design is based here)
    - The request produces a short pulse when demand first appears which is useful if the 555/controller circuitry expects a trigger pulse instead of a held level.

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
  This design is practical because it is smaller and safer. It avoids large timing counters, red/yellow/green sequencing, all-red timing, minimum green timing, direct light control, and safety-critical phase transitions of the desired legacy traffic lights. Instead, the legacy traffic controller keeps responsibility for timing, while TinyQV adds a supplemental demand signal. The TinyQV peripheral enhances an existing loop-based traffic controller by adding Wi-Fi-count-based supplemental demand detection. It preserves the original inductive-loop/555-timer behavior as the primary control path and only asserts a request when the loop detector is inactive and Wi-Fi density exceeds a programmable threshold.

## Team Reflection
  [TO DO]