# **User Guide**

---

### **DMAC Configuration**

- Once the bus is granted, the DMAC uses **`peri_addr_reg`** (peripheral base address) + register offsets to generate read requests.  
  - Base address for **Peripheral 1** → `32'h1000_0000`  
  - Base address for **Peripheral 2** → `32'h0000_0000`  
  - Register offsets:  
    - **Source Address (Src)** → `32'h0000_00A0`  
    - **Destination Address (Dst)** → `32'h0000_00A4`  
    - **Transfer Size** → `32'h0000_00A8`  
    - **Control Register** → `32'h0000_00AC`  

- All peripherals must implement identical offsets for uniform access.  
- During configuration, `con_sel = 2`, sending requests directly to the master interface (bypassing channels).  
- Data read is stored into DMAC configuration registers (each with a wait state):  
  - **Wait for Src** → `SAddr_Reg`  
  - **Wait for Dst** → `DAddr_Reg`  
  - **Wait for Trans. Size** → `Size_Reg`  
  - **Wait for Ctrl** → `Ctrl_Reg`  

#### **Configuration Sequence (Strictly Ordered)**
1. `SAddr_Reg`  
2. `DAddr_Reg`  
3. `Size_Reg`  
4. `Ctrl_Reg`  


## **Enabling Channels**

- After configuration, **`DmacReq_Reg`** determines which channel to enable:  
  - `MSB_Req`: entered when `DmacReq_Reg[1] = 1` → enables **Channel 1**.  
  - `LSB_Req`: entered when `DmacReq_Reg = 01` → enables **Channel 2**.  

- Once enabled, control moves to the **Wait** state, where the DMAC waits for transfer completion.  

- If `Bus_Grant` is deasserted:  
  - DMAC releases the bus, halts transfer, and deasserts channel enable.  
  - Control returns to `MSB_Req` or `LSB_Req` based on **`new_con_sel`** (previously selected channel).  

- DMAC then re-requests the bus and resumes transfer until completion.  


### **Transfer Completion and Disabling DMAC**

1. After enabling a channel, the DMAC waits for `irq` to signal transfer completion.  
   A MUX with `con_sel` selects the channel output, and `con_sel` latched into `new_con_sel` indicates which channel was active (`0` = Channel 1, `1` = Channel 2).  
2. On `irq`, the DMAC asserts **`Interrupt`** to inform the CPU that the transfer is complete and bus access is available.  

---

### **Configuration Options**

#### **Single Transfer**
- `Ctrl_Reg[3:0]` defines the burst size length.  
  Set it to **0** for a **single transfer**.  

#### **Burst Transfer**
- `Ctrl_Reg[3:0]` defines the burst size length.  
  - **1** → Burst of 4  
  - **2** → Burst of 8  
  - **3** → Burst of 16  

---

### **Data Transfer Format**
- `Ctrl_Reg[5:4]` defines the HSize signal.  

| Data Size  | HSize | Address Offset | MWSTRB | HWDATA[31:24] | HWDATA[23:16] | HWDATA[15:8] | HWDATA[7:0] |
| ----------- | ------ | -------------- | ------ | -------------- | -------------- | ------------- | ------------ |
| `word`      | `10`  | `0`            | `1111` | Valid          | Valid          | Valid         | Valid        |
| `halfword`  | `01`  | `0`            | `0011` |                |                | Valid         | Valid        |
| `halfword`  | `01`  | `2`            | `1100` | Valid          | Valid          |               |              |
| `byte`      | `00`  | `0`            | `0001` |                |                |                | Valid        |
| `byte`      | `00`  | `1`            | `0010` |                |                | Valid         |              |
| `byte`      | `00`  | `2`            | `0100` |                | Valid          |               |              |
| `byte`      | `00`  | `3`            | `1000` | Valid          |                |               |              |


---