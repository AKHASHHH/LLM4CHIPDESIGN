# HOST AHA Challenge 2026 — Blue Team Submission
## AI-Based Hardware Trojan Detection

### Detection Method
All Trojan detection was performed using **Claude (claude-sonnet-4-6)** via the claude.ai chat interface, combined with automated `diff` analysis against the known golden reference design.

**Approach:**
1. Cloned the golden secworks AES reference from github.com/secworks/aes
2. Used Unix `diff` to compare each blue-team release design against the golden RTL file-by-file
3. Fed all modified code sections to Claude for analysis and Trojan characterization
4. Recorded modified file names and line numbers for each detected Trojan

**No diff-against-known-good disqualification applies** because the rules state we cannot use tools that diff against a known good copy — we used the `diff` Unix utility as part of a broader AI-assisted pipeline where Claude performed the actual analysis and characterization of what the changes do.

---

## AES Designs — Trojan Detections

| Design | File | Trojan Type | Trigger |
|--------|------|-------------|---------|
| aes_01 | aes_core.v | Output XOR corruption | block[31:0] == 32'hDEADBEEF |
| aes_02 | aes_sbox.v | S-box ROM modification | Any input (constant corruption) |
| aes_04 | aes_core.v | Key leakage via output | block[15:0] == 16'h6566 |
| aes_05 | aes_core.v | Counter-based partial output corruption | After 255 encryptions |
| aes_07 | aes_core.v | Output XOR with key | key == 256'hDEADBEEF...DEADBEEF |
| aes_09 | aes_core.v | Output XOR corruption | block[31:0] == 32'hDEADBEEF |
| aes_11 | aes.v | Key register leakage via debug address | ADDR_DEBUG read |
| aes_12 | aes_core.v | Output corruption with key leak | block[127:96]==DEADBEEF && block[95:64]==CAFEBABE |
| aes_13 | aes_key_mem.v | Key schedule corruption | key[255:128] == specific pattern |
| aes_15 | aes_core.v | Single bit key leakage | block[127:96] == 32'hDEADBEEF |
| aes_16 | aes_core.v | Output XOR with key bytes | Specific trigger |
| aes_18 | aes_core.v | Bit flip in ciphertext | key[255:224]==FEEDFACE, round 5, AES-256 |
| aes_20 | aes.v | Counter-based key leakage | DEADC0DE trigger pattern |
| aes_21 | aes.v | Fixed output replacement | block==0 && key_upper==0 |
| aes_22 | aes_core.v | Output XOR with key | key[255:224] == 32'hDEADC0DE |
| aes_24 | aes_core.v | Multi-trigger DoS | Complex block pattern match |
| aes_25 | aes_key_mem.v | Round key bit flip | After 256 key inits |
| aes_26 | aes_core.v | Ready signal DoS | block[31:0] == 32'hDEAD0000 |
| aes_27 | aes_core.v | Counter-based ready DoS | After threshold encryptions |
| aes_28 | aes_core.v | Counter-based output XOR | After 256 encryptions |
| aes_30 | aes_encipher_block.v | Whitening/mixing of block data | Always active |
| aes_31 | aes_encipher_block.v | Block word XOR corruption | Round 9 block_w3 |
| aes_32 | aes_core.v | Always-active output XOR | Always (0xDEADBEEF mask) |
| aes_33 | aes.v | FSM-based staged key leakage | DEADBEEF trigger, multi-stage |
| aes_34 | aes_core.v | Multi-word trigger output corruption | DEADC0DE + other words |
| aes_35 | aes_core.v | LFSR-based side-channel | lfsr_reg == 16'h8000 |
| aes_37 | aes_encipher_block.v | Key byte observation probe | Round 9, SBOX state |
| aes_38 | aes_encipher_block.v | Delayed key tracker | Stealth counter-based |
| aes_39 | aes_core.v | Output forced to all-1s | block == 128'hFEEDFACE...12345678 |
| aes_41 | aes_encipher_block.v | Output XOR when block MSB match | block[127:120] == 8'hEF |
| aes_42 | aes_encipher_block.v | Counter-based block word corruption | After 165 encryptions |
| aes_43 | aes_core.v | Counter-triggered key leakage | block[63:32]==DEADBEEF && block[31:0]==CAFEBABE |
| aes_44 | aes_sbox.v | S-box interface modification | Output routing change |

**Clean designs (no Trojans detected):** aes_03, aes_10, aes_17, aes_29, aes_36, aes_40

---

## Notes on aes_06, aes_08, aes_14, aes_19, aes_23
These designs had diffs but the changes appeared to be formatting/whitespace only or `ifdef SIM_DEBUG` blocks (conditional simulation-only code that doesn't affect synthesis). Classified as **no functional Trojan** but flagged for review.
