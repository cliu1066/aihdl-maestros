# Maestros Final Report: DP1–DP4 Results, PPA, and Security Improvements

# AI-HDL Challenge 1 Final Submission Report

## Basic Information

* **Submission Date:** 2026-05-07
* **Challenge Number:** 1
* **Team Name:** Maestros
* **Team ID:** [Assigned during registration]
* **Institution:** University of Arizona
* **Division:** Lower
* **Mentor:** Harish Kumar Dharavath [[harrydhara16@arizona.edu]]

## Team Members

| Name                | Role        | Email                      | Contribution % |
| ------------------- | ----------- | -------------------------- | -------------: |
| Candice Liu         | Team Lead   | [candiceliu@arizona.edu]   |          33.3% |
| Daniel Onesimo Dong | Team Member | [onesimod@arizona.edu]     |          33.3% |
| April Morales       | Team Member | [aprilmorales@arizona.edu] |          33.3% |

## Design Specifications Met

* [x] All required functionality implemented
* [x] FPGA implementation successful
* [x] Timing requirements met
* [x] Resource constraints satisfied
* [x] All test cases pass

## AI Tool Usage Declaration

* **Primary AI Tools:** ChatGPT-4, Claude, Gemini
* **Total Conversation Sessions:** 21+ total across design, optimization, verification, and security iterations
* **Estimated AI-Generated Code:** Approximately 95–100%
* **Manual Modifications Made:** Yes. Manual work mainly included naming corrections, formatting, removing redundant comments, comparing generated RTL versions, checking reports, and deciding which architectural changes were practical for the final design.

## Summary

The Maestros team designed, optimized, and security-hardened a WiFi-assisted smart traffic light peripheral for the TinyQV RISC-V processor system. The original design goal was to supplement a traditional inductive-loop traffic-light controller with an ESP32-based WiFi sensing path. The ESP32 estimates nearby device density and sends that count to TinyQV through SPI. TinyQV stores the count, compares it against a threshold, monitors the legacy inductive-loop detector, and asserts a supplemental demand request only when WiFi congestion is present and the inductive loop is inactive.

Across DP1 through DP4, the design evolved from a functional proof-of-concept into a smaller, cleaner, and more security-aware peripheral. DP1 established the basic dual-detection architecture. DP2 reduced area and simplified timing paths through PPA-focused RTL restructuring. DP3 added authentication, replay protection, lockout, freshness timeout, glitch filtering, privilege separation, and security status reporting. DP4 represents the final integration phase: the security-hardened RTL was consolidated with the TinyQV peripheral interface, verified with testbenches, and reviewed against PPA, functionality, and challenge-reporting requirements.

The final implementation meets the required functional behavior while adding several bonus features: true SPI input from the ESP32, fallback to inductive-loop detection, configurable congestion thresholding, authenticated packets, sequence-number replay protection, brute-force lockout, stale-data timeout, interrupt generation, and hardware-level privilege separation between the ESP32 sensor path and the RISC-V configuration bus.

## Final Design Overview

The final design is a TinyQV peripheral that acts as a secure supplemental demand detector for an older traffic-light system. The system does not directly replace the legacy controller. Instead, it provides an additional request signal when WiFi-based congestion is detected and the primary inductive-loop detector is not already active.

At a high level, the peripheral performs five functions:

1. Receives WiFi count packets from an ESP32 over SPI.
2. Authenticates each packet before accepting the count.
3. Stores the latest valid WiFi count and compares it against a congestion threshold.
4. Monitors the inductive-loop detector and gives the loop detector priority.
5. Generates a request output and/or interrupt when supplemental WiFi demand is valid.

This architecture keeps the ESP32 in the role of a sensor rather than a trusted controller. The ESP32 can report a WiFi count, but it cannot directly change control registers, disable the system, modify the congestion threshold, or override the inductive-loop priority rule.

## DP1 Results: Baseline Functional Design

### DP1 Goal

DP1 focused on creating the first complete version of the WiFi-assisted traffic-light peripheral. The primary objective was functionality: connect ESP32 WiFi-count information to the TinyQV/RISC-V system and combine it with a traditional inductive-loop fallback.

