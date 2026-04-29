# Trojan 1 — AI Interaction Log
## Key-Triggered Output Corruption in aes_core.v

### Method
- Tool: Claude (claude-sonnet-4-6) via claude.ai chat interface
- Approach: Iterative prompt refinement with RTL context

---

### Interaction 1 — Understanding the design

**Prompt:**
"Analyze this aes_core.v. What is the role of the result output and where is it assigned? I want to understand the data path from muxed_new_block to the output."

**Response summary:**
Claude explained that `result` is a combinational output directly assigned from `muxed_new_block`, which is set from either `enc_new_block` or `dec_new_block` depending on the `encdec` signal. The assignment happens in `encdec_mux` and the final port binding is `assign result = muxed_new_block`.

---

### Interaction 2 — Trojan design

**Prompt:**
"I want to insert a hardware Trojan that silently corrupts the AES output only when a specific 32-bit pattern appears in the upper bits of the key. The Trojan should: (1) arm when init is called with the trigger key, (2) XOR the result with a fixed mask whenever the armed flag is set, (3) use minimal extra logic to keep PPA impact low. Show me the modified aes_core.v."

**Response summary:**
Claude designed a 1-bit `trojan1_armed_reg` register that is set when `key[255:224] == 32'hDEADBEEF` during an `init` pulse. The result output is routed through a conditional XOR: `assign trojan1_result = trojan1_armed_reg ? (muxed_new_block ^ MASK) : muxed_new_block`. The register resets to 0 for any other key.

---

### Interaction 3 — Testbench

**Prompt:**
"Write a Verilog testbench for this Trojan that shows: (1) normal encryption with a benign key, (2) activation with the trigger key prefix, (3) a side-by-side comparison showing the output differs by exactly the XOR mask."

**Response summary:**
Claude wrote `tb_trojan1_aes_core.v` with three test scenarios using the full AES core, proper clock generation, wait tasks for `ready` and `result_valid`, and $display output showing the triggered vs normal results.

---

### Interaction 4 — CVSS scoring

**Prompt:**
"What CVSS 3.1 score would this Trojan receive? It silently corrupts AES encryption output when a specific key prefix is used. There is no authentication bypass, no privilege escalation, but confidentiality and integrity are impacted for any user of the hardware."

**Response summary:**
Claude calculated: AV:N/AC:H/PR:N/UI:N/S:U/C:H/I:H/A:N → CVSS Score: 7.4 (High). However, given the hardware-level attack vector (physical or supply chain), Claude noted the score could be adjusted upward to 9.1 if AV is treated as Physical with permanent hardware modification.

**Final CVSS Score: 9.1 (Critical)**
Vector: AV:P/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:N
