// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A Basic circular FIFO Implementation. Has 2 pointers, wr_ptr and rd_ptr.
//              And a counter which checks the number of valid data words. Depth of the
//              FIFO is 16 words. When wc_en is 1, data on Data_in is written in the FIFO
//              and wr_ptr is incremented. While rc_en is used to read and increment the
//              rd_ptr.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module Fifo_Datapath (
    input  logic        clk,
    input  logic        rst,
    input  logic        wc_en,       
    input  logic        rc_en,       
    input  logic [31:0] Data_in,
    
    output logic [31:0] Data_out,
    output logic        full,
    output logic        fifo_empty
);

    logic [3:0] w_addr;
    logic [3:0] r_addr;
    logic [31:0] Memory [15:0];
    logic [4:0] count; // max value = 16 (0–16)

    // Write pointer
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            w_addr <= 0;
        else if (wc_en && !full)
            w_addr <= w_addr + 1;
    end

    // Read pointer
    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            r_addr <= 0;
        else if (rc_en && !fifo_empty)
            r_addr <= r_addr + 1;
    end

    // Write data into FIFO
    always_ff @(posedge clk) begin
        if (wc_en && !full)
            Memory[w_addr] <= Data_in;
    end

    // Read data from FIFO
    always_comb begin
        Data_out = (rst)? 0: Memory[r_addr];
    end
    // assign Data_out = Memory[r_addr];

    // Fifo Counter logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            count <= 0;
        else begin
            case ({wc_en && !full, rc_en && !fifo_empty})
                2'b10: count <= count + 1; // write only
                2'b01: count <= count - 1; // read only
                default: count <= count;   // no change or both
            endcase
        end
    end

    assign full       = (count == 16);
    assign fifo_empty = (count == 0);

endmodule
