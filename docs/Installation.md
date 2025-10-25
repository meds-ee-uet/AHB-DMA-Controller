# Installation Guide

This guide explains how to install and set up the environment for simulating the **AHB DMA Controller** using **QuestaSim / ModelSim** and **Make**. Follow each step carefully to ensure a smooth setup.

---

## 1. Prerequisites

Before starting, make sure you have the following installed on your system:

| Tool | Purpose | Installation Command (Linux) |
|------|----------|-------------------------------|
| **Git** | For cloning the repository | `sudo apt install git` |
| **Make** | For running build and simulation tasks | `sudo apt install make` |
| **QuestaSim / ModelSim** | For compiling and simulating SystemVerilog code | *(Manual install from Siemens EDA)* |

---

##2. Setup 

```bash
# 1. Clone the repo
git clone https://github.com/meds-ee-uet/AHB-DMA-Controller
cd AHB-DMA-Controller

# 2. Compile the design
make compile

# 3. Run simulation
make simulate

# 4. Analyze Waveforms
make wave
```

---

## 3. Alternative
If you don’t have access to QuestaSim or ModelSim, you can use **[EDA Playground](https://www.edaplayground.com)** to simulate the RTL and testbench online.  
Simply upload the SystemVerilog source files (`code/rtl/` and `code/verif/`) and select **QuestaSim** or **Icarus Verilog** as the simulator.

---
