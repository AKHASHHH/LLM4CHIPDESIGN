# AI Interaction Log — Trojan 1: Key Leakage via Ciphertext

## Model Used
- Claude Opus 4.6 (Anthropic) via claude.ai web interface

## Session Overview
Single agentic session where Claude analyzed the full AES design, designed the Trojan, generated modified RTL, and created the exploit testbench.

---

## Prompt 1: Design Analysis & Trojan Concept

**User:**
> I'm participating in the HOST 2026 AHA Challenge. I've chosen the secworks AES core as my target. I need to insert a hardware Trojan that leaks the encryption key through the ciphertext output. The Trojan should be stealthy (minimal PPA overhead) and have a high CVSS score. Please analyze the aes_core.v module and propose a Trojan design.

**Claude's Analysis:**
Claude analyzed the `aes_core.v` module structure, identifying:
- The `result` output assignment: `assign result = muxed_new_block;`
- The `key` input (256 bits) available throughout the module
- The `block` input (plaintext) available for trigger conditioning
- The `next` signal as a timing anchor for trigger events

**Claude's Proposed Design:**
A counter-based sequential trigger that requires 15 consecutive encryptions where `block[15:0] == 16'h5CA3`. On the 16th such encryption, the output is XORed with `key[127:0]`, leaking the key material through the ciphertext. The attacker recovers the key by XORing the leaked output with the expected ciphertext.

**Rationale for design choices:**
- Sequential trigger (4-bit counter) adds minimal area — only 4 flip-flops + comparator
- Trigger pattern is rare in normal traffic (specific 16-bit alignment)
- Counter must saturate at 15, requiring sustained attacker control
- XOR-based payload is purely combinational, zero timing impact
- The key leak is deterministic: leaked_ciphertext XOR expected_ciphertext = key

---

## Prompt 2: RTL Generation

**User:**
> Generate the modified aes_core.v with the Trojan inserted. Keep changes minimal and blend with existing coding style.

**Claude's Output:**
Claude generated the complete modified `aes_core.v` with the following additions:
1. `seq_match_cnt` (4-bit register) — sequential trigger counter
2. `seq_pattern_match` (wire) — combinational match on `block[15:8] == 8'hA3 & block[7:0] == 8'h5C`  
3. `leak_active` (wire) — asserted when counter saturates at 0xF
4. Modified `result` assignment with conditional MUX
5. Counter increment logic in `reg_update` always block

Lines changed: ~12 lines added, 1 line modified (result assignment)

---

## Prompt 3: Testbench Generation

**User:**
> Create a testbench that demonstrates both normal AES operation (using NIST test vectors) and the Trojan activation/key leakage.

**Claude's Output:**
Claude generated `tb_trojan1_key_leak.v` with:
- TEST 1: NIST AES-128 test vector verification (normal operation proof)
- TEST 2: 15 trigger-pattern block encryptions to arm the Trojan, then a 16th encryption showing the leaked result
- Helper tasks for register-level AES core interaction
- Clear pass/fail reporting

---

## CVSS Score Justification
- **Attack Vector:** Network (AV:N) — attacker can send crafted plaintexts remotely
- **Attack Complexity:** Low (AC:L) — trigger pattern is deterministic
- **Privileges Required:** None (PR:N)
- **User Interaction:** None (UI:N)
- **Scope:** Unchanged (S:U)
- **Confidentiality:** High (C:H) — full secret key recovery
- **Integrity:** None (I:N)
- **Availability:** None (A:N)

**CVSS 3.1 Base Score: 7.5 (High)**
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N
