# ***AHB Direct Access Memory Controller (DMAC)***

## **Hardware DMA Controller (SystemVerilog Implementation)**  

> Efficient, configurable AMBA-AHB compliant DMA engine supporting burst/block transfers and CPU offloading for high-performance embedded systems.
 
🗓️  *Last updated: August 29, 2025* 
© 2025 **Maktab-e-Digital Systems Lahore**.  
Licensed under the Apache 2.0 License.

---

## Designed and Verified By:
- [Muhammad Mouzzam](https://github.com/MuhammadMouzzam)
- [Danish Hassan](https://github.com/Danish-Hassann)


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

📖 [Documentation](https://systolic-mac.readthedocs.io/en/latest/)