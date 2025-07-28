# ***AHB Direct Access Memory Controller (DMAC)***

## **Introduction**
Direct Memory Access Controller is used to allow the peripherals to directly transfer data to their required destination i.e. Memory or another peripheral without disrupting the processor. This saves the processor from handling lenghty transfers because when a CPU handles data transfers, it remains blocked and can't perform instructions. This transfer can take many cycles so to avoid this, the transfer is handed over to the DMAC along with the control of the Bus. DMAC handles the transfer while the CPU can deal with other tasks and instructions. A DMAC has two types of transfers:
- Burst Transfer
- Single Transfer

In a Burst Transfer, data is buffered in a FIFO untill burst size is reached and then transfered one-by-one untill the FIFO is empty.

## **DMAC Pinout**
<div align='center'>
<img width=700px height=550px src='docs/dmac_pinout.png'>
</div>


## **Specifications**
- 

