# Maestros - Challenge 2 Submission

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
The goal of this challenge was to optimize the initial version of the WiFi-assisted traffic light peripheral for power, performance, and area (PPA) without destroying its behavior. While the original design worked fine, there were many inefficiencies that left registers and critical paths longer than necessary. Our approach was to modify the microarchitecture to produce a smaller, faster, and more power efficient implementation.

## Key Features
- Feature 1: Pipelining
  - Congestion and loop detection signals are latched a cycle early to break the long combinatorial chain from the SPI shift register to the interrupt output.
- Feature 2: Clock Gating
  - Control and WiFi count registers have their own write enable so OpenLane can infer clock-gate cells to stop registers from toggling on idle cycles.
- Feature 3: Hardware Threshold
  - The congestion threshold is hardcoded instead of storing and comparing a configurable value, eliminating a whole register.
- Feature 4: Single Expression IRQ Logic
  - The interrup pending register is updated with one boolean equation instead of lengthy if/else chain.

## AI Tools Used
- Primary LLM: ChatGPT-4, Claude, Gemini
- Additional tools: N/A
- Total AI interactions: 5+

## Results Summary
- **Functionality**: Pass
- **FPGA Implementation**: Success
- **Resource Usage**: 59 cells, Area = 751.9712 μm^2
- **Timing**: 92 MHz

## Innovation Highlights
The most significant change was reducing the combinatorial work done in one cycle, especially since the signal for our purpose did not need to by accurate down to the cycle. Traffic light controllers can tolerate some degrees of detection latency without consequences, so utilizing this to our benefit, we could pipeline both the status signals for timing and register them for power at the same time. 

## Team Reflection
We worked through the code more than once because we ran into some issues about fanout and our very first change did not produce better PPA results. However, through this process we learned that prioritizing PPA optimization versus execution latency requires different RTL code writing, and it all depends on the set design goal.