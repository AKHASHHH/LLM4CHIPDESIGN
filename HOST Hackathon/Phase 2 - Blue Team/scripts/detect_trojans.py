#!/usr/bin/env python3
"""
HOST 2026 AHA Challenge — Blue Team Trojan Detection Framework
=============================================================

This script uses Claude (Anthropic API) to analyze hardware designs
for potential Trojan insertions. It processes each RTL file in a
given project directory and produces a structured detection report.

Usage:
    python3 detect_trojans.py <project_dir> [--api-key KEY] [--model MODEL]

Example:
    python3 detect_trojans.py ./blue-team_release/aes/aes_01/
    python3 detect_trojans.py ./blue-team_release/ethmac/ethmac_05/
    python3 detect_trojans.py ./blue-team_release/cv32e40p/cv32e40p_03/

Requirements:
    pip install anthropic
"""

import os
import sys
import json
import argparse
import glob
import time
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("ERROR: 'anthropic' package not installed. Run: pip install anthropic")
    sys.exit(1)


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_MODEL = "claude-sonnet-4-20250514"
MAX_FILE_CHARS = 60000  # Truncate very large files

SYSTEM_PROMPT = """\
You are an expert hardware security analyst specializing in hardware Trojan \
detection in RTL (Verilog / SystemVerilog) designs. Your task is to analyze \
the provided source file for signs of malicious modifications (hardware Trojans).

IMPORTANT RULES:
- You must NOT compare the code against any known-good "golden" reference. \
  You are analyzing the code purely on its own merits.
- Focus on structural, behavioral, and semantic anomalies.

Look for these common hardware Trojan patterns:

1. **Trigger-Payload Structures**: Combinational or sequential logic that \
   activates a hidden payload when a rare condition is met (magic constants, \
   counter thresholds, specific input patterns).

2. **Data Leakage**: Secret data (keys, internal state) being XORed, MUXed, \
   or otherwise mixed into observable outputs under certain conditions.

3. **Denial of Service**: FSM transitions that can be suppressed or stalled, \
   causing the design to hang or become unresponsive.

4. **Functionality Weakening**: Logic that reduces the effective security of \
   cryptographic operations (e.g., reducing round counts, zeroing key bits, \
   bypassing S-boxes).

5. **Unused or Suspicious Signals**: Registers/wires declared but only used \
   in suspicious contexts, dead code that could be activated, redundant \
   comparators on input data.

6. **Style Anomalies**: Code that doesn't match the surrounding style \
   (different indentation, naming conventions, comment patterns), which may \
   indicate post-hoc insertion.

For EACH suspicious finding, provide:
- The exact line numbers involved
- The type of Trojan (trigger, payload, leakage, DoS, weakening, etc.)
- A confidence level (HIGH / MEDIUM / LOW)
- A clear explanation of the suspected malicious behavior

If the file appears clean, explicitly state that no Trojans were detected.

Respond in the following JSON format:
{
  "file": "<filename>",
  "verdict": "CLEAN" | "SUSPICIOUS" | "TROJAN_DETECTED",
  "findings": [
    {
      "type": "<trojan_type>",
      "confidence": "HIGH" | "MEDIUM" | "LOW",
      "lines": "<line range, e.g. '145 - 152' or '23, 45, 67 - 89'>",
      "description": "<explanation>"
    }
  ],
  "summary": "<one-paragraph summary>"
}

Return ONLY valid JSON. No markdown fences, no preamble.
"""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def read_rtl_file(filepath: str) -> str:
    """Read an RTL file and add line numbers."""
    with open(filepath, "r", errors="replace") as f:
        lines = f.readlines()

    numbered = []
    for i, line in enumerate(lines, 1):
        numbered.append(f"{i:4d} | {line.rstrip()}")

    content = "\n".join(numbered)
    if len(content) > MAX_FILE_CHARS:
        content = content[:MAX_FILE_CHARS] + "\n... [TRUNCATED]"
    return content


def find_rtl_files(project_dir: str) -> list:
    """Find all .v and .sv RTL source files (excluding testbenches)."""
    rtl_files = []
    for pattern in ["**/*.v", "**/*.sv"]:
        for f in glob.glob(os.path.join(project_dir, pattern), recursive=True):
            # Skip testbenches, simulation files, model files
            fpath = f.lower()
            if any(skip in fpath for skip in ["/tb/", "/tb_", "testbench",
                                               "/sim/", "/model/", "/bhv/",
                                               "/sva/", "/example_tb/"]):
                continue
            rtl_files.append(f)
    return sorted(rtl_files)


