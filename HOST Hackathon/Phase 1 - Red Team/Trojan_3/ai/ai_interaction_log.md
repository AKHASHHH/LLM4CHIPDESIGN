# Trojan 3 — AI Interaction Log
## Single S-box Entry Corruption in aes_sbox.v

### Method
- Tool: Claude (claude-sonnet-4-6) via claude.ai chat interface
- Approach: Targeted ROM entry modification for minimal footprint

---

### Interaction 1 — S-box analysis

**Prompt:**
"Explain how the AES S-box is implemented in aes_sbox.v. What makes a good target entry to corrupt for a hardware Trojan? I want to minimize PPA impact (zero extra logic) while still having a meaningful security impact."

**Response summary:**
Claude explained the S-box is a pure combinational ROM implemented as 256 `assign` statements. Modifying a single entry adds zero logic (just changes a constant), so PPA impact is literally zero. Claude recommended targeting an entry whose input byte appears frequently in real AES operations to maximize impact, or alternatively one near other entries to reduce visual detectability.

---

### Interaction 2 — Entry selection

**Prompt:**
"Which S-box entry would be most stealthy to modify? I want one that: (1) is surrounded by visually similar values so it's hard to spot, (2) affects real-world inputs enough to be impactful, and (3) has a modification that is hard to detect statistically."

**Response summary:**
Claude suggested entry 0x52 (value 0x00) because: (1) 0x00 is an unusual value in the S-box making the corruption to 0xAA look like it was always non-zero; (2) the byte 0x52 corresponds to ASCII 'R', which appears in common plaintext; (3) the nearby entry 0x62 also has value 0xAA, making the corrupted value look plausible in a visual audit.

---

### Interaction 3 — Modification

**Prompt:**
"Modify aes_sbox.v to change sbox[0x52] from 0x00 to 0xAA. Keep everything else identical."

**Response summary:**
Claude produced the modified file with only the single line change:
`assign sbox[8'h52] = 8'haa; // was 8'h00`

---

### Interaction 4 — Testbench

**Prompt:**
"Write a testbench for this Trojan that: (1) scans all 256 entries against a golden reference, (2) explicitly demonstrates the corrupted entry, (3) shows the impact on a 32-bit word where all bytes are 0x52."

**Response summary:**
Claude wrote a comprehensive testbench with an embedded golden S-box reference, a full 256-entry scan, and targeted demonstrations of the corruption at both byte and word granularity.

---

### CVSS Score: 8.1 (High)
Vector: AV:P/AC:H/PR:N/UI:N/S:C/C:H/I:H/A:N
Rationale: Hardware-level supply chain attack; corrupts encryption silently; affects confidentiality and integrity; requires physical access to implant but no authentication after deployment.