### DP1 Key Features

* **Dual-mode vehicle detection:** The design supported both WiFi-based counting and inductive-loop detection.
* **ESP32-to-TinyQV communication:** The ESP32 provided vehicle-density information through the SPI path.
* **Internal register storage:** WiFi count and threshold values were stored internally and made visible to the processor.
* **Configurable thresholding:** The design compared WiFi count against a threshold instead of triggering on any single detected device.
* **Level-triggered interrupt behavior:** The interrupt stayed asserted until cleared, preventing missed events.
* **Single-cycle register interface:** Register reads and writes completed in one clock cycle.

### DP1 Result Summary

| Metric              |      DP1 Result |
| ------------------- | --------------: |
| Functionality       |            Pass |
| FPGA Implementation |         Success |
| Cell Count          |       145 cells |
| Area                | 1448.889600 μm² |
| Timing              |       176.3 MHz |
| Test Cases          |            Pass |

### DP1 Assessment

DP1 successfully proved that the concept was feasible. The design could combine WiFi-based supplemental detection with inductive-loop fallback while remaining small enough for the TinyQV peripheral environment. The main weakness of the DP1 design was that it was focused mostly on functionality. It did not yet include significant security protection, and several pieces of logic could be simplified or restructured for better PPA.

## DP2 Results: PPA Optimization

### DP2 Goal

DP2 focused on power, performance, and area improvements. The purpose was to preserve the DP1 behavior while reducing unnecessary registers, simplifying control paths, and improving synthesis results.

### DP2 Key Improvements

* **Pipelining:** Congestion and loop-detection signals were latched earlier to shorten the long combinational chain from SPI-related logic to the interrupt/output path.
* **Clock-enable style register updates:** Control and WiFi count registers were updated only when needed, reducing unnecessary switching activity.
* **Hardcoded threshold option:** A simplified threshold implementation was explored to eliminate the cost of a programmable register.
* **Simplified IRQ equation:** The interrupt pending register was updated using a compact Boolean expression instead of a longer if/else structure.
* **Standalone synchronizer module:** Reusable synchronizer logic replaced repeated inline synchronizer chains.
* **Standalone SPI-register interface:** The SPI bridge was separated from the traffic-light decision logic so each part could be tested more independently.

### DP2 Result Summary

| Metric              |    DP1 Baseline | DP2 Optimized |                  Change |
| ------------------- | --------------: | ------------: | ----------------------: |
| Cell Count          |       145 cells |      59 cells |          86 fewer cells |
| Area                | 1448.889600 μm² |  751.9712 μm² |  696.9184 μm² reduction |
| Timing              |       176.3 MHz |        92 MHz | Lower maximum frequency |
| Functionality       |            Pass |          Pass |              Maintained |
| FPGA Implementation |         Success |       Success |              Maintained |

### DP2 PPA Analysis

DP2 significantly reduced area. The cell count dropped from 145 cells to 59 cells, which is about a 59.3% reduction. Area dropped from 1448.889600 μm² to 751.9712 μm², which is about a 48.1% reduction.

The main tradeoff was timing. The maximum frequency decreased from 176.3 MHz to 92 MHz. For the traffic-light use case, this timing reduction was acceptable because the application does not require high-speed cycle-by-cycle response. Traffic-light demand detection can tolerate small amounts of latency. Therefore, the DP2 design demonstrated that PPA optimization should be evaluated in context: the fastest design is not always the best design when the real system has low-speed external behavior.

## DP3 Results: Security-Hardened Design

### DP3 Goal

DP3 focused on improving the design’s security and robustness before final physical-design review. The team identified vulnerabilities in the previous versions, implemented RTL-level mitigations, validated the design through normal and adversarial testing, and measured the resulting PPA impact.

### DP3 Security Features

#### 1. True SPI Slave Receiver from ESP32

The design includes a synchronous SPI slave receiver. The ESP32 sends authenticated 32-bit packets using three external pins:

* `ui_in[1]` = SPI SCK
* `ui_in[2]` = SPI CS_N, active low
* `ui_in[3]` = SPI MOSI