def analyze_file(client, model: str, filepath: str) -> dict:
    """Send a single RTL file to Claude for Trojan analysis."""
    filename = os.path.basename(filepath)
    content = read_rtl_file(filepath)

    user_msg = (
        f"Analyze the following RTL file for hardware Trojans.\n"
        f"File: {filename}\n"
        f"Path: {filepath}\n\n"
        f"```verilog\n{content}\n```"
    )

    try:
        response = client.messages.create(
            model=model,
            max_tokens=4096,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_msg}],
        )

        raw_text = response.content[0].text.strip()

        # Try to parse JSON
        # Handle potential markdown fences
        if raw_text.startswith("```"):
            raw_text = raw_text.split("```")[1]
            if raw_text.startswith("json"):
                raw_text = raw_text[4:]

        result = json.loads(raw_text)
        result["_raw_response"] = raw_text[:500]  # Keep snippet for debugging
        return result

    except json.JSONDecodeError:
        return {
            "file": filename,
            "verdict": "ANALYSIS_ERROR",
            "findings": [],
            "summary": f"Failed to parse AI response as JSON.",
            "_raw_response": raw_text[:1000] if 'raw_text' in dir() else "No response"
        }
    except Exception as e:
        return {
            "file": filename,
            "verdict": "ANALYSIS_ERROR",
            "findings": [],
            "summary": f"API error: {str(e)}",
            "_raw_response": ""
        }


