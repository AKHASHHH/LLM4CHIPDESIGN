# LLM4ChipDesign

A collection of projects exploring the use of Large Language Models in hardware design, verification, and IP protection. Topics covered include LLM-driven Verilog generation, automated testbench creation, formal verification, IP rewriting, and synthesis-guided PPA optimization.

---

## Repository Structure

```
LLM4CHIPDESIGN/
├── ChipChat/                          # LLM-aided Verilog generation via ChipChat
├── AutoChip/                          # Automated iterative Verilog generation
├── ROME Demo/                         # Hierarchical mux design with LLM
├── Veritas/                           # LLM-based formal verification
├── Enhanced LLM Aided Testbench Generation/   # Automated testbench generation
├── LLMPirate/                         # LLM-based IP piracy detection evasion
└── LLM-Based Verilog Adder Generation and Verification Project/  # Adder generation & optimization
```

---

## ChipChat — LLM-Aided Verilog Generation

**Folder:** `ChipChat/`  
**Tool:** ChipChat (GPT-4 based interactive Verilog generation)

Explored LLM-driven hardware design using ChipChat for two example circuits and one extension.

| File | Description |
|---|---|
| `ChipChat_1_binary_to_bcd.ipynb` | Binary-to-BCD converter — ChipChat generation + debugging loop |
| `ChipChat_2_Dice_Roller.ipynb` | Dice roller circuit — iterative prompt refinement |
| `ChipChat_3_binary_to_bcd_extension.ipynb` | Extended BCD converter with clocked output |
| `Test Bench/binary_to_bcd_tb.v` | Testbench for binary-to-BCD verification |
| `Lab Report_ChipChat.pdf` | Full lab report with prompts, outputs, and analysis |

---

## AutoChip — Automated Iterative Verilog Generation

**Folder:** `AutoChip/`  
**Tool:** AutoChip (automated feedback-loop Verilog generator)

Used AutoChip's iterative feedback loop to generate and verify two Verilog designs automatically.

| File | Description |
|---|---|
| `AutoChip_Tutorial.ipynb` | Tutorial walkthrough notebook |
| `binary_to_bcd/AutoChip_binary_to_bcd.ipynb` | Binary-to-BCD via AutoChip |
| `binary_to_bcd/binary_to_bcd.v` | Final generated Verilog |
| `binary_to_bcd/binary_to_bcd_tb.v` | Testbench |
| `dice_roller/AutoChip_dice_roller.ipynb` | Dice roller via AutoChip |
| `dice_roller/dice_roller.v` | Final generated Verilog |
| `dice_roller/dice_roller_tb.v` | Testbench |
| `Lab Report_AutoChip.pdf` | Full lab report |

---

## ROME Demo — Hierarchical LLM-Aided Design

**Folder:** `ROME Demo/`  
**Tool:** DeepSeek / ROME framework  

Designed a hierarchical multiplexer system using LLM assistance, demonstrating submodule decomposition and instantiation.

| File | Description |
|---|---|
| `mux2to1tb.v` | Testbench for 2-to-1 MUX |
| `mux4to1tb.v` | Testbench for 4-to-1 MUX |
| `mux8to1tb.v` | Testbench for 8-to-1 MUX |
| `deepseek/mux2to1.v` | LLM-generated 2-to-1 MUX |
| `deepseek/mux4to1.v` | LLM-generated 4-to-1 MUX (instantiates mux2to1) |
| `deepseek/mux8to1.v` | LLM-generated 8-to-1 MUX (instantiates mux4to1) |
| `deepseek/output.txt` | Raw LLM output log |
| `ROME Report.pdf` | Full lab report |

**Simulation:**
```bash
iverilog -g2012 -o mux2to1_sim mux2to1.v mux2to1tb.v && vvp mux2to1_sim
iverilog -g2012 -o mux4to1_sim mux4to1.v mux2to1.v mux4to1tb.v && vvp mux4to1_sim
iverilog -g2012 -o mux8to1_sim mux8to1.v mux4to1.v mux2to1.v mux8to1tb.v && vvp mux8to1_sim
```

---

## Veritas — LLM-Based Formal Verification

**Folder:** `Veritas/`  
**Tool:** Veritas (LLM-assisted SAT-based equivalence checking)

Ran the Veritas pipeline on two circuits (3-bit adder and 3-bit multiplier) using GPT-4 for formal oracle validation.

| File | Description |
|---|---|
| `Adder/adder_3-bit.v` | 3-bit adder Verilog |
| `Adder/adder_3-bit.bench` | Bench format for SAT solver |
| `Adder/adder_3-bit.cnf` | CNF format |
| `Adder/adder_3-bit_tab.csv` | Truth table / oracle output |
| `Multiplier/multiplier_3-bit.v` | 3-bit multiplier Verilog |
| `Multiplier/multiplier_3-bit.bench` | Bench format |
| `Multiplier/multiplier_3-bit.cnf` | CNF format |
| `Multiplier/multiplier_3-bit_tab.csv` | Truth table / oracle output |
| `Veritas_Report.pdf` | Full lab report with analysis |
| `Veritas_final_presentation.pdf` | Presentation slides |

---

## Enhanced LLM-Aided Testbench Generation

**Folder:** `Enhanced LLM Aided Testbench Generation/`  
**Tool:** GPT-4o via OpenAI API + iverilog

