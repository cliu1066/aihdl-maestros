# AI-HDL Challenge 3 Submission Form

## Basic Information
- **Submission Date**: [2026-05-06]
- **Challenge Number**: 3
- **Team Name**: Maestros
- **Team ID**: [Assigned during registration]

## Team Members
| Name | Role | Email | Contribution % |
|------|------|-------|----------------|
| Candice Liu | Team Lead | [candiceliu@arizona.edu] | 33.3% |
| Daniel Onesimo Dong | Team Member | [onesimod@arizona.edu] | 33.3% |
| April Morales | Team Member | [aprilmorales@arizona.edu] | 33.3% |

## Design Specifications Met
- [X] All required functionality implemented
- [X] FPGA implementation successful
- [X] Timing requirements met
- [X] Resource constraints satisfied
- [X] All test cases pass

## AI Tool Usage Declaration
- **Primary AI Tool**: ChatGPT-4, Claude, Gemini
- **Total Conversation Sessions**: 20
- **Estimated AI-Generated Code %**: 100%
- **Manual Modifications Made**: Removed redundant comments

## Special Considerations
- **Bonus Features Implemented**:
    1. Incremental CRC8 with pre-computed CRC_INIT: The authentication key never
    travels through live combinatorial logic. CRC_INIT = CRC8(0x00, KEY) is a
    synthesis-time constant, making the key harder to recover through power
    side-channel analysis compared to processing it each packet.

    2. spi_cmd_class_ok_r and spi_write_seen registered at byte 0 boundary:
    These are stable values 24+ clocks before the packet is evaluated,
    preventing any combinatorial glitch on the command byte from influencing
    the accept/reject decision during the tag comparison cycle.

    3. spi_new_byte wire: The incoming byte is assembled in one place and
    referenced once per always-block activation. This eliminates net
    duplication during synthesis, reducing the number of fanout violations
    the tool must resolve.

    4. sec_alert_rise edge detection for IRQ: The IRQ fires once on the lockout
    event rather than staying permanently asserted. Firmware can acknowledge
    the interrupt and continue operating without being stuck in an uncleared
    IRQ loop while sec_alert remains sticky.

    5. LOCKOUT_CYCLES as a module parameter: The lockout window is configurable
    at instantiation. Simulation uses 20 (fast), production uses 0xFFFF (~1 ms
    at 64 MHz). No RTL change is needed between tapeout and testbench.

- **Known Issues**:
    1. 8-bit sequence number wraps at 256 accepted packets. After wrap, the
    oldest observed valid packet becomes replayable. No mitigation in current
    RTL; affects long-running deployments more than short test scenarios.

    2. spi_last_pkt_accepted is a one-cycle pulse. Firmware polling REG_SECURITY
    more than one cycle after a packet boundary will always read 0 for this bit.
    Use spi_last_tag_ok and spi_last_seq_ok instead, which hold their values
    until the next packet arrives.

    3. The lockout DoS surface exists for any attacker with physical SPI access.
    Three bad packets over ~2.6 µs trigger a ~1 ms denial window at production
    LOCKOUT_CYCLES. Continuous triggering creates roughly 4% effective
    throughput for the ESP32. Not exploitable remotely; requires wire access.

    4. REG_SECURITY exposes spi_tag_r (the received tag byte). A bus-reading
    attacker can use this as a tag verification oracle when testing offline key
    guesses against a known packet. Does not directly disclose the key but
    speeds up exhaustive search from 256 guesses to a single-query check.

    5. The CRC8 polynomial 0x07 and key 0x5C are compile-time constants. Any
    party with access to the synthesized netlist or RTL can extract them.
    Security relies on the RTL remaining confidential, not on algorithmic
    secrecy.
- **Future Improvements**:
    Priority High:
    - Replace CRC8 with a 32-bit HMAC-SHA256 tag. The ESP32 has sufficient compute
    for this at the update rate required; TinyQV would need a small SHA-256
    compression function block or a shared secret comparison only.
    - Expand the sequence number to 16 bits to push the wrap boundary to 65536
    accepted packets, eliminating the replay window in practical deployments.

    Priority Medium:
    - Add a hardware eFuse or OTP register that locks CTRL and THRESHOLD writes
    after initial provisioning, removing the residual risk of firmware-level
    tampering.
    - Add a 3-flip-flop synchronizer on rst_n before distribution to guard against
    reset glitch injection attacks.
    - Consider an AES-128 payload encryption layer on the SPI link for deployments
    where the physical channel cannot be trusted.

    Priority Low:
    - Expand the fail log from a 2-bit saturating counter to a 4-entry FIFO in
    REG_SECURITY. This would let firmware reconstruct a short attack history
    rather than only seeing the current fail count and lockout state.
    - Add a dummy switching register on the inverse clock edge during CRC update
    cycles to mask the data-dependent power signature, reducing power
    side-channel leakage.
    - Expose wifi_timeout as a readable field in REG_SECURITY so firmware can
    monitor time-to-expiry without needing to know WIFI_TIMEOUT_MAX at runtime.

## Verification Checklist
- [X] All source files compile without errors
- [X] Testbenches run successfully
- [X] FPGA implementation verified on hardware
- [X] AI interaction logs are complete
- [X] Documentation is thorough and clear

## Team Statement
We certify that this submission represents our original work, completed according to AI-HDL rules and academic integrity guidelines. All AI interactions have been logged and submitted.

**Team Representative**: Maestros
**Date**: [2026-05-06]