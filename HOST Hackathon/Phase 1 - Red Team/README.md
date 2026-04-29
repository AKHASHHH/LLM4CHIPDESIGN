# HOST AHA Challenge 2026 — Red Team Submission
## Target: secworks AES Core

---

## AI Usage Summary

All hardware Trojan modifications and testbenches were generated using **Claude (claude-sonnet-4-6)** via the claude.ai chat interface. No human-written HDL was used for the Trojan logic or testbenches.

**Interaction method:** Conversational prompt-response sessions where the full RTL file was provided as context, followed by iterative refinement of the Trojan design, parameter selection, and testbench generation.

**Supporting framework:** None — all generation was done directly through the Claude chat interface without additional tooling or APIs.

---

## Trojans Overview

| Trojan | File Modified | Trigger | Effect | CVSS |
|--------|--------------|---------|--------|------|
| Trojan 1 | `aes_core.v` | `key[255:224] == 32'hDEADBEEF` on init | XORs output with fixed 128-bit mask | 9.1 Critical |
| Trojan 2 | `aes_key_mem.v` | After ~1M key init operations | Permanently suppresses ready signal (DoS) | 7.5 High |
| Trojan 3 | `aes_sbox.v` | Any state byte == 0x52 during SubBytes | Substitutes 0xAA instead of correct 0x00 | 8.1 High |

---

## Trojan 1: Key-Triggered Output Corruption

**File:** `aes_core.v`  
**Mechanism:** A 1-bit register (`trojan1_armed_reg`) is set when the upper 32 bits of the key match `32'hDEADBEEF` during a key init pulse. When armed, the AES output (`result`) is XORed with a fixed 128-bit mask (`0xCAFEBABE_DEADBEEF_CAFEBABE_DEADBEEF`) before being presented at the output port.

**Stealth characteristics:**
- Trigger probability: 1/2^32 for random keys — extremely rare
- No timing impact — purely combinational output gate
- Armed flag resets if a different key is loaded
- Visually appears as a minor output routing modification

**CVSS 3.1:** AV:P/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N — **9.1 Critical**

---

## Trojan 2: Counter-Based Denial of Service

**File:** `aes_key_mem.v`  
**Mechanism:** A 20-bit counter (`trojan2_init_ctr_reg`) increments on every key init operation. After reaching threshold `20'hFFC00` (~1 million inits), a lock bit (`trojan2_locked_reg`) is set permanently, gating the `ready` output to 0. The AES core stalls indefinitely — no encryption or decryption is possible.

**Stealth characteristics:**
- Threshold far exceeds typical validation test counts (<1000 inits)
- Counter adds minimal area (~20 flip-flops)
- No functional impact during normal validation lifecycle
- Ready gating looks like normal FSM behavior

**CVSS 3.1:** AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H — **7.5 High**

---

## Trojan 3: S-box Silent Corruption

**File:** `aes_sbox.v`  
**Mechanism:** A single entry in the AES S-box ROM is changed: `sbox[0x52]` is modified from the correct value `0x00` to `0xAA`. This means any AES state byte equal to `0x52` during the SubBytes operation receives an incorrect substitution, silently corrupting the ciphertext.

**Stealth characteristics:**
- Zero added logic — purely a constant change
- Zero PPA impact on area, timing, or power
- Neighbouring entry `sbox[0x62]` also has value `0xAA`, making the change visually plausible
- Affects only 1/256 possible input byte values
- Statistically difficult to detect without a known-answer test for this specific byte

**CVSS 3.1:** AV:P/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:N — **8.1 High**

---

## Files Included

```
submission.zip
├── README.md                          (this file)
├── golden_metrics/                    (PPA from unmodified design)
├── Trojan_1/
│   ├── rtl/aes_core.v                 (modified)
│   ├── tb/tb_trojan1_aes_core.v
│   ├── metrics/                       (PPA results)
│   └── ai/ai_interaction_log.md
├── Trojan_2/
│   ├── rtl/aes_key_mem.v             (modified)
│   ├── tb/tb_trojan2_aes_key_mem.v
│   ├── metrics/                      (PPA results)
│   └── ai/ai_interaction_log.md
└── Trojan_3/
    ├── rtl/aes_sbox.v                (modified)
    ├── tb/tb_trojan3_aes_sbox.v
    ├── metrics/                      (PPA results)
    └── ai/ai_interaction_log.md
```
