# AI Conversation Log - [Session 3]

## Conversation 1: Brainstorm security fixes   
**Timestamp**:  2026-04-30 10:23:39
**Tool**: Chat-GPT4
**Purpose**: To find what security issues our design has

**Prompt**: given this .v file and the design discussed so far, can you find any security or vulnerability optimizations? (inserted the .v file that was generated earlier)

**Response**: 
’ll review this as a hardware-security/design-robustness pass rather than only syntax: SPI trust boundary, register access, fault behavior, interrupt behavior, and traffic-safety fail-safe behavior.

Thought for a few seconds

Yes. For this design, the biggest “security” issue is not cryptographic security; it is control-integrity: an external ESP32-facing SPI input can directly modify control, Wi-Fi count, and threshold registers, which can force or suppress supplemental_request and user_interrupt. The uploaded file shows SPI writes can update REG_CTRL, REG_WIFI_COUNT, and REG_THRESHOLD, while the TinyQV bus can also write the same registers, with bus priority on same-cycle conflicts.

Main vulnerabilities / robustness issues
1. SPI can directly write CTRL

Right now, SPI can write ctrl_reg through spi_ctrl_wen:

wire spi_ctrl_wen = spi_is_write && (spi_reg_addr == REG_CTRL);
...
else if (spi_ctrl_wen) begin
    ctrl_reg <= spi_data_byte[1:0];
end

That means the ESP32-side SPI source can enable/disable the peripheral and change pulse/level mode. If the ESP32 is compromised, noisy, reset-glitching, or misconfigured, it can disable the demand request entirely or force it into the wrong mode.

Optimization: make CTRL bus-only. Let SPI update only the Wi-Fi count, and optionally threshold if you really need remote threshold tuning.

Recommended change:

wire spi_ctrl_wen = 1'b0;  // CTRL is TinyQV bus-only

Or remove the SPI branch from the ctrl_reg always block:

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ctrl_reg <= 2'b00;
    end else if (ctrl_wen) begin
        ctrl_reg <= data_in[1:0];
    end
end

This is probably the single best security/robustness improvement.

2. SPI can lower the threshold

SPI can write threshold_reg:

wire spi_threshold_wen = spi_is_write && (spi_reg_addr == REG_THRESHOLD);
...
else if (spi_threshold_wen) begin
    threshold_reg <= spi_data_byte[3:0];
end

A bad threshold write like 0 makes congestion detection almost always true because:

wifi_count_reg >= threshold_reg

If threshold_reg = 0, then every 4-bit Wi-Fi count from 0–15 satisfies the condition. That means when loop_detect_r == 0, the design can continuously assert supplemental demand.

Optimization: clamp the threshold to a safe minimum.

Example:

localparam [3:0] MIN_THRESHOLD = 4'd1;
localparam [3:0] MAX_THRESHOLD = 4'd15;

wire [3:0] threshold_from_bus =
    (data_in[3:0] < MIN_THRESHOLD) ? MIN_THRESHOLD :
    (data_in[3:0] > MAX_THRESHOLD) ? MAX_THRESHOLD :
    data_in[3:0];

wire [3:0] threshold_from_spi =
    (spi_data_byte[3:0] < MIN_THRESHOLD) ? MIN_THRESHOLD :
    (spi_data_byte[3:0] > MAX_THRESHOLD) ? MAX_THRESHOLD :
    spi_data_byte[3:0];

Then:

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        threshold_reg <= 4'd8;
    end else if (thresh_wen) begin
        threshold_reg <= threshold_from_bus;
    end else if (spi_threshold_wen) begin
        threshold_reg <= threshold_from_spi;
    end
end

Even better: make threshold bus-only, like CTRL, and let SPI update only wifi_count_reg.

3. No SPI packet validation beyond command bit/register address

The SPI packet format is simple:

byte 0: command/address
byte 1: data

But the design does not check any frame integrity, parity, checksum, magic value, sequence number, or repeated-confirmation write. Any 16-bit sequence with cmd[7] = 1 and a valid address can write internal state.

