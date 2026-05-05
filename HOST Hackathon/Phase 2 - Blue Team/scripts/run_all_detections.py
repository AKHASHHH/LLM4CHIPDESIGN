#!/usr/bin/env python3
"""
run_all_detections.py — Batch runner for the Blue Team detection pipeline.

Runs detect_trojans.py on every project in the blue-team_release directory
and produces a consolidated summary.

Usage:
    python3 run_all_detections.py <blue_team_dir> [--api-key KEY]

Example:
    python3 run_all_detections.py ./blue-team_release/ --api-key sk-ant-...
"""

import os
import sys
import json
import glob
import argparse
import subprocess
import time
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Batch Trojan detection runner")
    parser.add_argument("blue_team_dir", help="Path to blue-team_release directory")
    parser.add_argument("--api-key", default=os.environ.get("ANTHROPIC_API_KEY", ""),
                        help="Anthropic API key")
    parser.add_argument("--model", default="claude-sonnet-4-20250514")
    parser.add_argument("--output-dir", default="./detection_reports/")
    args = parser.parse_args()

    if not args.api_key:
        print("ERROR: Set ANTHROPIC_API_KEY or use --api-key")
        sys.exit(1)

    blue_dir = os.path.abspath(args.blue_team_dir)
    out_dir = os.path.abspath(args.output_dir)
    os.makedirs(out_dir, exist_ok=True)

    # Find all project directories
    projects = []
    for design_type in ["aes", "ethmac", "cv32e40p"]:
        design_dir = os.path.join(blue_dir, design_type)
        if not os.path.isdir(design_dir):
            continue
        for proj in sorted(os.listdir(design_dir)):
            proj_path = os.path.join(design_dir, proj)
            if os.path.isdir(proj_path):
                projects.append((design_type, proj, proj_path))

    print(f"Found {len(projects)} projects to analyze")
    print(f"Output directory: {out_dir}\n")

    # Process each project
    all_results = []
    script_dir = os.path.dirname(os.path.abspath(__file__))
    detect_script = os.path.join(script_dir, "detect_trojans.py")

    for i, (design_type, proj_name, proj_path) in enumerate(projects, 1):
        print(f"\n{'=' * 50}")
        print(f"[{i}/{len(projects)}] {design_type}/{proj_name}")
        print(f"{'=' * 50}")

        report_file = os.path.join(out_dir, f"{proj_name}_report.json")

        # Run the detection script
        cmd = [
            sys.executable, detect_script,
            proj_path,
            "--api-key", args.api_key,
            "--model", args.model,
            "--output", report_file
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            print(result.stdout)
            if result.stderr:
                print(f"STDERR: {result.stderr[:500]}")

            # Load the report
            if os.path.exists(report_file):
                with open(report_file) as f:
                    report = json.load(f)
                all_results.append({
                    "project": proj_name,
                    "design_type": design_type,
                    "files_analyzed": report.get("files_analyzed", 0),
                    "trojans_detected": sum(
                        1 for r in report.get("per_file_results", [])
                        if r.get("verdict") == "TROJAN_DETECTED"
                    ),
                    "suspicious": sum(
                        1 for r in report.get("per_file_results", [])
                        if r.get("verdict") == "SUSPICIOUS"
                    ),
                    "findings": [
                        {
                            "file": r.get("file"),
                            "findings": r.get("findings", [])
                        }
                        for r in report.get("per_file_results", [])
                        if r.get("verdict") in ("TROJAN_DETECTED", "SUSPICIOUS")
                    ]
                })
        except subprocess.TimeoutExpired:
            print(f"  TIMEOUT after 600s")
            all_results.append({
                "project": proj_name,
                "design_type": design_type,
                "error": "timeout"
            })
        except Exception as e:
            print(f"  ERROR: {e}")
            all_results.append({
                "project": proj_name,
                "design_type": design_type,
                "error": str(e)
            })

        # Rate limit between projects
        time.sleep(2)

    # Write consolidated summary
    summary_file = os.path.join(out_dir, "consolidated_summary.json")
    with open(summary_file, "w") as f:
        json.dump({
            "total_projects": len(projects),
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S UTC", time.gmtime()),
            "results": all_results
        }, f, indent=2)

    # Print final summary
    print(f"\n{'=' * 60}")
    print("CONSOLIDATED SUMMARY")
    print(f"{'=' * 60}")

    for r in all_results:
        t = r.get("trojans_detected", 0)
        s = r.get("suspicious", 0)
        status = "CLEAN" if t == 0 and s == 0 else f"TROJAN:{t} SUSPICIOUS:{s}"
        print(f"  {r['project']:20s}  {status}")

    infected = [r for r in all_results if r.get("trojans_detected", 0) > 0]
    print(f"\nTotal infected projects: {len(infected)} / {len(projects)}")
    print(f"Summary saved to: {summary_file}")


if __name__ == "__main__":
    main()
