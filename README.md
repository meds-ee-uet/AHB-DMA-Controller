# ***AHB Direct Access Memory Controller (DMAC)***

## **Table of Contents:**
- [Introduction](#introduction)
- [Specifications](#specifications)
- [DMAC](#dmac)
  - [Block Diagram/Pinout](#block-diagrampinout)
  - [Signals](#signals)
    - [Slave Interface](#slave-interface)
    - [Request and Response Interface](#request-and-response-interface)
    - [Control and Interrupt Interface](#control-and-interrupt-interface)
    - [Master Interface](#master-interface)
  - [Working](#working)
- [DMAC Channel](#dmac-channel)
  - [Description](#description)
  - [Operation](#operation)
  - [Configuration](#configuration)
  - [Start Condition](#start-condition)
  - [Data Transfer](#completion)
  - [Registers](#registers)

## **Introduction**
Direct Memory Access Controller is used to allow the peripherals to directly transfer data to their required destination i.e. Memory or another peripheral without disrupting the processor. This saves the processor from handling lenghty transfers because when a CPU handles data transfers, it remains blocked and can't perform instructions. This transfer can take many cycles so to avoid this, the transfer is handed over to the DMAC along with the control of the Bus. DMAC handles the transfer while the CPU can deal with other tasks and instructions. A DMAC has two types of transfers:
- Burst Transfer
- Single Transfer

In a Burst Transfer, data is buffered in a FIFO untill burst size is reached and then transfered one-by-one untill the FIFO is empty.

## **Specifications**
- Number of Channels: 2
- Fixed Priority Channels
  - Highest priority: `Channel 1`
  - Lowest priortity: `Channel 2`
- Maximum Burst Transfer Capability: `16 beats`
- Highest priority to `DmacReq[1]` Request - Assigned `Channel 1`
- FIFO depth in Each Channel: 16 words
- Supported Peripherals/Slaves: 2
- Capable of Burst and Single transfer
- Slave Interface: For DMAC Configuration
  - 4 32-bit Registers:
    - Control Register - `Ctrl_Reg `
    - Size Register - `Size_Reg`
    - Source Address Register -  `SAddr_Reg`
    - Destination Address Register - `DAddr_Reg`
  - Registers are memory mapped. Offsets are as follows:
    - `SAddr_Reg`: `0x4`
    - `DAddr_Reg`: `0x8`
    - `Size_Reg`: `0x0`
    - `Ctrl_Reg`: `0xC`
- Request and Response Interface: For peripherals

# **DMAC**

### **Block Diagram/Pinout**
<div align='center'>
<img width=700px height=550px src='docs/dmac_pinout.png'>
</div>

### **Signals:**
#### ***Slave Interface***
|Signals|Type|Purpose|
|-------|----|-------|
|HWData|Input|Data to be processed/stored by the slave interface|
|HAddr|Input|Address to store data in slave|
|HSel|Input|Tells the Slave that it's been selected as slave for a transaction|
|Write|Input|Tells the nature of the transfer|
|STrans|Input|Tells the state of the current request on the bus (Encodings: Idle, Busy, Seq, Non-Seq)|
|HReadyOut|Output|Signals to master that the transfer is complete|
|S_HResp|Output|Tells master if the transfer was successful or not|

#### ***Request and Response Interface***
|Signals|Type|Purpose|
|-------|----|-------|
|DmacReq|Input|Each bit indicates a request from each peripheral|
|ReqAck|Output|Request Acknowledgement Signals to each peripheral|

#### ***Control and Interrupt Interface***
|Signals|Type|Purpose|
|-------|----|-------|
|Hold|Output|Signals CPU to stop and configure the DMAC Slave|
|Interrupt|Output|Signals to CPU that transfer is complete|

#### ***Master Interface***
|Signals|Type|Purpose|
|-------|----|-------|
|Bus_Req|Output|Requests Bus' Arbiter to become Bus Master (Remains asserted until Bus_Grant is asserted)|
|Bus_Grant|Input|Signals DMAC that bus access is granted to it|
|MWData|Output|Data to write to Slave as a master|
|MAddress|Output|Address to Slave as a master|
|MTrans|Output|Tells the state of the current transfer Request on bus as a master|
|MWrite|Output|As a master, tells the slave the nature of the transfer Request|
|MRData|Input|Data Read from the Slave|
|HReady|Input|Signals DMAC that the transfer request is complete|
|M_HResp|Input|From slave to master, tells if the transfer was successful or not|

### **Working:**
This DMAC has been designed as to follow a certain pipeline to complete the transfer. The pipeline is as follows:
<div align='center'>
    <img src='docs/DMAC_Pipeline.png'>
</div>

#### **Request from Peripheral**
First of all, peripheral requests for a transfer to DMAC.
1. Priority is given to the `DmacReq[1]` which Enables `Channel 1` to handle the transfer.
2. If both bits of DmacReq are asserted, DMAC ignores `DmacReq[0]` signal and doesn't assert its request acknowledge signal `ReqAck[1]`.
3. `Channel 2` is used for `DmacReq[0]`.

#### **Slave Configuration**
After the Request, DMAC asserts Hold and waits for CPU to configure the Slave Interface. Along with Hold, DMAC also Requests for Bus. Bus Request remains asserted until Bus is granted.
1. The Sequence in which slave registers should be configured are:
   1. `Size_Reg`
   2. `SAddr_Reg`
   3. `DAddr_Reg`
   4. `Ctrl_Reg`
2. Control Register Contains a `c_config` bit which, when asserted, tells the DMAC that its Slave has been configured. `Ctrl Reg` is Reset (to zero) after `irq` is generated by the channel.
3. Slave Gets Configured, i.e. `c_config` signal gets asserted.
4. DMAC waits for Bus Grant.

#### **Enabling Channels**
1. After the DMAC is granted the bus, DMAC asserts the `ReqAck `bit corresponding to the `DmacReq` bit which results in deassertion of `DmacReq` bit by the slave/peripheral.
2. Corresponding to `DmacReq`, the channel is enabled i.e. `Channel 1` is used for `DmacReq[1]` and has the highest priority.Whereas, `Channel 2` is for `DmacReq[0]` bit.

#### **Transfer Completion and Disabling DMAC**
1. After the channel has been enabled, Now the DMAC waits for `irq` which signals transfer completion from the channel's side. During the transfer, it is important to decide which channel should output the data to the master interface. To do that, a mux is used with `con_sel` signal as selector. This `con_sel` is also given to a FlipFlop and the output of the FlipFlop, `new_con_sel` is the input to the controller of the DMAC, which informs which channel was enabled previously. `0` means `channel 1`, `1` means `channel 2`.
2. Once `irq` is asserted, DMAC asserts the `Interrupt` flag to signal the CPU about the completion of transfer, that means the CPU can take the Bus access.

### **DMAC DataPath**
<div align='center'>
  <img src='docs/DMAC_datapath.png'>
</div>

## DMAC Channel
### Description: 
The DMAC (Direct Memory Access Controller) channel is responsible for autonomously transferring data between a source and destination without CPU intervention. It is designed to support both single transfers (one word per transaction) and burst transfers (multiple words per transaction), providing flexibility for various use cases.

Each channel includes a dedicated FIFO buffer, which temporarily holds data during burst operations. Once the data has been successfully transferred, the channel automatically generates an interrupt to notify the CPU that the operation is complete.

### Operation

The DMA channel operates through a **finite state machine (FSM)** that governs the control and flow of data. The following outlines the step-by-step operation:

---

### Configuration
- When a **transfer request** is received from a peripheral, the CPU configures the DMAC by writing to the following registers:
  - `SAddr_Reg`: Source memory address
  - `DAddr_Reg`: Destination memory address
  - `Size_Reg`: Total number of bytes or words to transfer
  - `Ctrl_Reg`: Burst size and other control/configuration bits

---

### Start Condition
- The transfer begins when the **`channel_en`** signal for the selected channel is asserted.
- The FSM transitions from the **IDLE** state to the **ENABLED** state.
- During this transition, the following internal registers are loaded from the previously configured values:
  - `Src_Addr`: Latched source address
  - `Dst_Addr`: Latched destination address
  - `Size_Reg`: Size of the transfer
  - `Burst_Size`: Number of words to be transferred per burst

---

### Data Transfer
- Once enabled:
  - The DMA channel issues a **read request** to the source address and increments the source address.
  - Upon receiving valid data, it stores it in the **FIFO**.
  - Then, a **write request** is issued to the destination address and destination address is incremented.
- In **burst mode**, multiple data items are read in chunks, temporarily buffered in the FIFO, and then written sequentially.
- This process repeats until the **entire configured transfer size** is completed.

---

### Completion
- After the final data word is transferred:
  - The FSM returns to the **IDLE** state.
  - The DMA channel asserts an **interrupt signal** to the CPU to indicate successful completion.

---

### Registers

| Register Name        | Width | Description                                                                 |
|----------------------|-------|-----------------------------------------------------------------------------|
| `Src_Addr`           | 32    | Source memory address                                                       |
| `Dst_Addr`           | 32    | Destination memory address                                                  |
| `Transfer_Size`      | 32    | Total number of words to transfer                                           |
| `Burst_Size`         | 32    | Number of words to be transferred per burst                                 |
| `Decrement_Counter`  | 32    | Tracks the remaining number of data items to be read or written in the current burst. It decrements with each successful transfer and resets to `Burst_Size` at the start of every new read or write burst. |
