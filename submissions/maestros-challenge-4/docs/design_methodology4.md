# Design Methodology

## Initial Approach
How did you start? What was your overall strategy?

The design process began with a WiFi-assisted traffic-light peripheral for the TinyQV RISC-V system. The original goal was to use an ESP32 as a supplemental sensing device that could estimate nearby traffic demand through WiFi device counting and send that count to the TinyQV peripheral through SPI. The design also preserved the original inductive-loop detector so the system would still have a traditional fallback path if WiFi data was unavailable, stale, or unreliable.

Our overall strategy was to build the design in stages instead of trying to create the final design all at once. DP1 focused on proving that the basic functionality worked: receiving a WiFi count, storing it in internal registers, comparing it against a threshold, monitoring the inductive-loop detector, and generating a supplemental request signal. DP2 focused on power, performance, and area improvements by simplifying logic, reducing unnecessary registers, and restructuring control paths. DP3 focused on security and robustness by adding authenticated SPI packets, replay protection, stale-data timeout, lockout behavior, privilege separation, loop-detector filtering, and security status reporting. DP4 served as the final integration and consolidation stage, where the security-hardened version was selected as the final design because it provided the best balance of functionality, timing, and security.

The first step was not only to ask AI to generate code, but to ask AI to identify possible weaknesses in the original architecture. These weaknesses included unauthenticated ESP32 input, replayed SPI messages, stale WiFi counts, over-trusting the ESP32, loop-detector glitches, and interrupt behavior that could either miss events or remain asserted too long. After identifying these risks, we selected security features that were realistic for a TinyQV/TinyTapeout-style design and avoided features that would be too large or impractical for the target hardware.

## AI Integration Strategy
How did you plan to use AI tools? What was your prompting strategy?

The team used multiple AI tools, including ChatGPT-4, Claude, and Gemini, throughout the design process. AI was used for RTL generation, design review, testbench creation, debugging, report writing, PPA analysis, and security analysis. The main reason for using more than one AI tool was to avoid relying on a single system to both generate and verify the same answer. In many cases, one AI tool was used to create or revise a design, and another AI tool was used to check whether the design matched our intended behavior.

Our prompting strategy was iterative and task-specific. Instead of asking AI to create the entire peripheral in one large prompt, we divided the design into smaller pieces. These included SPI input handling, register mapping, WiFi count storage, threshold comparison, loop-detector synchronization, interrupt behavior, PPA optimization, authentication, replay protection, lockout behavior, and stale-data timeout. This made the generated code easier to review and helped prevent the design from drifting away from the original traffic-light purpose.

For security-related work, the team first asked AI to identify possible vulnerabilities before asking for RTL changes. After receiving suggestions, we compared them against the size and timing limits of the project. Some ideas, such as stronger cryptographic authentication, were useful conceptually but too expensive for the final TinyQV peripheral. The final design therefore uses a keyed CRC8 tag, sequence checking, stale-data timeout, and brute-force lockout as lightweight protections that fit the project constraints. Team members with stronger security knowledge guided the authentication and mitigation prompts, while the rest of the team checked that the traffic-light behavior still matched the original requirements.

## Design Evolution
How did your design change throughout the process?

The design changed significantly from the first functional version to the final submission version.

In DP1, the design was mainly focused on functionality. The peripheral supported dual-mode vehicle detection using both WiFi-based counting and an inductive-loop input. The ESP32 provided a WiFi count through SPI, the count was stored internally, and the RISC-V bus could read or write key registers. The design compared the WiFi count against a threshold and generated a supplemental request when demand was detected. This version passed functionality and implementation checks, with 145 cells, 1448.889600 μm² area, and 176.3 MHz timing.

In DP2, the design was optimized for power, performance, and area. We reduced unnecessary control logic, simplified register updates, used clock-enable style behavior where appropriate, separated reusable modules such as the synchronizer and SPI-register interface, and shortened some combinational paths. This reduced the design to 59 cells and 751.9712 μm², which was a major area improvement over DP1. The timing dropped to 92 MHz, but this was still acceptable for a traffic-light demand detector because the system does not require extremely fast response. DP2 showed that a much smaller implementation was possible, but it also showed that minimizing area alone was not enough for the final design.

