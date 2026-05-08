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
  DP3 focuses on improving the design’s security and robustness before physical design. The challenge asks us to identify vulnerabilities, plan and implement RTL-level mitigations, validate them through normal and adversarial testing, measure any power/area/timing impact, and document the final security posture. By the milestone review, the design should have verified security features, clean regression results, a completed DP3 report, and stable RTL ready for the next design phase.

## Key Features
- Feature 1: True SPI slave receiver from ESP32
  The design includes a fully synchronous SPI slave receiver. The ESP32 sends authenticated 32-bit packets to TinyQV over three external pins:
    - ui_in[1] = SPI SCK
    - ui_in[2] = SPI CS_N (active low)
    - ui_in[3] = SPI MOSI
  Each pin passes through a 2-stage synchronizer before being used internally, eliminating metastability risk. The receiver tracks bit position (3-bit counter), byte index (2-bit counter), and a 1-byte shift accumulator instead of a 32-bit shift register, minimizing fanout on internal nets.

- Feature 2: Per-packet CRC8 keyed authentication
  Every SPI packet carries a 4-byte structure: command, data, sequence number, and an authentication tag. The tag is CRC8(KEY, cmd, data, seq) computed by the ESP32. TinyQV recomputes the expected tag incrementally — one byte per clock at each byte boundary — and compares the received tag against the expected value in a single registered comparison. A packet is accepted only if the tag matches, the command class is valid, the write flag is set, and the sequence number is fresh. This protects against accidental SPI noise,
  bus crosstalk, and deliberate injection by unauthorized devices.

- Feature 3: Sequence number replay protection The sequence byte in each SPI packet is compared against the last accepted sequence number. If the incoming sequence equals the stored value, the packet is rejected regardless of tag validity. This prevents an attacker who captured a valid packet from replaying it to re-inject an old WiFi count.

- Feature 4: Bus-only privilege separation for CTRL and THRESHOLD
  REG_CTRL and REG_THRESHOLD can only be written by the RISC-V bus. The SPI write enables for these registers are hardwired to 1'b0 in RTL — there is  no code path, however the SPI packet is constructed, that allows the ESP32 to enable or disable the peripheral or change the congestion threshold. This enforces the principle of least privilege: the ESP32 is a sensor and is given write authority over REG_WIFI_COUNT only.

- Feature 5: WiFi data freshness timeout with low-power prescaler
  After a valid SPI update, a 16-bit countdown timer starts. If no new valid authenticated packet arrives before the timer expires, wifi_valid clears and the stale count is ignored. The timer is not decremented every clock cycle; instead an 8-bit prescaler generates a slower tick, so the wide 16-bit counter switches much less frequently. This reduces switching power in the timeout path while preserving the security property that old WiFi readings do not persist indefinitely.

- Feature 6: Internal register storage with bus read access
  wifi_count_reg, threshold_reg, and ctrl_reg are stored in flip-flops and readable by the RISC-V bus at any time. The bus can also write wifi_count_reg and threshold_reg directly, which is useful for simulation, testing, and manual override without an ESP32 connected.

- Feature 7: Programmable threshold with hardware clamping
  The congestion threshold is configurable from 1 to 15 via the RISC-V bus. Writing a value of 0 is clamped to 1 in hardware, preventing the degenerate case where any non-zero WiFi count would always assert congestion. The maximum of 15 is enforced by the 4-bit register width.

- Feature 8: Inductive loop monitoring with 3-stage synchronizer and glitch filter
  The raw loop detector input on ui_in[0] passes through three flip-flops for metastability hardening, then through a 15-cycle inactive filter. The loop is only considered stably inactive after 15 consecutive clock cycles of inactivity. Short glitches — such as a brief signal bounce when a vehicle partially exits the loop — do not create a spurious window where a WiFi supplemental request could fire.

- Feature 9: Loop detector has priority over WiFi request
  The supplemental WiFi request is only asserted when all three conditions hold simultaneously: the peripheral is enabled, the WiFi count meets or exceeds threshold, and the loop detector is stably inactive. An active loop means the legacy inductive loop controller already has demand; TinyQV suppresses its own request to avoid sending redundant or conflicting demand signals to the traffic controller.

- Feature 10: Level mode and pulse mode output
  The request output behavior is selected by ctrl_reg[1]:
    - ctrl_reg[1] = 0: level mode — request stays high while demand is present, suitable for legacy controllers that expect a held demand line.
    - ctrl_reg[1] = 1: pulse mode — a fixed-width one-shot pulse fires when demand first appears, suitable for 555-timer or edge-triggered inputs.
  Pulse width is 8 clock cycles (parameter PULSE_WIDTH).