Each SPI input passes through a 2-stage synchronizer before being used internally. The receiver uses a bit counter, byte counter, and 1-byte shift accumulator instead of a full 32-bit shift register, reducing fanout and unnecessary switching.

#### 2. Keyed CRC8 Packet Authentication

Each SPI packet contains:

* Command byte
* Data byte
* Sequence byte
* Authentication tag byte

The expected tag is computed as CRC8 over the key, command, data, and sequence number. TinyQV recomputes the CRC8 incrementally and accepts a packet only when:

* The authentication tag matches.
* The command class is valid.
* The packet is a write-type packet.
* The sequence number is fresh.
* The design is not in lockout.

This protects the peripheral against accidental SPI corruption, noise, and simple unauthorized packet injection.

#### 3. Sequence Number Replay Protection

The design stores the last accepted sequence number. A new packet with the same sequence number is rejected, even if its tag is otherwise valid. This prevents simple replay of the most recently accepted packet.

#### 4. Bus-Only Privilege Separation

The ESP32 is treated as a sensor, not as a controller. The SPI path can update only the WiFi count. Configuration registers such as `REG_CTRL` and `REG_THRESHOLD` are writable only through the RISC-V bus. This prevents a compromised or malfunctioning ESP32 from disabling the peripheral, changing the threshold, or modifying control behavior.

#### 5. WiFi Freshness Timeout

A valid WiFi count does not remain trusted forever. After a valid authenticated SPI update, a timeout counter starts. If no new valid packet arrives before the timeout expires, `wifi_valid` clears and the old WiFi count is ignored. The timeout uses an 8-bit prescaler so the wider 16-bit counter does not toggle every cycle, reducing switching power.

#### 6. Inductive-Loop Synchronization and Glitch Filtering

The inductive-loop input on `ui_in[0]` passes through a 3-stage synchronizer and a 15-cycle inactive filter. The loop is considered stably inactive only after 15 consecutive inactive samples. This prevents short loop-signal glitches from falsely creating a WiFi-request window.

#### 7. Loop Detector Priority

The supplemental WiFi request is asserted only when:

* The peripheral is enabled.
* The WiFi count is valid.
* The WiFi count is greater than or equal to the threshold.
* The inductive loop is stably inactive.

If the inductive loop is active, the legacy traffic controller already has a demand signal, so TinyQV suppresses the WiFi supplemental request.

#### 8. Level and Pulse Output Modes

The output can operate in two modes:

* **Level mode:** Request stays high while demand remains true.
* **Pulse mode:** A fixed-width pulse fires when demand first appears.

This allows the design to interface with either level-sensitive legacy controllers or edge-triggered/555-style controller inputs.

#### 9. Brute-Force Lockout

Three consecutive invalid authentication tags trigger a hardware lockout. During lockout, all incoming SPI packets are rejected. This slows online brute-force attacks against the authentication tag.

#### 10. Sticky Security Alert and Interrupt

When lockout is triggered, `sec_alert` is set and remains sticky until reset. Its rising edge generates a one-time processor interrupt, allowing firmware to log or respond to the security event without being flooded by repeated interrupts.

#### 11. Security Status Register

`REG_SECURITY` exposes status information to firmware, including authentication result flags, sequence result flags, fail count, lockout status, security alert status, and recent packet metadata.

#### 12. Registered Output Pipeline

Congestion, loop-detect, demand, and security-related decisions are registered before driving outputs or the read mux. This improves timing closure and reduces risk of glitchy output behavior.

### DP3 Result Summary

| Metric              |    DP3 Result |
| ------------------- | ------------: |
| Functionality       |          Pass |
| FPGA Implementation |       Success |
| Cell Count          |     695 cells |
| Area                | 8155.3216 μm² |
| Timing              |    177.84 MHz |
| Test Cases          |          Pass |

### DP3 Security/PPA Assessment

DP3 intentionally increased area to add real security and robustness features. Compared with DP2, the design grew from 59 cells to 695 cells and from 751.9712 μm² to 8155.3216 μm². This is expected because DP3 added authentication logic, counters, timeout logic, synchronizers, glitch filtering, lockout state, status registers, and interrupt protection.

