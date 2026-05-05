# HOST 2026 AHA Challenge — Blue Team Detection Framework

## Overview

This framework uses Claude (Anthropic API) as an AI-powered hardware Trojan
detector. It performs automated analysis of RTL (Verilog/SystemVerilog) designs
to identify malicious modifications without comparing against any golden
reference.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  run_all_detections.py               │
│         (Batch runner for all blue-team projects)    │
└──────────────────────┬──────────────────────────────┘
                       │ calls per-project
                       ▼
┌─────────────────────────────────────────────────────┐
│                  detect_trojans.py                    │
│                                                      │
│  Phase 1: Per-File Analysis                          │
│  ┌──────────────────────────────────────────┐       │
│  │  For each .v/.sv file:                    │       │
│  │  • Read file with line numbers            │       │
│  │  • Send to Claude with expert prompt      │       │
│  │  • Parse structured JSON response         │       │
│  │  • Classify: CLEAN / SUSPICIOUS / TROJAN  │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  Phase 2: Cross-Reference Analysis                   │
│  ┌──────────────────────────────────────────┐       │
│  │  • Consolidate all findings               │       │
│  │  • Identify multi-file Trojans            │       │
│  │  • Eliminate false positives              │       │
│  │  • Rank by severity                       │       │
│  └──────────────────────────────────────────┘       │
│                                                      │
│  Output: <project>_report.json                       │
└─────────────────────────────────────────────────────┘
```

## AI Model & Interaction Method

- **Model:** Claude Sonnet 4 (`claude-sonnet-4-20250514`) via Anthropic API
  - Sonnet chosen for the balance of speed (70 projects × multiple files)
    and analytical capability
  - Can be switched to Opus for higher accuracy on complex designs
- **Interaction:** Python `anthropic` SDK, programmatic API calls
- **No human-in-the-loop:** The pipeline runs fully automatically

## Detection Methodology

### Phase 1: Per-File Semantic Analysis

Each RTL file is analyzed independently using a carefully engineered system
prompt that instructs Claude to look for six categories of hardware Trojan
patterns:

1. **Trigger-Payload Structures** — Rare-condition comparators that gate
   hidden functionality (magic constants, counter thresholds, specific bit
   patterns in inputs)

2. **Data Leakage** — Secret data (keys, internal state) being conditionally
   mixed into outputs via XOR, MUX, or conditional assignment

3. **Denial of Service** — FSM transitions that can be suppressed or stalled,
   causing permanent hangs

4. **Functionality Weakening** — Logic that reduces cryptographic security
   (round reduction, S-box bypass, key zeroing)

5. **Unused/Suspicious Signals** — Registers or wires that only participate
   in anomalous logic paths

6. **Style Anomalies** — Code segments that don't match the surrounding
   authorial style (indentation, naming, comment patterns)

The prompt produces structured JSON output with exact line numbers,
confidence levels, and explanations for each finding.

### Phase 2: Cross-Reference Consolidation

After individual files are analyzed, all findings are sent to a second
Claude call that:
- Merges related findings across files into unified Trojan descriptions
- Eliminates false positives by checking whether "suspicious" patterns
  are actually benign design idioms
- Assigns severity rankings

### Key Design Decisions

- **No diffing:** The framework never compares against a known-good copy.
  All analysis is purely semantic, looking at code structure and behavior.
- **Line-numbered input:** Files are sent with line numbers prepended,
  enabling precise localization in the output.
- **Testbench exclusion:** TB and simulation files are automatically
  excluded from analysis to reduce noise.
- **Rate limiting:** 1-second delay between API calls, 2-second delay
  between projects, to stay within API rate limits.

## Usage

### Prerequisites

```bash
pip install anthropic
export ANTHROPIC_API_KEY="sk-ant-api03-..."
```

### Single Project Analysis

```bash
python3 detect_trojans.py ./blue-team_release/aes/aes_01/
```

### Batch Analysis (All Projects)

```bash
python3 run_all_detections.py ./blue-team_release/ --output-dir ./reports/
```

### Output Format

Each project produces a JSON report:

```json
{
  "project": "aes_01",
  "files_analyzed": 7,
  "per_file_results": [
    {
      "file": "aes_core.v",
      "verdict": "TROJAN_DETECTED",
      "findings": [
        {
          "type": "data_leakage",
          "confidence": "HIGH",
          "lines": "145 - 152",
          "description": "Output conditionally XORed with key material..."
        }
      ]
    }
  ],
  "cross_reference": {
    "trojans_found": 1,
    "consolidated_findings": [...]
  }
}
```

## Formatting Submissions

The detection reports can be formatted for the HOST submission form as follows:

### Files containing Trojan logic:
```
aes_core.v
```

### Lines with Trojan logic:
```
145 - 152
```

### Multi-file example:
```
Files: aes_core.v, aes_sbox.v
Lines: (145 - 152), (23, 45 - 67)
```

## Estimated Performance

Based on analysis of the blue-team release set (44 AES, 13 ETHMAC, 13 CV32E40P):
- **AES projects:** ~7 files each, ~2 min per project
- **ETHMAC projects:** ~20 files each, ~5 min per project
- **CV32E40P projects:** ~25 files each, ~7 min per project
- **Total batch time:** ~4-5 hours for all 70 projects

## Limitations

- False positive rate depends on code quality of the base design
  (unusual-but-benign patterns may flag)
- Very subtle Trojans (e.g., single-bit modifications in lookup tables)
  may be missed in a single-pass analysis
- Token limits may require truncation of very large files (>60K chars)
