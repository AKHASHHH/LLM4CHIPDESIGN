# HOST 2026 AHA Challenge — Red Team Submission

## Team Information
- **Target Design:** secworks AES Core (AES-128/256 block cipher)
- **AI Model:** Claude Opus 4.6 (Anthropic)
- **Interaction Method:** claude.ai web interface, single agentic session

---

## AI Methodology

### Approach: Agentic Single-Session Pipeline

All three Trojans were designed, implemented, and validated in a single Claude Opus 4.6 session using the claude.ai web interface with computer-use tools. The pipeline was:

1. **Design Analysis** — Claude was given the full AES RTL source tree and hackathon specification. It autonomously read all 7 Verilog files, understood the module hierarchy (`aes` → `aes_core` → `aes_encipher_block`, `aes_decipher_block`, `aes_key_mem`, `aes_sbox`), and identified attack surfaces.

2. **Trojan Design** — For each Trojan, Claude analyzed the specific module, identified the optimal insertion point, and designed a trigger-payload pair optimized for:
   - **Minimal PPA footprint** (all Trojans < 1.1% area overhead)
   - **High CVSS score** (average 8.03)
   - **Stealthiness** (rare triggers, no visible behavioral change in normal operation)

3. **RTL Generation** — Claude generated the modified Verilog files, maintaining the original coding style (naming conventions, comment format, indentation).

4. **Testbench Generation** — Claude generated exploit testbenches that demonstrate both normal (golden) operation and Trojan activation.

5. **PPA Verification** — Claude ran Yosys synthesis (techmap to generic cells) on both the golden and modified designs to compute cell-count overhead.

### Creative AI Techniques
- **Holistic design analysis**: Rather than modifying code line-by-line, Claude analyzed the complete datapath and FSM control flow to identify minimal-impact insertion points
- **Cross-module impact analysis**: Each Trojan was designed to avoid side-effects on other modules in the hierarchy
- **CVSS-driven design**: Trojans were specifically engineered to maximize CVSS vectors (network-accessible triggers, no required privileges)
- **Style-aware generation**: Modified code matches the original author's formatting and commenting conventions

---

## Trojan Summary

| # | Name | File Modified | Trigger | Payload | CVSS | Area Overhead |
|---|------|--------------|---------|---------|------|---------------|
| 1 | Key Leakage | `aes_core.v` | 15× sequential blocks with `block[15:0]==16'h5CA3` | XOR `key[127:0]` into ciphertext output | 7.5 (High) | +1.08% |
| 2 | Encryption Weakening | `aes_encipher_block.v` | `block[127:112]==16'hE0E0` | Reduce AES-128 from 10 rounds to 4 | 9.1 (Critical) | +0.12% |
| 3 | Denial of Service | `aes_key_mem.v` | `key[255:224]==32'hBADCAFE0` | Stall key expansion FSM permanently | 7.5 (High) | +0.20% |

**Average CVSS: 8.03 (High)**
**Average Area Overhead: 0.47%**

---

## Trojan 1: Key Leakage via Ciphertext

### Mechanism
A 4-bit counter (`seq_match_cnt`) increments each time an encryption is initiated with `block[15:0] == 16'h5CA3`. After 15 such trigger encryptions (counter saturates at `4'hF`), the `leak_active` signal asserts. When active, the result output becomes `muxed_new_block XOR key[127:0]`, leaking the secret key through the ciphertext.

### Attack Scenario
An attacker who can submit chosen plaintexts to the AES engine (e.g., over a network protocol) sends 15 blocks ending with `0x5CA3`, then encrypts a known plaintext. By XORing the leaked ciphertext with the expected ciphertext (computed independently), the attacker recovers the full 128-bit key.

### Why It's Stealthy
- Sequential trigger requires 15 specific encryptions — extremely unlikely in normal traffic
- The counter never resets (saturates), so the leak only activates after sustained attacker effort
- No structural changes to the FSM or datapath — only the output MUX is modified
- PPA overhead is dominated by the 128-bit XOR (which the synthesizer may partially share with existing XOR logic)

---

## Trojan 2: Encryption Weakening (Reduced Rounds)

### Mechanism
A `reduced_mode_reg` flag is latched when an encryption starts with `block[127:112] == 16'hE0E0`. When active, the encipher FSM's `num_rounds` variable is overridden from 10 (AES-128) or 14 (AES-256) to just 4. The output is valid-looking 128-bit ciphertext, but encrypted with only 4 rounds.

### Attack Scenario
An attacker sends plaintext with the `0xE0E0` prefix. The resulting ciphertext is protected by only 4 AES rounds, which is trivially breakable using integral/Square cryptanalysis with approximately 2^32 computational work (vs. 2^126 for full AES-128). The attacker can then recover the key and decrypt all past/future traffic.

### Why It's Stealthy
- The ciphertext output is still 128 bits and looks structurally valid
- The trigger is per-block (not persistent), so non-trigger blocks encrypt normally
- Only 1 flip-flop and a 16-bit comparator are added — 0.12% area overhead
- No changes to the round key generation or S-box logic

---

## Trojan 3: Denial of Service via Key Memory Stall

### Mechanism
A `stall_keygen_reg` flag is latched during key initialization when `key[255:224] == 32'hBADCAFE0`. When active, the key expansion FSM's transition from `CTRL_GENERATE` to `CTRL_DONE` is suppressed. The FSM loops in `CTRL_GENERATE` forever, the round counter wraps around endlessly, and `ready` is never asserted.

### Attack Scenario
An attacker who can influence key material (e.g., via a TLS handshake, key derivation input, or key management protocol) supplies a key with the `0xBADCAFE0` prefix. The AES core becomes permanently unresponsive — no encryption or decryption can be performed. Only a full hardware reset recovers the system.

### Why It's Stealthy
- Only 1 flip-flop and a 32-bit comparator are added — 0.20% area overhead
- The FSM structure is unchanged; only an existing transition is conditionally guarded
- No error signals are raised — the core simply appears to be "busy"
- The trigger key prefix is unlikely in normal random key material (probability 2^-32)

---

## PPA Analysis

All synthesis performed with Yosys 0.33, `techmap` pass to generic cells (no liberty-mapped ABC due to runtime constraints in the automated environment). Cell counts serve as a reliable proxy for area.

| Design | Cells | Delta | Overhead |
|--------|-------|-------|----------|
| Golden | 27,600 | — | — |
| Trojan 1 | 27,898 | +298 | +1.08% |
| Trojan 2 | 27,632 | +32 | +0.12% |
| Trojan 3 | 27,656 | +56 | +0.20% |
| **Average** | | | **+0.47%** |

All Trojans are well within the "Exemplary" PPA threshold of <1% average overhead.

---

## Reproducibility

1. Clone this repository
2. Install [Yosys](https://yosyshq.net/yosys/) and [Icarus Verilog](http://iverilog.icarus.com/)
3. For each Trojan:
   - Copy the modified RTL file into the `src/rtl/` directory of the AES project
   - Run the testbench: `iverilog -o tb src/rtl/*.v tb/tb_trojanN_*.v && vvp tb`
   - Run PPA analysis: `cd red-team_phase/aes_synth && bash run_ppa.sh`
4. Compare `metrics/area_report.txt` against `golden_metrics/area_report.txt`