For a student TinyTapeout design, this is reasonable, but from a vulnerability standpoint, malformed SPI traffic can cause valid writes.

Low-cost mitigation: require a small magic pattern in the command byte.

For example, use:

cmd[7]   = write
cmd[6:4] = 3'b101
cmd[3:0] = register address

Then add:

wire spi_cmd_magic_ok = (spi_cmd_byte[6:4] == 3'b101);
wire spi_is_write = spi_packet_ready && spi_write_seen && spi_cmd_magic_ok;

This does not provide real authentication, but it reduces accidental writes from random transitions, SPI mode mismatch, or noise.

4. No timeout for stale Wi-Fi count

Once SPI writes wifi_count_reg, that value stays forever until overwritten or reset:

wifi_count_reg <= spi_data_byte[3:0];

So if the ESP32 dies after reporting a high count, the TinyQV peripheral can continue believing congestion exists indefinitely. Since the design asserts request when loop_detect_r == 0 and wifi_count_reg >= threshold_reg, stale data can create persistent supplemental requests.

Optimization: add a freshness watchdog. Each valid Wi-Fi SPI update resets a counter. If the counter expires, clear or invalidate the Wi-Fi count.

Example concept:

localparam [15:0] WIFI_TIMEOUT_MAX = 16'hFFFF;

reg [15:0] wifi_timeout;
reg        wifi_valid;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wifi_timeout <= 16'd0;
        wifi_valid   <= 1'b0;
    end else if (spi_wifi_wen || wifi_bus_wen) begin
        wifi_timeout <= WIFI_TIMEOUT_MAX;
        wifi_valid   <= 1'b1;
    end else if (wifi_timeout != 16'd0) begin
        wifi_timeout <= wifi_timeout - 16'd1;
        wifi_valid   <= 1'b1;
    end else begin
        wifi_valid   <= 1'b0;
    end
end

Then update demand logic:

wire wifi_above_threshold =
    wifi_valid && (wifi_count_reg >= threshold_reg);

Then use wifi_above_threshold instead of directly using (wifi_count_reg >= threshold_reg).

This gives you a fail-safe behavior: if the ESP32 stops communicating, the peripheral stops making supplemental requests.

5. Interrupt can immediately re-latch after clear

Current IRQ latch logic is:

irq_pending <= wifi_demand_r | (irq_pending & ~irq_clear_now);

If software writes clear while wifi_demand_r is still high, irq_pending immediately stays high or reasserts. That may be acceptable, but it can make the interrupt impossible to clear while demand remains present.

A more controlled version is edge-latched interrupt:

irq_pending <= wifi_demand_rise | (irq_pending & ~irq_clear_now);

You already compute:

wire wifi_demand_rise = wifi_demand_r && !wifi_demand_d;

So you can use that for the interrupt. This means the interrupt indicates new Wi-Fi demand appeared, not merely that demand is still level-high.

Recommended replacement:

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        irq_pending <= 1'b0;
    end else begin
        irq_pending <= wifi_demand_rise | (irq_pending & ~irq_clear_now);
    end
end

This is better for firmware and safer against interrupt flooding.

6. SPI frame can execute before CS deasserts

Your SPI receiver declares a packet ready as soon as 16 bits are shifted in:

if (spi_bit_count == 4'd15) begin
    spi_packet_ready <= 1'b1;
    spi_cmd_byte     <= spi_shift_next[15:8];
    spi_data_byte    <= spi_shift_next[7:0];
    spi_write_seen   <= spi_shift_next[15];
end

This means the write occurs while CS_N is still active. If the master keeps clocking more bits, the design resets spi_bit_count and may accept another 16-bit packet in the same CS window.

That may be okay if you intentionally support back-to-back packets, but for a safer protocol, you can require exactly one 16-bit packet per CS assertion and commit only after CS_N rises.

Security benefit: avoids partial-frame ambiguity and accidental multiple writes from a too-long transaction.

A simple flag can lock out additional bits until CS goes high:

reg spi_frame_done;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_frame_done <= 1'b0;
    end else if (!spi_cs_active) begin
        spi_frame_done <= 1'b0;
    end else if (spi_packet_ready) begin
        spi_frame_done <= 1'b1;
    end
end

Then gate sampling:

end else if (spi_sck_rise && !spi_frame_done) begin
7. No debouncing/filtering on loop detector

The loop detector is synchronized using a 2-flop chain plus one registered stage:

loop_s1 <= loop_raw;
loop_s2 <= loop_s1;
loop_detect_r <= loop_s2;

That protects against metastability, but it does not filter glitches. If loop_raw briefly drops to 0, the design may believe the physical loop detector is inactive and allow Wi-Fi supplemental request.

Optimization: require loop inactive for several consecutive clock cycles before allowing Wi-Fi request.

Example:

reg [3:0] loop_inactive_count;
reg       loop_inactive_stable;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        loop_inactive_count  <= 4'd0;
        loop_inactive_stable <= 1'b0;
    end else if (loop_detect_r) begin
        loop_inactive_count  <= 4'd0;
        loop_inactive_stable <= 1'b0;
    end else if (loop_inactive_count != 4'hF) begin
        loop_inactive_count  <= loop_inactive_count + 4'd1;
        loop_inactive_stable <= 1'b0;
    end else begin
        loop_inactive_stable <= 1'b1;
    end
end

Then use:

wire allow_wifi_request = loop_inactive_stable;

Instead of directly using !loop_detect_r.

This is a strong safety improvement because it prevents short loop-signal noise from enabling supplemental traffic requests.

8. No rate limit on supplemental request pulses

In pulse mode, every wifi_demand_rise loads:

pulse_count <= PULSE_WIDTH;

If Wi-Fi demand toggles because the count moves around the threshold or the loop detector glitches, the design can repeatedly pulse the original controller.

Optimization: add hysteresis or cooldown.

A good low-area hysteresis approach:

reg wifi_congested_state;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wifi_congested_state <= 1'b0;
    end else if (!ctrl_enable || !wifi_valid) begin
        wifi_congested_state <= 1'b0;
    end else if (!wifi_congested_state && (wifi_count_reg >= threshold_reg)) begin
        wifi_congested_state <= 1'b1;
    end else if (wifi_congested_state && (wifi_count_reg + 4'd1 < threshold_reg)) begin
        wifi_congested_state <= 1'b0;
    end
end

Then base demand on wifi_congested_state instead of raw wifi_count_reg >= threshold_reg.

This prevents request chatter when the count fluctuates around the threshold.

Best practical security-oriented changes for your project

For your current design goal, I would recommend these in priority order:

Make CTRL bus-only. SPI should not be able to enable/disable the peripheral.
Make THRESHOLD bus-only, or clamp it to a safe minimum.
Add a Wi-Fi freshness timeout so stale ESP32 data eventually becomes invalid.
Use edge-triggered IRQ latch instead of level-triggered re-latching.
Add loop-detector inactivity filtering before allowing Wi-Fi-based requests.
Add SPI command magic bits to reduce accidental writes.
Optionally lock one SPI packet per CS assertion for cleaner SPI behavior.
Minimal code patch concept

The most security-relevant compact patch would be:

// Safer SPI decode
wire spi_cmd_magic_ok = (spi_cmd_byte[6:4] == 3'b101);
wire spi_is_write     = spi_packet_ready && spi_write_seen && spi_cmd_magic_ok;
wire [3:0] spi_reg_addr = spi_cmd_byte[3:0];

// SPI may update Wi-Fi count only
wire spi_ctrl_wen      = 1'b0;
wire spi_threshold_wen = 1'b0;
wire spi_wifi_wen      = spi_is_write && (spi_reg_addr == REG_WIFI_COUNT);

Then leave CTRL and THRESHOLD writable only from the TinyQV bus.

Your ESP32 packet for Wi-Fi count would change from:

0x82, count

to something with the magic field:

0xD2, count

because:

0xD2 = 1101_0010
       ^^^^ ^^^^
       |||| register 2
       |101 magic bits
       write bit = 1
Bottom line

The design is already reasonably safe in one important way: it does not directly control red/yellow/green light timing; it only asserts a supplemental request to the original controller. That limits the safety risk.

The main vulnerability is that the SPI side is too trusted. The ESP32-facing SPI input can currently modify control behavior and thresholds. For a stronger design, treat SPI as an untrusted sensor input, not as a privileged controller. Let SPI report only the Wi-Fi count, while the TinyQV bus or fixed reset defaults own the enable, mode, and threshold.

## Conversation 2: Brainstorm security fixes   
**Timestamp**:  2026-04-30 10:28:14
**Tool**: Chat-GPT4
**Purpose**: To see what authentification procedures can be made.

**Prompt**: does ESP32 provide any real authentification procedures that we can use instead of using magic?

**Response**: 
I’ll separate two ideas: ESP32 platform security features, which protect the ESP32 itself, and message authentication between the ESP32 and your TinyQV peripheral, which you would still need to design into the SPI protocol.

Thought for 6s

Yes, but with an important limitation:

ESP32 can provide real authentication primitives, but SPI itself does not automatically authenticate packets. You would need the ESP32 firmware to compute an authentication tag, and your TinyQV Verilog peripheral would need logic to verify it.

The ESP32 family supports security features like Secure Boot, Flash Encryption, eFuse key storage, and on some variants hardware-assisted HMAC and Digital Signature peripherals. Espressif describes HMAC as a way to verify message authenticity and integrity using a pre-shared key, with some ESP32 variants accelerating SHA-256 HMAC using keys stored in eFuses. Espressif also documents Secure Boot as a way to ensure only authenticated firmware runs on the device, and Digital Signature peripherals for hardware-backed device identity on supported chips.

For your TinyQV SPI traffic-light peripheral, the practical answer is:

Option 1: Secure the ESP32 itself

This is useful and realistic.

Use ESP32 features like:

Secure Boot
Flash Encryption
Disable/restrict JTAG/UART download mode
Store keys or secrets in eFuse/NVS securely

This helps ensure the ESP32 runs only your trusted firmware and that an attacker cannot easily extract firmware or keys. But this does not stop random electrical SPI traffic from writing to your TinyQV peripheral unless the TinyQV peripheral checks something.

So this protects the ESP32, not the SPI command stream.

Option 2: Add HMAC-style authentication to SPI packets

This is real authentication.

Instead of sending only:

command byte + data byte

you would send something like:

command + data + counter + MAC

For example:

Byte 0: command/register
Byte 1: Wi-Fi count
Byte 2: sequence counter
Byte 3: truncated authentication tag

The ESP32 computes the tag from a secret key:

tag = HMAC(secret_key, command || data || counter)

Then TinyQV verifies the tag before accepting the write.

However, full HMAC-SHA256 verification in Verilog is probably too large for this tiny design. A SHA-256/HMAC block would be much bigger than the current SPI receiver and register logic.

Option 3: Use a lightweight keyed MAC instead of full HMAC

For TinyTapeout, this is probably the best compromise.

You can implement a tiny challenge/tag check, for example:

tag = data ^ command ^ sequence_counter ^ secret_key[7:0]

or a slightly stronger LFSR/CRC-style keyed checksum:

tag = CRC8(command || data || counter || secret)

This is not cryptographically strong like HMAC-SHA256, but it is much better than a fixed magic pattern because the accepted tag depends on a secret and a changing counter.

A SPI packet could become:

Byte 0: command
Byte 1: data
Byte 2: sequence counter
Byte 3: keyed CRC/MAC

Then the TinyQV design only accepts the packet if:

received_tag == expected_tag

and optionally:

sequence_counter != previous_sequence_counter

That protects against accidental writes and simple replay.

Option 4: Keep authentication on the ESP32 side only

This is weaker but simple.

You can configure the ESP32 with secure boot and flash encryption, then assume the ESP32 firmware is trusted. In that case, your TinyQV peripheral still uses a simple SPI packet format, but you make the peripheral safer by limiting SPI writes:

SPI may only update Wi-Fi count.
SPI may not update CTRL.
SPI may not update threshold.
TinyQV bus owns enable/mode/threshold.

For your project, this is probably the most reasonable implementation.

Recommendation for your design

I would not implement full HMAC-SHA256 verification in your TinyQV peripheral. It is likely too much area for the benefit.

I would do this instead:

1. Use ESP32 Secure Boot + Flash Encryption if this were a real deployment.
2. Make SPI write only REG_WIFI_COUNT.
3. Make REG_CTRL and REG_THRESHOLD bus-only.
4. Add a Wi-Fi freshness timeout.
5. Replace fixed magic with a packet counter + small keyed CRC/tag if you want extra protection.

So instead of:

magic bits only

use:

command + data + counter + keyed 8-bit tag

That gives you a real authentication-like check at very low hardware cost, while still being reasonable for a TinyQV/TinyTapeout-scale Verilog design.

## Conversation 3: Brainstorm security fixes   
**Timestamp**:  2026-04-30 10:29:31
**Tool**: Chat-GPT4
**Purpose**: To see what is feasable

**Prompt**: is it valid to implement option 3 and 4 for security purposes?

**Response**:
Yes, it is valid to implement Option 3 + Option 4 together, and for your TinyQV traffic-request design, that is probably the most reasonable security story.

The clean way to describe it is:

The ESP32 is treated as a mostly trusted sensor node, protected by platform-level security, while the TinyQV peripheral still limits what SPI is allowed to modify and checks SPI packets for lightweight authenticity/integrity.

How the two options work together
Option 4: reduce what SPI is allowed to control

This is the stronger architectural protection.

You would make SPI only update:

REG_WIFI_COUNT

and prevent SPI from writing:

REG_CTRL
REG_THRESHOLD

So even if the ESP32 sends bad data, the ESP32 cannot directly disable the module, change pulse/level mode, or lower the threshold to force constant demand.

That means your trust boundary becomes:

ESP32 can report sensed Wi-Fi demand,
but cannot configure the traffic-request policy.

That is a very defensible design choice.

Option 3: add a lightweight keyed packet check

This adds protection against accidental writes, simple spoofing, random SPI noise, and basic replay attempts.

Instead of accepting:

command + data

you accept:

command + data + sequence_counter + keyed_tag

For example:

Byte 0: command/register
Byte 1: Wi-Fi count
Byte 2: sequence counter
Byte 3: keyed CRC/tag

TinyQV only updates wifi_count_reg when the tag is valid.

Conceptually:

if (spi_wifi_wen && tag_valid && counter_is_new) begin
    wifi_count_reg <= spi_data_byte[3:0];
end
Important wording for your report

Do not oversell Option 3 as strong cryptographic authentication unless you implement a real MAC like HMAC, AES-CMAC, or similar.

A small keyed CRC/XOR/LFSR tag is better described as:

lightweight packet authentication
integrity checking
spoofing resistance
accidental-write protection
replay reduction

Not:

cryptographically secure authentication
tamper-proof communication
secure against advanced attackers

A keyed CRC/tag is valid for a constrained hardware project, but it is not equivalent to HMAC-SHA256.

Recommended final security design

For your project, I would implement:

1. SPI can only write Wi-Fi count.
2. CTRL and THRESHOLD are bus-only.
3. SPI packet includes command, count, counter, and keyed tag.
4. TinyQV rejects packets with invalid tag.
5. TinyQV rejects repeated/stale counters.
6. Wi-Fi count expires if no valid packet arrives for a while.
7. Loop detector still has priority over Wi-Fi request.

That gives you a strong layered argument:

ESP32 platform security protects the sensor firmware.
SPI write restrictions limit damage if SPI misbehaves.
Keyed packet validation rejects malformed or spoofed packets.
Freshness timeout prevents stale Wi-Fi data from persisting forever.
Loop-detector priority preserves compatibility with the original controller.
Best version to implement in Verilog

A practical packet format would be:

Byte 0: command
Byte 1: Wi-Fi count
Byte 2: sequence counter
Byte 3: authentication tag

Where:

tag = CRC8(command, count, sequence, secret_key)

For TinyTapeout size reasons, this is more practical than full HMAC.

Bottom line

Yes, combining Option 3 and Option 4 is valid and actually preferable. Option 4 gives you the most important security improvement by reducing SPI authority, while Option 3 gives you lightweight packet integrity/authentication. Just be careful to call it lightweight authentication/integrity checking, not full cryptographic authentication, unless you implement a real cryptographic MAC.

## Conversation 4: Optimization Re-Evaluation   
**Timestamp**:  2026-05-1 8:52:45
**Tool**: Chat-GPT4
**Purpose**: To see if we can optimize this new security feature

**Prompt**: how practical is this design in terms of sizing, power, and timing?

**Response**:
Yes, the combined Option 3 + Option 4 design is still practical for a TinyQV/TinyTapeout-scale peripheral, but it is no longer quite as “tiny” as the original 16-bit SPI + register design.

The short practical assessment:

Size:   Still reasonable
Power:  Slightly higher, but still low
Timing: Should be fine at normal TinyQV clock rates
Risk:   Main risk is not timing; it is verifying the new SPI/auth logic well
1. Size practicality

The original design was very small: mostly synchronizers, a 16-bit SPI shift register, a few 4-bit registers, compare logic, and interrupt/request logic.

The updated design adds:

32-bit SPI shift register instead of 16-bit
8-bit sequence counter tracking
8-bit received tag register
8-bit CRC/keyed tag calculation
Wi-Fi freshness timeout counter
loop-inactive filter counter
extra status/debug bits

That increases area, but not dramatically. The largest additions are the 32-bit SPI shifter and the CRC8 logic. CRC8 is still much smaller than real HMAC, AES, SHA, or public-key authentication.

For a TinyTapeout-style student peripheral, this is still a reasonable amount of logic.

Rough qualitative size comparison:

Feature	Size impact
SPI write-only receiver	Low
32-bit packet instead of 16-bit packet	Low to moderate
Keyed CRC8 tag check	Moderate
Sequence-counter replay check	Low
Wi-Fi timeout counter	Low to moderate
Loop-inactive filter	Low
Full HMAC/SHA authentication	High / probably impractical

So the design is practical because it avoids the expensive part: full cryptographic MAC verification in hardware.

2. Power practicality

Power should still be low because this is mostly small synchronous logic. The main switching activity happens only when:

SPI SCK edges arrive
registers are written
timeout/filter counters decrement
request/interrupt logic updates

The biggest avoidable power issue is the Wi-Fi timeout counter. If it decrements every clk cycle, it toggles continuously after receiving a packet. That is not huge, but it is the most constant switching activity in the security-enhanced version.

A better low-power version would only decrement the timeout counter using a slow tick.

For example, instead of:

wifi_timeout <= wifi_timeout - 1'b1;

every clock cycle, use a prescaler:

if (timeout_tick && wifi_timeout != 0)
    wifi_timeout <= wifi_timeout - 1'b1;

That reduces switching power significantly.

Power verdict

The design is still practical, but I would avoid large free-running counters if you want to present it as power-conscious.

Best low-power improvements:

1. Decrement timeout only on a slow tick.
2. Only update CRC/tag logic when a full packet is ready.
3. Keep SPI logic mostly idle when CS_N is high.
4. Do not add full SHA/HMAC hardware.

The updated design already follows the most important point by using a lightweight keyed CRC instead of real HMAC.

3. Timing practicality

Timing should be manageable.

The main timing path to watch is the CRC/tag verification path. If the CRC8 is computed combinationally over all packet bytes in one cycle, the path is something like:

spi_packet_ready
→ command/data/sequence/tag decode
→ CRC8 combinational logic
→ tag compare
→ write-enable decision
→ wifi_count_reg update

For CRC8 over four bytes, this is usually still reasonable. It is far smaller than a 32-bit multiplier, SHA block, or CPU datapath.

The SPI receive path itself is also safe if the TinyQV clk is much faster than SPI SCK. Your original design already assumed that SPI SCK is sampled using the TinyQV clock. That assumption still applies.

Important timing assumption:

TinyQV clk must be several times faster than ESP32 SPI SCK.

For example, if TinyQV is running around 25–50 MHz, you should keep the ESP32 SPI clock conservative. Something like:

100 kHz to 1 MHz SPI SCK

is very safe for this sampled-SPI style receiver. Higher may still work, but the design is not a true dedicated SPI-clock-domain peripheral; it is a synchronous sampler using clk.

Timing verdict

The design is practical, but keep ESP32 SPI speed modest. The security logic is unlikely to be the limiting factor; the asynchronous SPI sampling method is more important.

4. Practicality of Option 3 specifically

The lightweight keyed CRC/tag is practical because it provides useful protection with small area.

It helps against:

accidental SPI writes
random noise
wrong SPI mode
simple spoofed packets
simple repeated packets

It does not fully protect against:

an attacker who can extract the key
an attacker who can observe many valid packets and reverse-engineer the weak tag
a compromised ESP32 firmware
advanced cryptographic attacks

So in a report, I would describe it as:

A lightweight keyed integrity and authenticity check suitable for a constrained hardware peripheral.

I would not call it:

Secure cryptographic authentication.

That distinction matters.

5. Practicality of Option 4 specifically

Option 4 is extremely practical and probably the strongest improvement.

Making SPI only write REG_WIFI_COUNT is cheap and very effective. It means the external ESP32 cannot directly change the policy registers.

That gives the design a safer authority split:

TinyQV bus / firmware:
    owns enable, mode, threshold, clear interrupt

ESP32 over SPI:
    only reports observed Wi-Fi count

This is excellent from both a security and safety perspective. It costs almost no area and reduces the damage from bad SPI traffic.

6. Safety behavior

The design is also practical because it still does not directly control the lights. It only asserts a supplemental request to the original 555/controller circuit.

That means even if the Wi-Fi count logic behaves incorrectly, the original traffic-light timing circuit remains responsible for actual light sequencing.

Your design role remains:

sensor-assisted request generator

not:

full traffic-light controller

That is much easier to justify in terms of safety.

7. Main downside

The main downside is verification complexity.

The original design could be tested with simple 16-bit SPI packets:

send command
send data
check register update

The secure version needs more testbench coverage:

valid packet updates Wi-Fi count
invalid tag is rejected
repeated sequence is rejected
wrong register is rejected
SPI cannot write CTRL
SPI cannot write THRESHOLD
stale Wi-Fi count expires
interrupt only asserts on valid demand
loop detector suppresses Wi-Fi request

So the design is still practical in hardware, but the testbench needs to be stronger.

Overall verdict

This is a practical design for TinyQV/TinyTapeout as long as you keep the authentication lightweight.

I would summarize it this way:

The combined Option 3/4 design is a reasonable constrained-hardware security enhancement. It adds modest area and switching power due to the wider SPI packet, CRC8 tag check, sequence tracking, and freshness timeout, but remains much smaller than a true cryptographic HMAC/SHA implementation. Timing should be manageable at normal TinyQV clock rates if the ESP32 SPI clock is kept conservative. The most valuable improvement is limiting SPI authority so the ESP32 can only update the Wi-Fi count, while control and threshold policy remain bus-owned.

Final recommendation:

Keep this design.
Do not add full HMAC/SHA.
Use slow timeout ticking to reduce power.
Keep SPI SCK conservative.
Add a focused security testbench.

For your project, this is a strong balance between security, size, power, and timing.