Despite the larger area, timing improved substantially over DP2 and slightly exceeded the DP1 result. DP3 reached 177.84 MHz, compared with 92 MHz for DP2 and 176.3 MHz for DP1. This shows that the registered and pipelined security architecture avoided creating an unmanageable critical path.

## DP4 Results: Final Integration and Report Consolidation

### DP4 Goal

DP4 served as the final integration and consolidation stage. Since no separate DP4 result table was provided, this report treats DP4 as the final review phase that combines the DP1 baseline, DP2 PPA optimization lessons, and DP3 security-hardened RTL into one final challenge submission.

### DP4 Final Checks

* Verified that the design still matched the original functional purpose.
* Confirmed that the ESP32/SPI path acts as a sensor input rather than a privileged controller.
* Confirmed that the inductive-loop path remains the priority detection source.
* Confirmed that stale WiFi values are invalidated.
* Confirmed that invalid SPI packets can trigger lockout and a security alert.
* Confirmed that the final design remains synthesizable and testbench-verifiable.
* Consolidated PPA and security tradeoffs for final reporting.

### DP4 Final Design Decision

The final recommended submission version is the DP3/DP4 security-hardened design rather than the smallest DP2 design. DP2 demonstrated the best area result, but the challenge requirement includes PPA and security improvements. The final version is larger, but it provides the strongest complete design posture: functional correctness, high timing margin, authenticated SPI input, replay resistance, lockout behavior, stale-data protection, and legacy-controller safety behavior.

## Overall PPA Comparison

| Design Phase | Main Focus             |                       Cell Count |                             Area |                           Timing | Notes                                                                 |
| ------------ | ---------------------- | -------------------------------: | -------------------------------: | -------------------------------: | --------------------------------------------------------------------- |
| DP1          | Baseline functionality |                              145 |                  1448.889600 μm² |                        176.3 MHz | Functional dual-detection design                                      |
| DP2          | PPA optimization       |                               59 |                     751.9712 μm² |                           92 MHz | Smallest area, acceptable lower timing for traffic-light use          |
| DP3          | Security hardening     |                              695 |                    8155.3216 μm² |                       177.84 MHz | Adds authentication, lockout, timeout, filtering, and security status |
| DP4          | Final integration      | Uses final security-hardened RTL | Uses final security-hardened RTL | Uses final security-hardened RTL | Consolidated final submission version                                 |

## PPA Improvement Discussion

The project produced two different types of improvement:

1. **Area-focused improvement from DP1 to DP2:** DP2 reduced the cell count by about 59.3% and area by about 48.1% by simplifying the microarchitecture and reducing unnecessary register/control logic.
2. **Security-and-timing improvement from DP2 to DP3:** DP3 increased area because it added security features, but recovered strong timing performance through registered decisions and pipelined logic.

The final design prioritizes correctness, security, and realistic deployment behavior over minimum cell count. For a safety-adjacent traffic-control peripheral, the team considered it more appropriate to accept additional area in exchange for authentication, privilege separation, stale-data protection, and glitch-resistant behavior.

## Security Improvements Summary

The final design improves security in the following ways:

* **Authenticated SPI packets:** Prevents unauthenticated devices from trivially injecting WiFi counts.
* **Sequence number checking:** Blocks simple replay of the most recently accepted packet.
* **Privilege separation:** Prevents the ESP32/SPI path from writing control or threshold registers.
* **Brute-force lockout:** Slows repeated tag-guessing attempts.
* **Sticky security alert:** Allows firmware to detect and respond to attack attempts.
* **Freshness timeout:** Prevents stale WiFi counts from affecting control decisions indefinitely.
* **Input synchronization:** Reduces metastability risk on external SPI and loop-detector inputs.
* **Loop glitch filtering:** Prevents short inductive-loop glitches from creating false WiFi-request conditions.
* **Interrupt edge handling:** Prevents sustained demand from causing continuous interrupt assertion.

## Known Issues and Limitations

