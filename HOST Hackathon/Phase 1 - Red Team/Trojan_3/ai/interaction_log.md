# AI Interaction Log — Trojan 3: Denial of Service via Key Memory Stall

## Model Used
- Claude Opus 4.6 (Anthropic) via claude.ai web interface

## Session Overview
Single agentic session where Claude analyzed the AES key expansion FSM, designed a DoS Trojan that permanently stalls key generation, and built the exploit testbench.

---

## Prompt 1: Design Analysis & Trojan Concept

**User:**
> For my third Trojan, I want an availability attack — a denial of service that makes the AES core unusable. Analyze aes_key_mem.v and propose a Trojan.

**Claude's Analysis:**
Claude identified the key memory FSM `key_mem_ctrl`:
- States: CTRL_IDLE → CTRL_INIT → CTRL_GENERATE → CTRL_DONE → CTRL_IDLE
- In CTRL_GENERATE: the FSM loops generating round keys until `round_ctr_reg == num_rounds`
- Transition to CTRL_DONE is the only path to assert `ready`
- If CTRL_DONE is never reached, `ready` stays low and the entire AES core hangs

**Claude's Proposed Design:**
A trigger-latched stall: when `key[255:224] == 32'hBADCAFE0` (during init), a `stall_keygen_reg` flag is latched. When stall is active, the CTRL_GENERATE → CTRL_DONE transition is suppressed. The FSM stays in CTRL_GENERATE forever, the round counter wraps around, and `ready` is never asserted.

**Design Stealthiness:**
- Adds only 1 flip-flop and a 32-bit comparator
- The stall logic is a single `if (!stall_keygen_reg)` guard on an existing transition
- No new states, no structural changes to the FSM
- Trigger is a specific key prefix — extremely unlikely in normal operation
- The core appears to be "processing" — no error signals, just permanent busy

---

## Prompt 2: RTL Generation

**User:**
> Generate the modified aes_key_mem.v with the DoS Trojan.

**Claude's Output:**
Additions to `aes_key_mem.v`:
1. `stall_keygen_reg/new/we` — 1-bit latch (3 lines)
2. Reset initialization for `stall_keygen_reg`
3. Register update for `stall_keygen_reg`
4. In CTRL_IDLE: latch stall based on `key[255:224]` comparator
5. In CTRL_GENERATE: wrap transition to CTRL_DONE in `if (!stall_keygen_reg)`

Total additions: ~12 lines of RTL

---

## Prompt 3: Testbench Generation

**User:**
> Create a testbench that demonstrates normal key init and then the DoS hang.

**Claude's Output:**
`tb_trojan3_dos.v` with:
- TEST 1: Normal AES-128 key init + encryption — proves normal operation
- TEST 2: Key with 0xBADCAFE0 prefix — waits with timeout, confirms hang
- Timeout mechanism (10,000 cycles) to detect the stall condition
- Clear diagnostic output showing cycle counts

---

## CVSS Score Justification
- **Attack Vector:** Network (AV:N) — attacker can supply key material in many protocols
- **Attack Complexity:** Low (AC:L) — deterministic trigger
- **Privileges Required:** None (PR:N) — in many systems, key material comes from negotiation
- **User Interaction:** None (UI:N)
- **Scope:** Unchanged (S:U)
- **Confidentiality:** None (C:N)
- **Integrity:** None (I:N)
- **Availability:** High (A:H) — complete denial of cryptographic service

**CVSS 3.1 Base Score: 7.5 (High)**
Vector: CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
