# Developer Guide
---
# **Verification and Testing**
To verify the DMAC, a Mock AHB Peripheral with a 1024-byte register file (`8x1024`) was designed. Two instances, `source` and `dest`, acted as data source and destination. `source` and `dest` were initialized with random data. All the tests were performed on an AHB Bus. All three request types were tested, with `DmacReq[1]` given priority when asserted. All edge cases passed successfully. The following table shows the test plan we followed:

| Test Case | Description                                                                                                                                                   | Expected Behaviour                                                                                                      | Status |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------ |
| 1         | Verifies DMAC can perform both single-beat and multi-beat transfers correctly. Ensures address incrementing, burst length, and data integrity are maintained. | Data moves correctly for both single and burst modes with proper address increments and no extra bus activity.          | Pass   |
| 2         | Checks handling of transfers starting at non-aligned source/destination addresses.                                                                            | DMAC correctly generates byte enables and transfers valid data without corruption despite unaligned addresses.          | Pass   |
| 3         | Checks for different transfer sizes including multiples of Burst Size.                                                                                        | No. of Bursts = `floor(Transfer Size / Burst Size)`<br>No. of Singles = `Transfer mod Burst Size`                       | Pass   |
| 4         | Covers LEN=0 (no transfer) and LEN=1 (one beat). Confirms DMAC doesn’t misbehave with edge case lengths.                                                      | LEN=0 results in no transfer; LEN=1 transfers exactly one beat without extra activity.                                  | Pass   |
| 5         | Issues consecutive DMA requests without delay. Verifies channel re-initialization and seamless transition between transfers.                                  | DMAC handles consecutive requests smoothly, re-initializing correctly and transferring without data loss or overlap.    | Pass   |
| 6         | Forces DMAC to release bus ownership during an active burst. Ensures it resumes cleanly without data corruption.                                              | DMAC releases bus ownership safely and resumes the burst later without corruption or protocol violation.                | Pass   |
| 7         | Injects random HREADY stalls on the AHB bus. Confirms DMAC handles delays gracefully without data loss.                                                       | DMAC stalls gracefully during HREADY low cycles and continues when ready, preserving order and data integrity.          | Pass   |
| 8         | Runs transfers with different HSIZE values (byte, halfword, word). Verifies correct bus signaling and data alignment.                                         | Transfers of different sizes use correct bus signaling, align data properly, and complete without errors using strobes. | Pass   |

---

## **Waveforms**

### Dmac Configuration 
Once the DMAC receives the Bus_Grant, the peripheral begins configuring the DMAC. A base address corresponding to that peripheral is already stored in the `peri_addr_reg`, and from this base, four specific offsets are used to configure the `SAddr_Reg`, `DAddr_Reg`, `Size_Reg`, and `Ctrl_Reg`. To better reflect realistic peripheral behavior, the peripheral introduces an intentional delay of two cycles while providing these configuration values. After this delay, the DMAC captures the data and stores it into the respective registers.

<div align='center'>
<img src='../TestBenchs/Config_Sim.jpg'>
</div>

---

### Dmac Reading 
The DMAC reads data from the peripheral in bursts of 4, while the peripheral introduces an intentional 2-clock-cycle wait before providing valid data.
<div align='center'>
<img src='../TestBenchs/Read_Sim.jpg'>
</div>

---

### Dmac Writing 
Here the DMAC writes data to the peripheral in bursts of 4, with the peripheral introducing an intentional 2-clock-cycle wait before accepting each write.
<div align='center'>
<img src='../TestBenchs/Write_Sim.jpg'>
</div>

---


### DmacReq - 01
In this image, the `DmacReq` signal was `01`, so `Channel 2` was enabled and Interrupt was generated transfer was complete. The last 2 `word` as seen in the image are transferred via single word transfer while the remaining in bursts. `HSize` was kept as `byte` and the address offset was `3`.
<div align='center'>
<img src='../TestBenchs/tb_01req.png'>
</div>
We can see for reading, address of 1st peripheral (i.e. `0x0000xxxx`) is sent on the bus while for writing, address of 2nd peripheral is sent.

---

### DmacReq - 10
Here, `HSize` was kept as `halfword` and the address offset was kept at `2`.
<div align='center'>
<img src='../TestBenchs/tb_10req.png'>
</div>
We can see for reading, address of 2nd peripheral (i.e. `0x1000xxxx`) is sent on the bus while for writing, address of 1st peripheral is sent.

---

### DmacReq - 11
In this case, `HSize` was kept as `word` and the address offset was kept at `0`.
<div align='center'>
<img src='../TestBenchs/tb_11req.png'>
</div>
We can see for reading, address of 2nd peripheral (i.e. `0x1000xxxx`) is sent on the bus while for writing, address of 1st peripheral is sent.

### Summary of all 3 cases
All bytes were successfully transferred as only those bytes were tested which were valid depending upon the `MWSTRB` signal. If a byte was Invalid, **Invalid Byte** was displayed.
<div style="display: flex; justify-content: center; align-items: center; gap: 20px;">
  <figure style="text-align: center;">
    <img width="225px" height="250px" src="../TestCases_Checks/tc_01req.png" alt="DmacReq = 01">
    <figcaption><b>Figure 1:</b> DmacReq = 01</figcaption>
  </figure>
  <figure style="text-align: center;">
    <img width="225px" height="250px" src="../TestCases_Checks/tc_10req.png" alt="DmacReq = 10">
    <figcaption><b>Figure 2:</b> DmacReq = 10</figcaption>
  </figure>
  <figure style="text-align: center;">
    <img width="225px" height="250px" src="../TestCases_Checks/tc_11req.png" alt="DmacReq = 11">
    <figcaption><b>Figure 3:</b> DmacReq = 11</figcaption>
  </figure>
</div>

---

### Bus Grant Deasserted mid transfer
In this case, `HSize` is still `word` encoded and offset is `0` but bus grant was deasserted mid transfer for 2 clock edges.
Note: This test was not performed on AHB bus, in order for us to easily manipulate bus grant.
<div align='center'>
<img src='../TestBenchs/bg_da.png'>
</div>
Even though DMAC was removed as bus master, Transfer resumed after DMAC was again given the access to bus and stopped when transfer was complete.
<div align='center'>
<img width=300px height=334px src='../TestCases_Checks/bg_da_tc.png'>
</div>