- Feature 11: Brute-force lockout on SPI authentication failures
  Three consecutive SPI packets with invalid authentication tags trigger a hardware lockout. During the lockout window (LOCKOUT_CYCLES clocks; default 64, production value 0xFFFF), all incoming SPI packets are rejected regardless of tag validity. This prevents an attacker from testing tag candidates at wire speed over the live SPI bus. After the lockout window expires, normal authentication resumes and the fail counter resets.

- Feature 12: Sticky security alert with interrupt notification
  When a lockout is triggered, the sec_alert flag is set and held sticky until hardware reset (rst_n). It cannot be cleared by software. The rising edge of sec_alert generates a one-time processor interrupt, allowing firmware to log the event, alert the operator, or take defensive action. Subsequent packet failures within the same session do not re-fire the interrupt, preventing interrupt flooding.

- Feature 13: Security status visibility via REG_SECURITY
  REG_SECURITY provides firmware read access to: the last received tag byte, the last accepted sequence number, per-packet status flags (tag_ok, seq_ok, cmd_ok, pkt_accepted), the 2-bit fail counter, lockout_active, and sec_alert. This gives RISC-V firmware the information needed to detect, diagnose, and respon to authentication failures without external debug tooling.

- Feature 14: Edge-triggered clearable interrupt
  The processor interrupt fires on the rising edge of WiFi demand (wifi_demand_r going from 0 to 1) or on the rising edge of sec_alert. It latches and can be cleared by software writing ctrl_reg[2] even while the demand condition remains active. A new rising edge of demand will reassert the interrupt. This prevents the interrupt from continuously firing for a sustained high-WiFi  condition and allows the firmware to acknowledge and move on.

- Feature 15: Registered output pipeline for timing closure
  Congestion, loop detect, and WiFi demand outputs are registered one cycle before driving uo_out and the read mux. This breaks the combinatorial path from the SPI shift logic to the output pins, eliminating the slew and max-capacitance violations present in earlier iterations. Security correctness is preserved because the comparison and lockout decisions are also fully registered before being used.

## AI Tools Used
- Primary LLM: ChatGPT-4, Claude, Gemini
- Additional tools: N/A
- Total AI interactions: 21

## Results Summary
- **Functionality**: Pass
- **FPGA Implementation**: Success
- **Resource Usage**: 695 cells, Area = 8155.3216 μm^2
- **Timing**: 177.84 MHz

## Innovation Highlights
The final TinyQV peripheral implements a security-hardened supplemental demand detector designed to coexist with an existing inductive-loop traffic-light controller. An ESP32 estimates nearby vehicle density through WiFi probe request counting and delivers this data to TinyQV over a hardware SPI link. Every packet carries a CRC8 authentication tag computed over the key, command, data, and a sequence number, allowing TinyQV to verify both authenticity and freshness in hardware with no software involvement. The CRC is computed incrementally — one byte per clock cycle — keeping the combinatorial depth at 8 gate levels per boundary and meeting  sky130A timing closure requirements.

Privilege is separated at the silicon level: the SPI channel can only update the WiFi count, while peripheral configuration and threshold are exclusively writable by the RISC-V bus. Three consecutive authentication failures trigger a hardware lockout with a sticky security alert and a one-shot processor interrupt, giving firmware both protection against online brute-force attacks and a direct notification channel for incident response.

The inductive loop input passes through a 3-stage synchronizer and a 15-cycle glitch filter before gating the supplemental request, ensuring the legacy controller's primary detection path always takes precedence. A prescaled freshness timeout automatically invalidates stale WiFi readings if the ESP32 stops transmitting, preventing historical counts from influencing traffic control indefinitely. A dual output mode supports both held-level and edge-triggered legacy controller inputs. The result is a low-area, synthesis-clean peripheral that adds a security-aware secondary detection layer to infrastructure that was never designed for it.

## Team Reflection
Working through many iterations of the design taught us that security add-ons are chosen tradeoffs in area and timing closure. Adding more security and authentication features directly impacted critical path depth and fanout accounted for in synthesis. Our initial designs seemed straightforward, but they produced many slew and max capacitance violations that made us rethink our design. Reconciling different AI-generated versions of security features in code made us communicate with one another and consider the benefts and drawbacks of the different ideas.