In DP3, the design shifted toward security hardening. The ESP32 interface became a true SPI packet input, and each packet included a command byte, data byte, sequence number, and authentication tag. TinyQV recomputed the expected tag and accepted the packet only if the tag, command, write permission, sequence number, and lockout state were valid. The design also added sequence-number replay protection, stale WiFi data timeout, brute-force lockout after repeated authentication failures, a sticky security alert, firmware-readable security status, loop-detector glitch filtering, and registered outputs for timing closure. This increased the design to 695 cells and 8155.3216 μm², but timing improved to 177.84 MHz.

In DP4, the team consolidated the final design and selected the security-hardened DP3/DP4 version for submission. Although the DP2 version was smaller, the final version better satisfied the challenge goal because it documented both PPA improvement work and security improvement work. The final design preserves the original traffic-light behavior while adding authentication, replay resistance, stale-data protection, privilege separation, and safer interaction with the inductive-loop fallback.

## Key Decisions
What were the major design decisions and trade-offs?

One major design decision was to keep the ESP32 as a sensor instead of treating it as a trusted controller. The ESP32 can report WiFi count data, but it cannot directly write the main control register or threshold register. Those registers remain controlled by the RISC-V bus. This prevents a faulty, compromised, or replaced ESP32 from disabling the system, lowering the threshold, or overriding the intended behavior of the traffic-light peripheral.

Another important decision was to use lightweight authentication. A full cryptographic method such as HMAC-SHA256 would provide stronger protection, but it would require much more area and logic than was practical for this challenge. The final design uses a keyed CRC8 tag because it is small enough to implement in RTL while still preventing simple unauthenticated packet injection and accidental SPI corruption. This is an intentional security tradeoff: the design is more secure than an unauthenticated SPI input, but it should not be described as cryptographically strong.

The team also decided to include sequence-number checking to reduce replay attacks. If an attacker captures a valid packet and sends it again with the same sequence value, the design rejects it. The limitation is that the sequence number is only 8 bits, so it eventually wraps after 256 accepted packets. A future version should expand this to 16 bits or more.

Another important tradeoff was the WiFi freshness timeout. Without a timeout, an old WiFi count could remain valid forever if the ESP32 stopped transmitting. The final design clears wifi_valid when no valid authenticated packet arrives within the timeout window. To reduce switching power, the timeout counter uses a slower prescaled tick instead of decrementing every clock cycle. This slightly slows the timeout response, but that is acceptable because the WiFi path is supplemental and traffic-light behavior does not require high-speed updates.

The final major decision was area versus security. DP2 produced the smallest implementation, but it did not include the final authentication, replay protection, lockout, security alert, timeout, and debug-status features. The final DP3/DP4 design is larger, but it is more robust and better suited for a system that interacts with traffic-control infrastructure. For the final submission, the team prioritized correctness, observability, and security over minimum area. 

## Verification Strategy
How did you ensure your design was correct?

The design was verified through Verilog simulation, implementation checks, and AI-assisted review. We checked that the RTL compiled correctly, that the testbenches ran successfully, and that the design still met the original traffic-light functionality after each major change. Verification was not limited to normal operation; the team also tested security and fault scenarios.

The main functional test cases included receiving a valid WiFi count through SPI, storing the count internally, comparing the count against the threshold, asserting a request when WiFi demand was present, suppressing the request when the inductive loop was active, and allowing register reads and writes through the RISC-V bus. These tests confirmed that the final design still behaved like the original supplemental traffic-light peripheral.

The security-focused test cases included rejecting packets with invalid authentication tags, rejecting repeated sequence numbers, entering lockout after repeated failures, setting the sticky security alert, generating an interrupt on a security event, clearing normal interrupts through software, and invalidating stale WiFi data when no new authenticated packet arrived. These cases helped confirm that the security features were not just present in the RTL, but active in the expected situations.

We also reviewed the final results against the PPA reports. DP1 proved that the baseline design worked, DP2 demonstrated that the area could be reduced significantly, and DP3 showed that security features could be added while still maintaining strong timing. The final selected design uses the DP3/DP4 security-hardened RTL because it provides the strongest overall balance of required functionality, timing closure, and security improvements. 