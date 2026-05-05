#!/usr/bin/env python3
"""
heuristic_detector.py — Offline heuristic Trojan detector (no API needed)

This is a complementary tool that uses pattern-matching heuristics to
flag potential Trojans. It does NOT replace the AI-based detector but
provides instant results for quick triage.

Usage:
    python3 heuristic_detector.py <project_dir>
"""

import os
import sys
import re
import json
import glob
from pathlib import Path


# ---------------------------------------------------------------------------
# Heuristic patterns for common Trojan signatures
# ---------------------------------------------------------------------------
HEURISTIC_PATTERNS = [
    {
        "name": "magic_constant_comparator",
        "desc": "Comparator against a magic constant (potential trigger)",
        "regex": r"==\s*(32\'h[0-9A-Fa-f]{4,}|16\'h[0-9A-Fa-f]{3,}|8\'h[0-9A-Fa-f]{2})",
        "severity": "MEDIUM",
        "exceptions": [
            # Known-good constants in AES
            r"8\'h(00|1b|8d|01|02|03|04|08|10|20|40|80)",
            r"32\'h(0{8}|61657320|20202020|302e3630)",  # AES name/version
            r"8\'h0[0-9a]",  # Small address constants
        ]
    },
    {
        "name": "key_in_output_path",
        "desc": "Key material appearing in output assignment (potential leakage)",
        "regex": r"(result|output|out|read_data)\s*=.*\bkey\b",
        "severity": "HIGH"
    },
    {
        "name": "key_xor_output",
        "desc": "XOR between key and output data (potential leakage)",
        "regex": r"\^.*\bkey\b|\bkey\b.*\^",
        "severity": "HIGH"
    },
    {
        "name": "conditional_output_override",
        "desc": "Ternary operator on output with unusual condition",
        "regex": r"assign\s+(result|output|new_block|read_data)\s*=\s*\w+\s*\?",
        "severity": "MEDIUM"
    },
    {
        "name": "counter_with_saturation",
        "desc": "Counter register that saturates (potential sequential trigger)",
        "regex": r"(\w+_cnt|\w+_ctr|\w+_count)\s*<=\s*\1\s*\+",
        "severity": "LOW"
    },
    {
        "name": "fsm_transition_guard",
        "desc": "Conditional guard on FSM transition (potential DoS)",
        "regex": r"if\s*\(\s*!\s*\w*(stall|block|halt|freeze|disable|stop)\w*\s*\)",
        "severity": "HIGH"
    },
    {
        "name": "round_reduction",
        "desc": "Override of round count variable (potential weakening)",
        "regex": r"num_rounds\s*=\s*4\'h[0-4]",
        "severity": "HIGH"
    },
    {
        "name": "dead_code_signal",
        "desc": "Signal declared but minimally used (potential dormant Trojan)",
        "regex": r"^\s*(reg|wire)\s+.*?(trojan|backdoor|payload|trigger|leak|malicious)",
        "severity": "HIGH"
    },
    {
        "name": "unusual_block_pattern_check",
        "desc": "Comparison on block/plaintext input bits (potential trigger)",
        "regex": r"block\s*\[\s*\d+\s*:\s*\d+\s*\]\s*==",
        "severity": "MEDIUM"
    },
    {
        "name": "unusual_key_pattern_check",
        "desc": "Comparison on key input bits (potential trigger)",
        "regex": r"key\s*\[\s*\d+\s*:\s*\d+\s*\]\s*==",
        "severity": "MEDIUM"
    },
]


def analyze_file_heuristic(filepath: str) -> dict:
    """Run heuristic pattern matching on a single file."""
    filename = os.path.basename(filepath)
    findings = []

    with open(filepath, "r", errors="replace") as f:
        lines = f.readlines()

    for pattern in HEURISTIC_PATTERNS:
        regex = re.compile(pattern["regex"], re.IGNORECASE)
        exceptions = [re.compile(e, re.IGNORECASE) for e in pattern.get("exceptions", [])]

        for line_num, line in enumerate(lines, 1):
            # Skip comments
            stripped = line.split("//")[0].strip()
            if not stripped or stripped.startswith("/*"):
                continue

            match = regex.search(stripped)
            if match:
                # Check exceptions
                is_exception = any(exc.search(match.group(0)) for exc in exceptions)
                if is_exception:
                    continue

                findings.append({
                    "type": pattern["name"],
                    "severity": pattern["severity"],
                    "line": line_num,
                    "matched_text": match.group(0).strip(),
                    "description": pattern["desc"],
                    "context": line.rstrip()
                })

    verdict = "CLEAN"
    if any(f["severity"] == "HIGH" for f in findings):
        verdict = "TROJAN_DETECTED"
    elif findings:
        verdict = "SUSPICIOUS"

    return {
        "file": filename,
        "path": filepath,
        "verdict": verdict,
        "findings": findings
    }


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <project_dir>")
        sys.exit(1)

    project_dir = os.path.abspath(sys.argv[1])
    project_name = os.path.basename(project_dir)

    # Find RTL files
    rtl_files = []
    for ext in ["**/*.v", "**/*.sv"]:
        for f in glob.glob(os.path.join(project_dir, ext), recursive=True):
            fpath = f.lower()
            if any(skip in fpath for skip in ["/tb/", "/tb_", "testbench",
                                               "/sim/", "/model/", "/bhv/",
                                               "/sva/", "/example_tb/"]):
                continue
            rtl_files.append(f)

    rtl_files.sort()

    print(f"{'=' * 60}")
    print(f"  Heuristic Trojan Detector — {project_name}")
    print(f"  Files to analyze: {len(rtl_files)}")
    print(f"{'=' * 60}")

    all_results = []
    for filepath in rtl_files:
        result = analyze_file_heuristic(filepath)
        all_results.append(result)

        fname = result["file"]
        verdict = result["verdict"]
        n = len(result["findings"])
        marker = {"CLEAN": "✓", "SUSPICIOUS": "⚠", "TROJAN_DETECTED": "✗"}.get(verdict, "?")
        print(f"\n  {marker} {fname}: {verdict} ({n} findings)")

        for f in result["findings"]:
            print(f"     [{f['severity']:6s}] Line {f['line']:4d}: {f['type']}")
            print(f"              {f['matched_text']}")

    # Summary
    infected = [r for r in all_results if r["verdict"] == "TROJAN_DETECTED"]
    suspicious = [r for r in all_results if r["verdict"] == "SUSPICIOUS"]

    print(f"\n{'=' * 60}")
    print(f"  SUMMARY: {len(infected)} infected, {len(suspicious)} suspicious, "
          f"{len(all_results) - len(infected) - len(suspicious)} clean")
    print(f"{'=' * 60}")

    # Save report
    report_file = f"{project_name}_heuristic_report.json"
    with open(report_file, "w") as f:
        json.dump({"project": project_name, "results": all_results}, f, indent=2)
    print(f"  Report saved: {report_file}")


if __name__ == "__main__":
    main()