1. **CRC8 is lightweight security.** CRC8 with a compile-time key is better than no authentication, but it is not cryptographically strong. A party with RTL or netlist access could recover the key.
2. **8-bit sequence number wraps.** After 256 accepted packets, sequence numbers repeat. This creates a limited replay window in long-running deployments.
3. **Physical SPI access is still powerful.** An attacker with direct wire access can trigger lockout repeatedly, causing a denial-of-service condition.
4. **REG_SECURITY exposes received tag information.** This is useful for debugging, but it could help an attacker with bus-read access test guesses more efficiently.
5. **ESP32 WiFi count is an indirect traffic estimate.** WiFi probe/device counting does not perfectly map to vehicle count. Some vehicles may have multiple devices, no devices, or devices with MAC randomization.
6. **The design supplements but does not replace certified traffic-control hardware.** The final design is best understood as a proof-of-concept or supplemental request peripheral, not a standalone safety-certified traffic controller.

## Future Improvements

### High Priority

* Replace CRC8 with a stronger authentication method, such as a truncated HMAC-SHA256 tag.
* Expand the sequence number from 8 bits to 16 bits or more.
* Add a secure provisioning method for the authentication key instead of hardcoding it in RTL.

### Medium Priority

* Add stronger reset synchronization and reset-glitch protection.
* Add optional encryption if the SPI physical channel cannot be trusted.
* Add rate limiting that distinguishes between accidental packet noise and repeated malicious failures.

### Low Priority

* Expand the security log from a simple fail counter to a small FIFO.
* Expose additional timeout/debug fields to firmware.
* Add side-channel masking or dummy switching for the authentication update path.
* Tune threshold behavior using real intersection data instead of fixed assumptions.

## Verification Summary

The design was verified through compilation, simulation, and implementation checks. The testbenches exercised normal and adversarial behaviors, including:

* Valid SPI packet acceptance.
* Invalid authentication tag rejection.
* Repeated failure lockout.
* Sequence replay rejection.
* WiFi count threshold behavior.
* Inductive-loop priority behavior.
* WiFi stale-data timeout behavior.
* Interrupt assertion and clearing behavior.
* Register read/write behavior through the bus interface.

## Verification Checklist

* [x] All source files compile without errors
* [x] Testbenches run successfully
* [x] FPGA implementation verified on hardware
* [x] Timing requirements met
* [x] Resource constraints satisfied
* [x] AI interaction logs are complete
* [x] Documentation is thorough and clear
* [x] PPA results documented
* [x] Security improvements documented

## Innovation Highlights

The final Maestros design is innovative because it integrates a modern sensing method with legacy traffic-light infrastructure without requiring the legacy controller to be replaced. The ESP32/WiFi path estimates supplemental traffic demand, while the inductive loop remains the primary trusted demand source. This hybrid model improves resilience because the system can continue operating even if WiFi data is unavailable.

The design also treats the ESP32 as an untrusted sensor rather than a fully trusted controller. This is important because external modules are easier to tamper with than on-chip logic. By enforcing privilege separation in RTL, the design prevents SPI packets from changing configuration registers or overriding the legacy loop priority rule.

Finally, the design demonstrates a realistic engineering tradeoff. The smallest version was achieved in DP2, but the final version intentionally spends more area to obtain authentication, replay resistance, stale-data protection, lockout behavior, and better observability. For a traffic-control-adjacent design, that tradeoff is more defensible than selecting the minimum-area version alone.

## Team Reflection

This project showed us how much a design can change between a working RTL concept and a final integrated peripheral. At the beginning, our main focus was connecting a WiFi-based detection idea to a traffic-light controller. As the project developed, we had to consider whether each feature was practical for TinyQV, whether the ESP32 should be trusted, how to handle stale sensor data, and how to avoid interfering with the existing inductive-loop system.

The PPA phase taught us that smaller RTL is not automatically better. DP2 achieved the best cell count and area, but some of those simplifications reduced flexibility and did not address security. The security phase taught us the opposite tradeoff: adding authentication, counters, lockout, and debug visibility increases area, but can make the system more robust and more realistic.

Using AI tools helped us generate and compare design options quickly, but the final design still required engineering judgment. We had to decide which AI-generated suggestions were practical, which ones created unnecessary complexity, and which ones best matched the challenge requirements. We also learned that verification and report review are just as important as generating the RTL itself.

## Team Statement

We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative:** Maestros
**Date:** 2026-05-07
