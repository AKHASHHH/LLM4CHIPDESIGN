# AI Interaction Log — Trojan 2: Encryption Weakening (Reduced Rounds)

## Model Used
- Claude Opus 4.6 (Anthropic) via claude.ai web interface

## Session Overview
Single agentic session where Claude analyzed the AES encipher pipeline, designed a round-reduction Trojan, generated the modified RTL, and built the exploit testbench.

---

## Prompt 1: Design Analysis & Trojan Concept

**User:**
> For my second Trojan, I want to attack the encryption strength itself — making AES output look like valid ciphertext but with drastically reduced security. Analyze aes_encipher_block.v and propose a Trojan.

**Claude's Analysis:**
Claude identified the round control FSM in `encipher_ctrl`:
- `num_rounds` is set to `AES128_ROUNDS (10)` or `AES256_ROUNDS (14)` based on `keylen`
- The `CTRL_MAIN` state compares `round_ctr_reg < num_rounds` to decide between main and final round
- Reducing `num_rounds` would produce valid-looking ciphertext with far fewer rounds

**Claude's Proposed Design:**
A trigger-activated round reduction. When the plaintext `block[127:112] == 16'hE0E0`, a `reduced_mode_reg` flag is latched. When active, `num_rounds` is overridden to 4 instead of 10/14. This produces 4-round AES output — trivially breakable with integral/Square attacks (~2^32 work vs 2^126 for full AES-128).

**Design Stealthiness:**
- Only adds 1 flip-flop (`reduced_mode_reg`) and a comparator + MUX
- The override is purely within the combinational FSM logic
- Output still looks like 128-bit "ciphertext" — no obvious structural tell
- Trigger requires specific plaintext prefix, not activated by normal data

---

## Prompt 2: RTL Generation

**User:**
> Generate the modified aes_encipher_block.v. Keep the Trojan minimal.

**Claude's Output:**
Additions to `aes_encipher_block.v`:
1. `reduced_mode_reg/new/we` — 1-bit trigger latch (3 lines declaration)
2. Reset value for `reduced_mode_reg` in `reg_update`
3. Register update for `reduced_mode_reg` in `reg_update`
4. In `encipher_ctrl` CTRL_IDLE: latch trigger based on `block[127:112]`
5. Override: `if (reduced_mode_reg) num_rounds = 4'h4;`

Total additions: ~15 lines of RTL

---

## Prompt 3: Testbench Generation

**User:**
> Create a testbench showing normal encryption and then weakened encryption with the trigger.

**Claude's Output:**
`tb_trojan2_weak_enc.v` with:
- TEST 1: NIST AES-128 vector — proves normal operation
- TEST 2: Same key, plaintext with 0xE0E0 prefix — shows different (weakened) ciphertext  
- TEST 3: Non-trigger plaintext after trigger — proves trigger is per-block, not persistent

---

## CVSS Score Justification
- **Attack Vector:** Network (AV:N) — attacker controls plaintext
- **Attack Complexity:** Low (AC:L) — deterministic trigger, known weakness
- **Privileges Required:** None (PR:N)
- **User Interaction:** None (UI:N)
- **Scope:** Unchanged (S:U)
- **Confidentiality:** High (C:H) — 4-round AES is trivially reversible, exposing plaintext
- **Integrity:** High (I:H) — attacker can forge ciphertext that decrypts to chosen plaintext
- **Availability:** None (A:N)

**CVSS 3.1 Base Score: 9.1 (Critical)**
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N