def cross_reference_analysis(client, model: str, project_dir: str,
                             file_results: list) -> dict:
    """
    Second-pass analysis: cross-reference findings across all files in the
    project to identify multi-file Trojans and reduce false positives.
    """
    suspicious = [r for r in file_results
                  if r.get("verdict") in ("SUSPICIOUS", "TROJAN_DETECTED")]

    if not suspicious:
        return {
            "cross_reference_verdict": "PROJECT_LIKELY_CLEAN",
            "trojans_found": 0,
            "consolidated_findings": [],
            "summary": "No suspicious patterns detected across any files."
        }

    # Build a summary of all findings for cross-reference
    findings_summary = []
    for r in suspicious:
        for f in r.get("findings", []):
            findings_summary.append({
                "file": r["file"],
                "type": f.get("type", "unknown"),
                "confidence": f.get("confidence", "UNKNOWN"),
                "lines": f.get("lines", "?"),
                "description": f.get("description", "")[:200]
            })

    user_msg = (
        f"You are performing a cross-reference analysis of suspected hardware "
        f"Trojans found in the '{os.path.basename(project_dir)}' project.\n\n"
        f"Individual file analysis found {len(findings_summary)} suspicious "
        f"patterns across {len(suspicious)} files:\n\n"
        f"```json\n{json.dumps(findings_summary, indent=2)}\n```\n\n"
        f"Please:\n"
        f"1. Consolidate related findings that form a single multi-file Trojan\n"
        f"2. Eliminate likely false positives (benign patterns misidentified)\n"
        f"3. Rank confirmed Trojans by severity\n"
        f"4. For each confirmed Trojan, provide the exact file(s) and line ranges\n\n"
        f"Respond in JSON format:\n"
        f'{{"trojans_found": N, "consolidated_findings": [...], "false_positives": [...], "summary": "..."}}'
        f"\n\nReturn ONLY valid JSON."
    )

    try:
        response = client.messages.create(
            model=model,
            max_tokens=4096,
            system="You are a hardware security analyst consolidating Trojan detection results. Be precise about file names and line numbers. Return only valid JSON.",
            messages=[{"role": "user", "content": user_msg}],
        )
        raw_text = response.content[0].text.strip()
        if raw_text.startswith("```"):
            raw_text = raw_text.split("```")[1]
            if raw_text.startswith("json"):
                raw_text = raw_text[4:]
        return json.loads(raw_text)
    except Exception as e:
        return {
            "cross_reference_verdict": "CROSS_REF_ERROR",
            "error": str(e),
            "summary": "Cross-reference analysis failed."
        }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="AI-powered Hardware Trojan Detection (HOST 2026 AHA Challenge)"
    )
    parser.add_argument("project_dir", help="Path to the project directory to analyze")
    parser.add_argument("--api-key", default=os.environ.get("ANTHROPIC_API_KEY", ""),
                        help="Anthropic API key (or set ANTHROPIC_API_KEY env var)")
    parser.add_argument("--model", default=DEFAULT_MODEL,
                        help=f"Model to use (default: {DEFAULT_MODEL})")
    parser.add_argument("--output", default=None,
                        help="Output JSON file (default: <project>_report.json)")
    parser.add_argument("--skip-cross-ref", action="store_true",
                        help="Skip cross-reference analysis pass")
    args = parser.parse_args()

    if not args.api_key:
        print("ERROR: No API key. Set ANTHROPIC_API_KEY or use --api-key.")
        sys.exit(1)

    project_dir = os.path.abspath(args.project_dir)
    if not os.path.isdir(project_dir):
        print(f"ERROR: '{project_dir}' is not a directory.")
        sys.exit(1)

    project_name = os.path.basename(project_dir)
    output_file = args.output or f"{project_name}_report.json"

    print(f"=" * 60)
    print(f"  AHA Trojan Detector — Analyzing: {project_name}")
    print(f"  Model: {args.model}")
    print(f"=" * 60)

    # Find RTL files
    rtl_files = find_rtl_files(project_dir)
    if not rtl_files:
        print(f"ERROR: No RTL files found in '{project_dir}'")
        sys.exit(1)

    print(f"\nFound {len(rtl_files)} RTL files to analyze:")
    for f in rtl_files:
        print(f"  - {os.path.relpath(f, project_dir)}")

    # Initialize API client
    client = anthropic.Anthropic(api_key=args.api_key)

    # Phase 1: Per-file analysis
    print(f"\n{'─' * 40}")
    print("Phase 1: Per-File Analysis")
    print(f"{'─' * 40}")

    file_results = []
    for i, filepath in enumerate(rtl_files, 1):
        fname = os.path.basename(filepath)
        print(f"\n[{i}/{len(rtl_files)}] Analyzing {fname}...", end=" ", flush=True)

        result = analyze_file(client, args.model, filepath)
        file_results.append(result)

        verdict = result.get("verdict", "UNKNOWN")
        n_findings = len(result.get("findings", []))
        emoji = {"CLEAN": "✓", "SUSPICIOUS": "⚠", "TROJAN_DETECTED": "✗"}.get(verdict, "?")
        print(f"{emoji} {verdict} ({n_findings} findings)")

        if n_findings > 0:
            for f in result["findings"]:
                print(f"     [{f.get('confidence','?')}] {f.get('type','?')}: "
                      f"lines {f.get('lines','?')}")

        # Rate limiting
        time.sleep(1)

    # Phase 2: Cross-reference
    cross_ref = {}
    if not args.skip_cross_ref:
        print(f"\n{'─' * 40}")
        print("Phase 2: Cross-Reference Analysis")
        print(f"{'─' * 40}")
        cross_ref = cross_reference_analysis(client, args.model, project_dir, file_results)
        trojans_found = cross_ref.get("trojans_found", 0)
        print(f"\nConsolidated result: {trojans_found} Trojan(s) identified")

    # Build final report
    report = {
        "project": project_name,
        "project_path": project_dir,
        "model": args.model,
        "files_analyzed": len(rtl_files),
        "per_file_results": file_results,
        "cross_reference": cross_ref,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime())
    }

    with open(output_file, "w") as f:
        json.dump(report, f, indent=2)

    print(f"\n{'=' * 60}")
    print(f"  Report saved to: {output_file}")
    print(f"{'=' * 60}")

    # Print summary
    total_trojans = sum(1 for r in file_results
                        if r.get("verdict") == "TROJAN_DETECTED")
    total_suspicious = sum(1 for r in file_results
                           if r.get("verdict") == "SUSPICIOUS")
    total_clean = sum(1 for r in file_results
                      if r.get("verdict") == "CLEAN")

    print(f"\nSummary:")
    print(f"  Clean files:         {total_clean}")
    print(f"  Suspicious files:    {total_suspicious}")
    print(f"  Trojan-detected:     {total_trojans}")

    return 0 if total_trojans == 0 and total_suspicious == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
