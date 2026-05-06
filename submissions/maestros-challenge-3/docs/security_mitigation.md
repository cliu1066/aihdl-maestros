# Security Review — Challenge 3
Authors: Daniel Onesimo Dong, Candice Liu, April Morales

---

## Scope

This review covers the final combined peripheral which merges the security countermeasures from Design 2 (brute-force lockout, sticky alert) with the full SPI authentication architecture of Design 3 (per-packet CRC8, replay protection, bus/SPI privilege separation, data freshness timeout). Timing optimizations applied for synthesis closure (incremental CRC8, registered pipeline) are also evaluated for security impact.

---

## CIA Analysis

### Confidentiality
The peripheral stores no secrets externally visible to an attacker. The SPI authentication key (0x5C) lives only as a localparam in RTL and is never reflected on any output pin or readable register. REG_AUTH_KEY does not exist in this design — there is no bus register that could leak the key. The incremental CRC computation processes the key constant only at synthesis time as CRC_INIT = 0x93; the raw key byte never travels through live logic. An attacker with read access to all seven registers learns nothing that helps forge a valid tag.

### Integrity
Per-packet CRC8 authentication ensures that every SPI write to REG_WIFI_COUNT carries a keyed tag computed over (KEY, cmd, data, seq). A forged or corrupted packet is rejected. The sequence number field prevents replaying a previously captured valid packet. REG_CTRL and REG_THRESHOLD are bus-only at the RTL level (spi_ctrl_wen and spi_threshold_wen are hardwired to 1'b0), so the ESP32 physically cannot alter peripheral enable state or congestion threshold regardless of what it sends. The brute-force lockout (3 consecutive bad tags triggers LOCKOUT_CYCLES window) prevents offline tag-search attacks conducted over the live SPI bus.

### Availability
The supplemental request output only asserts when: the peripheral is enabled by the RISC-V bus, the loop detector is stably inactive, the WiFi count exceeds the threshold, and the data is still within its freshness window. All five conditions must be simultaneously satisfied. The lockout mechanism temporarily reduces availability to the authenticated ESP32 when a lockout is triggered, which is an intentional denial-of-service tradeoff in favor of integrity. The sec_alert flag provides firmware visibility so the processor can detect and respond to an ongoing attack.

---

## STRIDE Analysis

### Spoofing
An attacker sending arbitrary SPI traffic cannot spoof a valid WiFi count update without knowing the authentication key and computing the correct CRC8 tag for each packet. The sequence number additionally prevents an attacker from replaying a legitimately observed packet. The cmd[6:4] class discriminator (3'b101) provides a secondary filter that rejects packets with incorrect command structure even before tag evaluation. Likelihood: Low.

### Tampering
The bus/SPI privilege separation at the hardware level means the SPI channel cannot tamper with peripheral enable state or threshold, even with a valid tag. WiFi count tampering requires forging a valid CRC8 tag, which requires the key. The freshness timeout ensures that even if tampering succeeds at time T, the effect expires unless the attacker can continuously retransmit. Residual risk: an attacker who recovers the key through side-channel analysis could forge valid packets indefinitely until the key is changed (requires RTL update). Likelihood: Low to medium depending on physical access.

### Repudiation
All SPI packet outcomes are logged in REG_SECURITY. Firmware can read spi_last_tag_ok, spi_last_seq_ok, spi_last_cmd_ok, spi_fail_count, and spi_lockout_active to reconstruct a recent attack timeline. The sticky sec_alert flag preserves evidence of a brute-force attempt across subsequent packets until hardware reset. Limitation: only the most recent packet outcome is retained; there is no event log across multiple packets beyond the fail counter. Likelihood: Low.

### Information Disclosure
No sensitive data is exposed. REG_SECURITY shows the received tag byte (spi_tag_r), which reveals the expected tag value for the last packet. An attacker with read access to the bus can observe spi_tag_r for a known packet to verify their offline CRC8 computation. This does not disclose the key but does provide an oracle for key verification. All other readable fields contain operational status only. Likelihood: Low.

### Denial of Service
An attacker with SPI bus access can deliberately send 3 bad-tag packets to trigger LOCKOUT_CYCLES of denial-of-service against legitimate ESP32 updates. For production tapeout LOCKOUT_CYCLES = 0xFFFF (65535 clock cycles at 64 MHz ≈ 1 ms), which is a manageable recovery window. However, an attacker with continuous SPI access could repeatedly trigger lockouts with a period of (3 packets × ~858 cycles + 65535 lockout) ≈ 68 ms between legitimate updates. This is a residual DoS risk that requires physical SPI access. Likelihood: Medium if physical access is possible.

### Elevation of Privilege
SPI privilege is strictly bounded to REG_WIFI_COUNT by hardwired ties. Bus privilege (RISC-V firmware) can write all registers. There is no path by which SPI can escalate to bus-level control. Likelihood: Negligible.

---

## DREAD Ratings (1–10)

| Threat                         | D | R | E | A | D | Score |
|-------------------------------|---|---|---|---|---|-------|
| SPI WiFi count injection      | 6 | 4 | 4 | 7 | 5 | 5.2   |
| SPI threshold/ctrl tampering  | 8 | 2 | 2 | 8 | 2 | 4.4   |
| Replay attack                 | 6 | 3 | 5 | 7 | 3 | 4.8   |
| Brute-force tag search        | 5 | 2 | 3 | 6 | 3 | 3.8   |
| Lockout-based DoS             | 4 | 5 | 7 | 5 | 5 | 5.2   |
| stale WiFi data exploitation  | 5 | 3 | 4 | 5 | 3 | 4.0   |
| Key disclosure via spi_tag_r  | 3 | 2 | 4 | 3 | 2 | 2.8   |

D = Damage, R = Reproducibility, E = Exploitability, A = Affected users,
D = Discoverability.

---

## CWE Coverage

CWE-20  Improper Input Validation
  Addressed: cmd class discriminator, threshold bus-clamping (0→1), 4-bit wifi_count saturation, spi_write_seen gating.

CWE-284  Improper Access Control
  Addressed: spi_ctrl_wen = 1'b0 and spi_threshold_wen = 1'b0 hardwired. 
  Bus and SPI channels have non-overlapping write authority.

CWE-345  Insufficient Verification of Data Authenticity
  Addressed: CRC8 keyed authentication tag on every SPI packet. 
  Fully mitigated for adversaries without key knowledge.

CWE-294  Authentication Bypass by Capture-Replay
  Addressed: 8-bit sequence number tracked per accepted packet.
  Repeated sequence number causes packet rejection.

CWE-400  Uncontrolled Resource Consumption (Brute Force)
  Addressed: 3-strike lockout halts SPI acceptance for LOCKOUT_CYCLES.
  sec_alert sticky flag triggers firmware IRQ for incident response.

CWE-693  Protection Mechanism Failure
  Partially addressed: CRC8 is lightweight integrity, not a cryptographic MAC.
  Key brute-force offline remains a long-term residual risk.

CWE-1231  Improper Prevention of Lock Bit Modification
  Partially addressed: CTRL and THRESHOLD are bus-only but not hardware-fused.
  A compromised RISC-V firmware image can still modify them.

CWE-1233  Security-Sensitive Hardware Controls with Missing Lock Bit
  Not fully addressed: No eFuse or OTP lock mechanism in current silicon.
  Noted as a future improvement.

CWE-1300  Improper Protection of Physical Side Channels
  Not addressed: CRC8 computation introduces data-dependent switching.
  Power side-channel analysis against CRC_INIT or the key is a residual risk.
  Noted as a future improvement.

---

## Impact of Timing Optimizations on Security Posture

The incremental CRC8 architecture (one byte per clock, registered result)
was chosen to resolve slew and max-capacitance violations. This change has
a neutral-to-positive effect on security:

  Positive: The CRC computation is now spread across four registered clock
  cycles rather than evaluated as a single combinatorial cone. This makes
  power side-channel analysis slightly more difficult because the switching
  activity for each byte is separated in time rather than occurring in a
  single large glitch.

  Neutral: The functional security guarantee is identical. The expected tag
  value stored in spi_crc when byte 3 arrives is mathematically equivalent
  to the original four-call spi_expected_tag() result.

  No regression: The registered pipeline does not introduce any window during
  which a partial or intermediate CRC value is acted upon. spi_pkt_ready is
  only asserted after byte 3 is fully received and spi_tag_match is
  registered, ensuring the comparison is atomic with respect to firmware.

The brute-force lockout counter (spi_lockout_timer) is a registered 16-bit
decrement chain. Its switching activity is independent of packet content and
does not leak key-related information.

---

## Residual Risks

1. Lightweight key (8-bit constant): CRC8 with a single known polynomial and
   a static 8-bit key provides only 256 possible tag spaces per packet. An
   offline attacker who observes one valid (cmd, data, seq, tag) tuple can
   verify a key guess in O(1). A 256-iteration exhaustive key search is
   trivial. Mitigation path: replace with HMAC-SHA256 on the ESP32 and a
   hardware AES-128 block on TinyQV, or use a rotating session key
   negotiated at reset.

2. Sequence counter wrap: The 8-bit sequence number wraps at 256. After
   256 accepted packets the first sequence number becomes valid again,
   allowing replay of the oldest observed packet. Mitigation path: expand
   sequence to 16 bits, or add a monotonic session nonce seeded from a
   hardware entropy source at reset.

3. No physical tamper detection: An attacker with oscilloscope access to
   ui_in[1:3] can observe all SPI traffic passively. Combined with risk 1,
   this means key recovery is possible with enough observations and offline
   computation. Mitigation path: power masking, shielded routing.

4. Lockout-based DoS via continuous bad packets: Covered in STRIDE section.
   No hardware mitigation beyond the lockout window itself.

5. RISC-V firmware trust: The bus-side has unrestricted write access to all
   registers including CTRL and THRESHOLD. A compromised firmware image
   defeats all hardware security. Mitigation path: hardware eFuse lock bits,
   secure boot on the RISC-V core.

---

# Mitigation Plan — tqvp_spi_traffic3

## Implemented Mitigations (Current Silicon)

| ID  | Threat                        | Mitigation                                   | Status      |
|-----|-------------------------------|----------------------------------------------|-------------|
| M1  | Unauthenticated SPI writes    | CRC8 keyed tag required on every packet      | Implemented |
| M2  | Replay attacks                | 8-bit sequence number, last_spi_seq tracked  | Implemented |
| M3  | SPI privilege escalation      | CTRL and THRESHOLD bus-only (hardwired 1'b0) | Implemented |
| M4  | Stale WiFi data               | Prescaled freshness timeout, wifi_valid flag  | Implemented |
| M5  | Brute-force tag search        | 3-strike lockout, LOCKOUT_CYCLES window      | Implemented |
| M6  | Silent security failures      | Sticky sec_alert, IRQ on alert rise          | Implemented |
| M7  | Invalid command structure     | cmd[6:4] class discriminator                 | Implemented |
| M8  | Zero threshold (always-on)    | Bus clamp: write 0 → stored as 1             | Implemented |
| M9  | Short glitch on loop input    | 3-stage sync + 15-cycle inactive filter      | Implemented |
| M10 | IRQ flooding on sustained demand | Edge-triggered latch, clearable by firmware | Implemented |
| M11 | Key exposure via register     | No REG_AUTH_KEY; key never in readable reg   | Implemented |
| M12 | CRC path timing violations    | Incremental CRC8, registered tag comparison  | Implemented |

## Mitigation State Machine: SPI Authentication Flow
IDLE (spi_cs_active = 0)
│  spi_crc ← CRC_INIT (= CRC8(0,KEY), pre-computed)
│
▼
BYTE_0: receive cmd
│  spi_crc ← crc8_update(spi_crc, cmd)
│  register: spi_cmd_r, spi_write_seen, spi_cmd_class_ok_r
▼
BYTE_1: receive data
│  spi_crc ← crc8_update(spi_crc, data)
│  register: spi_dat_r
▼
BYTE_2: receive seq
│  spi_crc ← crc8_update(spi_crc, seq)
│  register: spi_seq_r
│  spi_crc now holds expected authentication tag
▼
BYTE_3: receive tag
│  spi_tag_match ← (received_tag == spi_crc)   [registered, 3 gate levels]
│  spi_pkt_ready ← 1 (one-cycle pulse)
▼
EVALUATE (next cycle, all inputs stable registers)
│
├─ tag_match=0 → increment spi_fail_count
│    ├─ fail_count < 3: remain unlocked, update status regs
│    └─ fail_count = 3: spi_lockout_active ← 1
│                        sec_alert ← 1 (sticky)
│                        IRQ fires on sec_alert_rise
│
├─ lockout_active=1 → reject packet regardless of tag
│
└─ tag_match=1 AND seq_fresh=1 AND cmd_class_ok=1 AND write_seen=1
└─ spi_wifi_wen fires:
wifi_count_reg ← spi_dat_r[3:0]
wifi_timeout   ← WIFI_TIMEOUT_MAX   (freshness reset)
last_spi_seq   ← spi_seq_r
spi_fail_count ← 0

## Planned Future Mitigations

| Priority | ID  | Residual Risk Addressed        | Proposed Mitigation                          |
|----------|-----|-------------------------------|----------------------------------------------|
| High     | F1  | 8-bit key brute-force         | Replace CRC8 tag with HMAC-SHA256; expand    |
|          |     |                               | tag to 32 bits; key provisioned via eFuse    |
| High     | F2  | Sequence number wrap (8-bit)  | Expand seq to 16 bits; add session nonce     |
|          |     |                               | seeded from TRNG at reset                    |
| Medium   | F3  | Compromised RISC-V firmware   | Hardware eFuse write-lock for CTRL and       |
|          |     |                               | THRESHOLD after initial provisioning         |
| Medium   | F4  | Passive SPI observation       | AES-128 encrypt SPI payload on ESP32;        |
|          |     |                               | hardware decrypt block on TinyQV             |
| Medium   | F5  | Power side-channel on CRC     | Insert dummy switching register clocked      |
|          |     |                               | on inverse edge during CRC update cycles     |
| Low      | F6  | Physical access to SPI lines  | Board-level shielded routing, test-point     |
|          |     |                               | removal on production PCB                    |
| Low      | F7  | Reset glitch attack on rst_n  | 3-FF synchronizer on rst_n input before      |
|          |     |                               | distribution to all registers                |
| Low      | F8  | Multi-packet attack history   | Expand fail log to 4-entry FIFO in           |
|          |     |                               | REG_SECURITY for post-incident forensics     |