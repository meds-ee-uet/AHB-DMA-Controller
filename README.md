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
  - [Working Pipeline](#working-pipeline)
    - [Request from Peripheral](#request-from-peripheral)
    - [Slave Configuration](#slave-configuration)
    - [Enabling Channels](#enabling-channels)
    - [Transfer Completion and Disabling DMAC](#transfer-completion-and-disabling-dmac)
  - [DMAC Datapath](#dmac-datapath)
  - [DMAC Controller](#dmac-controller)
    - [Internal Signals](#internal-signals)
    - [State Transition Graph](#state-transition-graph)
    - [States](#states)
- [DMAC Channel](#dmac-channel)
  - [Pinout](#pinout)
  - [Signals](#signals-1)
  - [Description](#description)
  - [Working Pipeline](#working-pipeline-1)
    - [Operation](#operation)
    - [Configuration](#configuration)
    - [Start Condition](#start-condition)
    - [Data Transfer](#completion)
  - [Registers](#registers)
  - [DMAC Channel Datapath](#dmac-channel-datapath)
  - [DMAC Channel Controller](#dmac-channel-controller)
    - [Internal Signals](#internal-signals-1)
    - [State Transition Graph](#state-transition-graph-1)
    - [States](#states-1)

## **Introduction**
A Direct Memory Access Controller (DMAC) is a hardware module designed to facilitate efficient data transfers between memory and peripherals, or between two peripheral devices, without heavily involving the processor (CPU). This mechanism allows data movement to occur in the background, freeing the CPU to execute other instructions or handle high-priority tasks.

When the CPU is tasked with handling data transfers directly, it typically becomes blocked — it must wait and perform each individual read and write operation. This process consumes valuable processor cycles and significantly hampers overall system performance, especially when dealing with large volumes of data. To alleviate this bottleneck, the DMAC takes over the responsibility of managing the transfer and temporarily gains control of the system bus.

Once granted control, the DMAC autonomously carries out the data transfer between source and destination addresses using its own internal logic. After completing the transfer, it relinquishes the bus back to the CPU, generating an interrupt to signal completion.

***Transfer Types:*** DMAC supports two fundamental types of data transfers:

- **Burst Transfer**
In burst mode, the DMAC collects data into a FIFO buffer. Once the buffer reaches the defined burst size, transfer starts. Data is sent in a continuous sequence without interruption. This reduces bus arbitration and improves throughput. Best suited for large data blocks or high-speed devices. However, it can monopolize the bus during the burst. Careful arbitration is needed in multi-master systems.

- **Single Transfer**
In single mode, one data item is moved at a time. It is used when a peripheral only has 1 word to transfer. Ideal for low-latency or real-time applications. Overhead is higher due to repeated bus arbitration. More predictable and fair in shared-bus environments. Recommended for small or sporadic data transfers.




## **Specifications**
- Number of Channels: 2
- Fixed Priority Channels
  - Highest priority: `Channel 1`
  - Lowest priortity: `Channel 2`
- Maximum Burst Transfer Capability: `16 beats`
- Endianness: `Little-Endian`
- Invariance: `byte invariant`
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
- If CPU asks for bus access, burst transfer is halted until bus access is granted again.

## ***DMAC***

### **Block Diagram/Pinout**
<div align='center'>
<img width=700px height=500px src='docs/DMAC_pinout.png'>
</div>

### **Signals:**
#### ***Slave Interface***
|Signals|Type|Width|Purpose|
|-------|----|-----|-------|
|`HWData`|Input|32|Data to be processed/stored by the slave interface|
|`HAddr`|Input|32|Address to store data in slave|
|`HSel`|Input|1|Tells the Slave that it's been selected as slave for a transaction|
|`Write`|Input|1|Tells the nature of the transfer|
|`STrans`|Input|2|Tells the state of the current request on the bus (Encodings: Idle, Busy, Seq, Non-Seq)|
|`HReadyOut`|Output|1|Signals to master that the transfer is complete|
|`S_HResp`|Output|2|Tells master if the transfer was successful or not|

#### ***Request and Response Interface***
|`Signals`|Type|Width|Purpose|
|-------|----|-------|-------|
|`DmacReq`|Input|2|Each bit indicates a request from each peripheral|
|`ReqAck`|Output|2|Request Acknowledgement Signals to each peripheral|

#### ***Control and Interrupt Interface***
|Signals|Type|Width|Purpose|
|-------|----|-----|-------|
|`Hold`|Output|1|Signals CPU to stop and configure the DMAC Slave|
|`Interrupt`|Output|1|Signals to CPU that transfer is complete|

#### ***Master Interface***
|Signals|Type|Width|Purpose|
|-------|----|-----|-------|
|`Bus_Req`|Output|1|Requests Bus' Arbiter to become Bus Master (Remains asserted until Bus_Grant is asserted)|
|`Bus_Grant`|Input|1|Signals DMAC that bus access is granted to it|
|`MWData`|Output|32|Data to write to Slave as a master|
|`MAddress`|Output|32|Address to Slave as a master|
|`MTrans`|Output|2|Tells the state of the current transfer Request on bus as a master|
|`MWrite`|Output|1|As a master, tells the slave the nature of the transfer Request|
|`MRData`|Input|32|Data Read from the Slave|
|`HReady`|Input|1|Signals DMAC that the transfer request is complete|
|`M_HResp`|Input|2|From slave to master, tells if the transfer was successful or not|
|`MHSize`|Output|2|Tells the size of the single transfer i.e. `byte`, `halfword` or `word`|
|`MWSTRB`|Output|4|`4` bit signal, each bit represents a valid `byte` in a `word`|

### **Working Pipeline:**
This DMAC has been designed as to follow a certain pipeline to complete the transfer. The pipeline is as follows:
<div align='center'>
    <img src='docs/DMAC_Pipeline.png'>
</div>

#### **Request from Peripheral**
First of all, peripheral requests for a transfer to DMAC.
1. Priority is given to the `DmacReq[1]` which Enables `Channel 1` to handle the transfer.
2. If both bits of DmacReq are asserted, DMAC ignores `DmacReq[0]` signal and doesn't assert its request acknowledge signal `ReqAck[1]`.
3. `Channel 2` is used for `DmacReq[0]`.

---

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

---

#### **Enabling Channels**
1. After the DMAC is granted the bus, DMAC asserts the `ReqAck `bit corresponding to the `DmacReq` bit which results in deassertion of `DmacReq` bit by the slave/peripheral.
2. Corresponding to `DmacReq`, the channel is enabled i.e. `Channel 1` is used for `DmacReq[1]` and has the highest priority.Whereas, `Channel 2` is for `DmacReq[0]` bit.

---

#### **Transfer Completion and Disabling DMAC**
1. After the channel has been enabled, Now the DMAC waits for `irq` which signals transfer completion from the channel's side. During the transfer, it is important to decide which channel should output the data to the master interface. To do that, a mux is used with `con_sel` signal as selector. This `con_sel` is also given to a FlipFlop and the output of the FlipFlop, `new_con_sel` is the input to the controller of the DMAC, which informs which channel was enabled previously. `0` means `channel 1`, `1` means `channel 2`.
2. Once `irq` is asserted, DMAC asserts the `Interrupt` flag to signal the CPU about the completion of transfer, that means the CPU can take the Bus access.

---

### **DMAC DataPath**
<div align='center'>
  <img src='docs/DMAC_datapath.png'>
</div>

### **DMAC Controller**
#### **Internal Signals**
|Signal|Type|Purpose|
|------|----|-------|
|`irq`|Input|An `OR` of `irq_1` and `irq_2` of both channels|
|`con_sel`|Output|Selector of a `mux` to output the data from the enabled channel|
|`new_con_sel`|Input|Returning from a FlipFlop used to store the previous value of `con_sel` signal|
|`Bus_Req`|Output|Signal to request access of the bus from the bus' Interconnect|
|`hold`|Output|Used to signal the CPU to configure the Slave Interface|
|`Interrupt`|Output|Signals the Completion of the current transfer|
|`c_config`|Input|When asserted, tells that the slave interface has been configured|
|`con_en`|Output|Enable signal for the FlipFlop to store `con_sel`|
|`channel_en_1`|Output|Enable for `Channel 1`|
|`channel_en_2`|Output|Enable for `Channel 2`|
|`Bus_Grant`|Input|Signals that the bus Request was acknowledged and bus access has been transferred|
|`DmacReq`|Input|Each bit representes a request to DMAC for data transfer from each peripheral|
|`ReqAck`|Output|Each bit is an Request Ackhnowledgment signal for each peripheral|
#### **State Transition Graph:**
<div align='center'>
  <img src='docs/DMAC_main_stg.png'>
</div>

#### **States:**
|State|Purpose|
|-----|-------|
|`Idle`|The which indicates the DMAC is not handling any Requests|
|`MSB Req`|State indicating that the peripheral with a higher priority has made the request|
|`LSB`|State indicating that the peripheral with a lower priority has made the request|
|`Wait`|A wait state until the transfer is complete|

## **DMAC Channel**
### **Pinout:**
<div align='center'>
  <img src='docs/DMAC_Channel_Pinout.png'>
</div>

### **Signals:**
| Signals            | Type   | Width | Purpose                                                                 |
|--------------------|--------|--------|-------------------------------------------------------------------------|
| `Channel_en`       | Input  | 1      | Enables the channel.                                                    |
| `Source_Addr`      | Input  | 32     | The starting memory location from which data is read during a transfer. |
| `Destination_Addr` | Input  | 32     | The starting memory location to which data will be written during a transfer. |
| `Transfer_Size`    | Input  | 32     | Specifies the total number of words to transfer.                        |
| `Burst_Size`       | Input  | 4      | Indicates the number of beats in a burst transfer.                      |
| `RData`            | Input  | 32     | Data read from the slave during a DMA read operation.                   |
| `ReadyIn`          | Input  | 1      | Indicates whether the processor is ready to send the data.              |
| `HSize`            | Input  | 2     | Specifies the size of each transfer: byte (00), halfword (01), word (10). |
| `Irq`              | Output | 1      | Interrupt signal raised when the DMA transfer is complete.              |
| `WData`            | Output | 32     | Data to be written to the destination address during a DMA write operation. |
| `Ready_Out`        | Output | 1      | Indicates that the DMA controller is ready to perform a transfer. |
| `HAddr`            | Output | 32     | Address sent to the AHB Bus for the read/write operation.   |
| `Write`            | Output | 1      | Indicate write operation when asserted and read when 0. |
| `Burst_Size`       | Output | 4      | Indicate number of beats in a burst transfer.                          |
| `HTrans`           | Output | 2      | Transfer type on the AHB bus (IDLE,BUSY NONSEQ, SEQ).                       |
| `MHSize`           | Output | 2      |  Specifies the size of each transfer: byte (00), halfword (01), word (10).        |
| `MWSTRB`           | Output | 4      |Indicates which byte(s) are active during a write. |


### Description: 
The DMAC (Direct Memory Access Controller) channel is responsible for autonomously transferring data between a source and destination without CPU intervention. It is designed to support both single transfers (one word per transaction) and burst transfers (multiple words per transaction), providing flexibility for various use cases.

Each channel includes a dedicated FIFO buffer, which temporarily holds data during burst operations. Once the data has been successfully transferred, the channel automatically generates an interrupt to notify the CPU that the operation is complete.

### Working Pipeline: 

<div align='center'>
  <img src='docs/DMAC_Channel_Pipeline.png'>
</div>

#### Operation

The DMA channel operates through a **finite state machine (FSM)** that governs the control and flow of data. The following outlines the step-by-step operation:

---

#### Configuration
- When a **transfer request** is received from a peripheral, the CPU configures the DMAC by writing to the following registers:
  - `SAddr_Reg`: Source memory address
  - `DAddr_Reg`: Destination memory address
  - `Size_Reg`: Total number of bytes or words to transfer
  - `Ctrl_Reg`: Burst size and other control/configuration bits

---

#### Start Condition
- The transfer begins when the **`channel_en`** signal for the selected channel is asserted.
- The FSM transitions from the **IDLE** state to the **ENABLED** state.
- During this transition, the following internal registers are loaded from the previously configured values:
  - `Src_Addr`: Latched source address
  - `Dst_Addr`: Latched destination address
  - `Size_Reg`: Size of the transfer
  - `Burst_Size`: Number of words to be transferred per burst

---

#### Data Transfer
- Once enabled:
  - The DMA channel issues a **read request** to the source address and increments the source address.
  - Upon receiving valid data, it stores it in the **FIFO**.
  - Then, a **write request** is issued to the destination address and destination address is incremented.
- In **burst mode**, multiple data items are read in chunks, temporarily buffered in the FIFO, and then written sequentially.
- This process repeats until the **entire configured transfer size** is completed.
- If the `transfer_size` is an exact multiple of the `burst_size`, the entire data is transferred using burst transfers. Otherwise, the largest possible number of full bursts are used, and the remaining data (`transfer_size % burst_size`) is transferred using single transfers.
- **Writing Strobe Signal - MWSTRB:** During **writing**, to indicate which `byte` (when `HSize` = `byte`) or which `halfword` (when `HSize` = `halfword`) is valid in the word being transferred, `MWSTRB` signal is used.
Here's a table to link each combination of `MWSTRB` to the bytes of a word, indicating which one is valid.

|Data Size|Address Offset|MWSTRB|HWDATA[31:24]|HWDATA[23:16]|HWDATA[15:8]|HWDATA[7:0]|
|----|-----|-----|-----|-----|----|-----|
|`word`|`0`|`1111`|Valid|Valid|Valid|Valid|
|`halfword`|`0`|`0011`|||Valid|Valid|
|`halfword`|`2`|`1100`|Valid|Valid|||
|`byte`|`0`|`0001`||||Valid|
|`byte`|`1`|`0010`|||Valid||
|`byte`|`2`|`0100`||Valid|||
|`byte`|`3`|`1000`|Valid||||

---

#### Completion
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
| `HSize_Reg`  | 2    | Stores the size of transfer: byte (00), halfword (01), word (10). |

### **DMAC Channel DataPath**
<div align='center'>
  <img src='docs/DMAC_Channel_Datapath.png'>
</div>

### **DMAC Channel Controller**

#### **Internal Signals**
| Signal           | Type   | Purpose                                                                 |
|------------------|--------|-------------------------------------------------------------------------
| `channel_en`     | Input  | Enables the currently selected DMA channel.                             |
| `readyIn`        | Input  | Indicates whether the source is ready to provide data.                  |
| `fifo_full`      | Input  | Indicates the internal FIFO is full and cannot accept more data.        |
| `fifo_empty`     | Input  | Indicates the internal FIFO is empty and no data is available to send.  |
| `bsz`            | Input  | Asserted when decrement counter stores 0, indicating current read/write burst is done.     |
| `tslb`           | Input  | Asserted when transfer size is less than burst size, used to indicate that the next transfers will be single transfers.            |
| `tsz`            | Input  | Asserted when transfer size reaches 0.                   |
| `M_HResp`        | Input  | Response from Dmac indicating transfer success or failure.        |
| `irq`            | Output | Interrupt raised when the DMA transfer is complete.                     |
| `HTrans`         | Output | Specifies transfer type (IDLE, BUSY, NONSEQ, SEQ).                    |
| `write`          | Output | Indicates direction of transfer: 1 for write, 0 for read.               |
| `b_sel`          | Output | Selects Burst_Size = 1 for single transfer when asserted.                   |
| `d_sel`          | Output | Selects starting destination address when asserted and incremented destination address when 0.                      |
| `t_sel`          | Output | Selects starting Transfer Size when asserted and Decremented Transfer Size (After a single or burst transfer) when 0.                    |
| `s_sel`          | Output | Selects starting Source address when asserted and incremented Source address when 0                           |
| `h_sel`          | Output | Selects Destination Address to put on AHB Bus during write operation when asserted and Source Address Otherwise.                         |
| `d_en`           | Output | Enable for `Dst_Addr` register.                         |
| `s_en`           | Output | Enable for `Src_Addr` register.                              |
| `ts_en`          | Output | Enable for `Transfer_Size` register.                        |
| `burst_en`       | Output | Enable for `Burst_Size` register.                                           |
| `count_en`       | Output | Enable for `Decrement_Counter` register.                   |
| `sz_en`          | Output | Enable for `HSize` register.                                      |
| `rd_en`          | Output | Read enable signal for reading data from FIFO.                   |
| `wr_en`          | Output | Write enable signal for writing data to FIFO.               |
| `trigger`        | Output | Puts the data output from FIFO on AHB bus.             

#### **State Transition Graph:**
<div align='center'>
  <img src='docs/DMAC_Channel_Controller.png'>
</div>          |

#### **States:**
|State|Purpose|
|-----|-------|
|`Disabled`|Indicates the DMAC Channel is not handling any Requests.|
|`Enabled`|State indicating that the internal registers of the DMAC Channel are configured.|
|`Read Wait`|State indicating that a read operation is going on.|
|`Hold Read`|"State indicating that the bus grant was given to the processor during a read operation, and the state remains active until the DMA channel is re-enabled.|
|`Write Wait`|State indicating that a write operation is going on.|
|`Hold Write`|"State indicating that the bus grant was given to the processor during a write operation, and the state remains active until the DMA channel is re-enabled.|