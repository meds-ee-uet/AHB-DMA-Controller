// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: Datapath of the Channel, takes a channel enable signal to configure itself,
//              then continues to first read the data from the source peripheral and then
//              write it to the provided destination. Has a 16-word FIFO buffer to buffer
//              data. If transfer size is not a multiple of burst size, then the remaining
//              words are transfered as single words.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module Dmac_Channel_Datapath (
    input  logic        clk,
    input  logic        rst,

    input  logic        s_sel,
    input  logic        d_sel,
    input  logic        b_sel,
    input  logic        t_sel,

    input  logic        s_en,
    input  logic        d_en,
    input  logic        ts_en,
    input  logic        burst_en,
    input  logic        count_en,
    input  logic        h_sel,
    input  logic        wr_en,
    input  logic        rd_en,
    input  logic        trigger,

    input  logic [31:0] S_Address,
    input  logic [31:0] D_Address,
    input  logic [31:0] T_Size,
    input  logic [31:0] B_Size,
    input  logic [31:0] R_Data,

    output logic        bs0,
    output logic        tslb,
    output logic        ts0,
    output logic        fifo_full,
    output logic        fifo_empty,
    output logic [31:0] MAddress,
    output logic [31:0] MWData
);

    // Registers
    logic [31:0] Src_Addr, Dst_Addr, Transfer_Size, Burst_Size;

    //Counters 
    logic [31:0] Incr_Src_Addr;
    logic [31:0] Incr_Dst_Addr;
    logic [31:0] Dec_Transfer_Size;

    always_comb begin
        Incr_Src_Addr      = Src_Addr + 32'd4;
        Incr_Dst_Addr      = Dst_Addr + 32'd4;
        Dec_Transfer_Size  = Transfer_Size - Burst_Size;
    end

    //Mux Inputs
    

    // Source Address Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Src_Addr <= 32'b0;
        end
        else if (s_en)
            Src_Addr <= s_sel ? S_Address : Incr_Src_Addr;
    end

    // Destination Address Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Dst_Addr <= 32'b0;
        end
        else if (d_en)
            Dst_Addr <= d_sel ? D_Address : Incr_Dst_Addr;
    end

    // Transfer Size Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Transfer_Size <= 32'b0;
        end
        else if (ts_en)
            Transfer_Size <= t_sel ? T_Size : Dec_Transfer_Size;
    end

    // Burst Size Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            Burst_Size <= 32'b0;
        end
        else if (burst_en)
            Burst_Size <= b_sel ? 1 : B_Size;
    end

    // Comparisons
    assign tslb = ((Transfer_Size - Burst_Size) < Burst_Size);

    // Decrement Counter Logic
    logic [31:0] Decrement_Counter;
    logic [31:0] Decremented_Value;

    always_comb begin
        Decremented_Value = Decrement_Counter - 1;
    end

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            Decrement_Counter <= 32'b0;
        else if (count_en)
            Decrement_Counter <= (Decrement_Counter == 0) ? Burst_Size - 1 : Decremented_Value;
    end

    // Putting Address on AHB Bus
    assign MAddress = h_sel ? (Dst_Addr) : (Src_Addr);

    // FIFO Integration
    logic [31:0] fifo_out;

    Fifo_Datapath fifo_inst (
        .clk        (clk),
        .rst        (rst),
        .wc_en      (wr_en),
        .rc_en      (rd_en),
        .Data_in    (R_Data),
        .Data_out   (fifo_out),
        .full       (fifo_full),
        .fifo_empty (fifo_empty)
    );

    // Connect MWData only when triggered
    always_comb begin
        if (trigger)
            MWData = fifo_out;
        else 
            MWData = 32'b0;
    end

    assign bs0 = (Decrement_Counter == 0);
    assign ts0 = (Transfer_Size == 0);

endmodule
