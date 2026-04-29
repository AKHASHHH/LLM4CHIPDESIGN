# Trojan 2 — AI Interaction Log
## Counter-Based Denial of Service in aes_key_mem.v

### Method
- Tool: Claude (claude-sonnet-4-6) via claude.ai chat interface
- Approach: Analyzed FSM structure, identified ready signal control point

---

### Interaction 1 — Design analysis

**Prompt:**
"In aes_key_mem.v, where is the ready signal controlled? I want to understand all the places where ready_reg is written and under what conditions it goes high vs low."

**Response summary:**
Claude traced the ready signal: it goes low when init is received in CTRL_IDLE, stays low through CTRL_INIT and CTRL_GENERATE, and goes high in CTRL_DONE. The final port assignment is `assign ready = ready_reg`. This is the only control point.

---

### Interaction 2 — Trojan design

**Prompt:**
"Design a hardware Trojan in aes_key_mem.v that implements a time bomb: a counter increments on every key init operation, and after a threshold number of inits, the ready signal is permanently suppressed (held low), causing a denial of service. The Trojan should: (1) use a 20-bit counter to count init events, (2) set a 1-bit locked register when counter >= threshold, (3) AND the locked signal with ready to gate the output. Keep the counter and lock register in the sequential always block."

**Response summary:**
Claude added `trojan2_init_ctr_reg` (20-bit) and `trojan2_locked_reg` (1-bit) registers. A new combinational block increments the counter on each `init` pulse and sets `trojan2_locked_reg` when count >= threshold. The port output uses `assign ready = trojan2_locked_reg ? 1'b0 : ready_reg`.

---

### Interaction 3 — Threshold selection

**Prompt:**
"What threshold value would make this Trojan stealthy in production? It should survive typical validation testing (which usually does fewer than 1000 key inits) but trigger in a real deployment scenario."

**Response summary:**
Claude recommended 20'hFFC00 (~1M inits) as a production threshold. This would pass standard validation suites which typically test fewer than 100 key initializations, but would trigger after extended deployment in a high-throughput server environment.

---

### Interaction 4 — Testbench

**Prompt:**
"Write a testbench that demonstrates the DoS Trojan using a low threshold (10 inits) for simulation speed. Show: normal ready behavior for first 8 inits, then the ready signal permanently going low after the threshold."

**Response summary:**
Claude wrote a self-contained testbench with an embedded low-threshold version of the key_mem module, iterating through 13 key inits and displaying the ready signal status at each step.

---

### CVSS Score: 7.5 (High)
Vector: AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:N/A:H
Rationale: Complete availability loss for AES operations, no authentication required, but no confidentiality or integrity impact.
