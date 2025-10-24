# ***AHB Direct Access Memory Controller (DMAC)***

## **Hardware DMA Controller (SystemVerilog Implementation)**  

> Efficient, configurable AMBA-AHB compliant DMA engine supporting burst/block transfers and CPU offloading for high-performance embedded systems.

<img src=./docs/DMAC/DMAC_pinout.png>


## Key Features:
- Fixed Priority Channels
  - Highest priority: `Channel 1`
  - Lowest priortity: `Channel 2`
- Supports 2 Peripherals/Slaves.
- Capable of Burst and Single transfer
- Supports Burst Transfer of maximum `16 beats.`
- Request and Response Interface for peripherals.
- If CPU asks for bus access, burst transfer is halted until bus access is granted again.

## Repository Structure
- [Code](code/)
  - [RTL](code/rtl/)
    - [Mock Peripheral/Buffer](code/rtl/Buffer.sv)
    - [DMAC Module](code/rtl/Dmac.sv)
    - [DMAC Datapath](code/rtl/Dmac_Main_Datapath.sv)
    - [DMAC Controller](code/rtl/Dmac_Main_Ctrl.sv)
    - [DMAC Channel](code/rtl/Dmac_Channel.sv)
    - [DMAC Channel Datapath](code/rtl/Dmac_Channel_Datapath.sv)
    - [DMAC Channel Controller](code/rtl/Dmac_Channel_Ctrl.sv)
    - [FIFO](code/rtl/Fifo_Datapath.sv)
  - [Verification](code/verif/)
    - [DMAC's TestBench](code/verif/Dmac_tb.sv)
    - [DMAC Channel's TestBench](code/verif/Dmac_Channel_tb.sv)
- [Documents and Images](docs/)
- [Makefile](makefile)

---
## Getting Started 

```bash
# Prerequisites: ModelSim & Make installed

# 1. Clone the repo
git clone https://github.com/meds-ee-uet/AHB-DMA-Controller
cd AHB-DMA-Controller

# 2. Compile the design
make compile

# 3. Run simulation
make simulate

# 4. Check Waveforms
make wave
```
## Full Documentation on ReadTheDocs
#### 📖 [Documentation](https://ahb-dma-controller.readthedocs.io/en/latest/)