Implemented a 5-step LLM pipeline: natural language description → initial testbench → Python golden model → expected outputs → self-checking final testbench. Run on two tutorial examples (MUX, 4-bit adder) and one custom module (3-bit priority encoder) with bug detection demonstration.

| File | Description |
|---|---|
| `Enhanced_LLM_Aided_Testbench_Generation_ad7252.ipynb` | Main executed notebook |
| `Enhanced LLM-Aided Testbench Report.pdf` | Full report |
| `Outputs/mux2to1.v` | 2-to-1 MUX design |
| `Outputs/mux/testbench_initial.v` | Initial MUX testbench (no checking) |
| `Outputs/mux/testbench_final.v` | Final MUX testbench (with PASS/FAIL) |
| `Outputs/mux/golden_model.py` | Python golden model for MUX |
| `Outputs/adder4bit.v` | 4-bit adder design |
| `Outputs/adder/testbench_final.v` | Final adder testbench |
| `Outputs/priority_encoder_3bit.v` | Custom 3-bit priority encoder |
| `Outputs/priority_encoder_3bit_buggy.v` | Intentionally buggy version for Part IV |
| `Outputs/priority_encoder/testbench_final.v` | Priority encoder testbench |

**Results:**
- MUX: 8/8 tests passing
- 4-bit Adder: 20/20 tests passing  
- Priority Encoder: 11/11 tests passing
- Bug detection: 2 failures caught on buggy DUT, 11/11 after fix

---

## LLMPirate — IP Piracy Detection Evasion

**Folder:** `LLMPirate/`  
**Tool:** GPT-3.5-turbo-16k / GPT-4 via OpenAI API  
**Circuit:** C432 benchmark

Evaluated LLM-based strategies for rewriting hardware IP to evade similarity-based piracy detection (SIM metric). Four strategies tested: direct Verilog rewriting, Boolean format rewriting, divide-and-conquer mapping, and iterative feedback.

| File | Description |
|---|---|
| `LLMPirate.ipynb` | Executed notebook with all 5 tasks and analysis |

**SIM Score Results:**

| Strategy | SIM Score | Functional Equivalence |
|---|---|---|
| Task 1: Direct Verilog Rewriting | 0.22 | Failed |
| Task 2: Boolean Format Rewriting | 0.22 | Failed |
| Task 3: Divide-and-Conquer (no feedback) | 0.25 | Failed |
| Task 4: Divide-and-Conquer (with feedback) | 0.33 | Failed |
| Task 5: Reference Cached Mapping | — | Reference baseline |

---

## LLM-Based Verilog Adder Generation and Verification

**Folder:** `LLM-Based Verilog Adder Generation and Verification Project/`  
**Tool:** GPT-4o via OpenAI API + Yosys + iverilog  
**Selected Adders:** RCA8 (Carry Ripple) and KSA8 (Kogge-Stone)

A three-part project covering LLM-based Verilog generation, testbench simulation, and Yosys-based PPA optimization with iterative LLM feedback.

| File | Description |
|---|---|
| `Verilog_Adder_Project.ipynb` | Full executed notebook |
| `Adder_Project_Report.pdf` | Comprehensive project report |

**Part 1 — Verilog Generation:**
- Natural language descriptions generated for RCA8 and KSA8
- Verilog regenerated from descriptions and compared with golden designs
- RCA8: functionally equivalent; KSA8: connectivity issues in LLM output

**Part 2 — Simulation:**

| Design | Tests | Passed | Notes |
|---|---|---|---|
| RCA8 | 20 | 18 | 2 testbench expected-value errors |
| KSA8 | 20 | 20 | Golden design used (LLM version had connectivity issues) |

**Part 3 — Yosys PPA Optimization:**

| Mode | Baseline | Best Cells | Reduction | Functionally Correct |
|---|---|---|---|---|
| Area (Mode A) | RCA8 (45 cells) | 25 cells | 44% | Partial |
| Delay (Mode B) | KSA8 | 3 cells | ~95% | No |
| Balanced (Mode C) | RCA8 | 2 cells | ~96% | No |

```
adder_project_outputs/
├── rca8/          # RCA8 generated Verilog, testbench, simulation analysis
├── ksa8/          # KSA8 generated Verilog, testbench, simulation analysis
├── yosys/         # Synthesis scripts, equivalence check scripts, constraints
└── optimization/
    ├── mode_a_area/      # 10 candidates, best_adder.v, PPA trajectory, log
    ├── mode_b_delay/     # 10 candidates, best_adder.v, PPA trajectory, log
    └── mode_c_balanced/  # 10 candidates, best_adder.v, PPA trajectory, log
```

---

## Tools Used

| Tool | Purpose |
|---|---|
| ChipChat | Interactive LLM Verilog generation (HW1) |
| AutoChip | Automated iterative Verilog generation (HW2) |
| DeepSeek / ROME | Hierarchical design generation (HW3) |
| Veritas | LLM-assisted formal verification (HW4) |
| GPT-4o (OpenAI API) | Testbench generation, adder generation, optimization (HW5, Project) |
| GPT-3.5-turbo-16k | IP rewriting experiments (HW6) |
| iverilog / vvp | RTL simulation |
| Yosys | Logic synthesis and equivalence checking |

---

## Notes

- API keys are not included in any notebook. Insert your OpenAI API key in the designated cell before running.
- All notebooks are designed to run top-to-bottom in Google Colab.
- Simulation commands use `iverilog -g2012` for SystemVerilog compatibility.
