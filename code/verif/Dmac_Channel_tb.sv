// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A Basic Testbench for the Channel which first initializes the registers
//              and transfers 18 words in 4 word bursts. 16 words are transfered in bursts
//              while the remaining 2 are transfered as single words one by one
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

`timescale 1ns/1ps

module dmac_channel_tb;

    // Clock and reset
    logic clk;
    logic rst;

    // AHB-Lite bus signals
    logic [31:0] HADDR;
    logic [1:0]  HTRANS;
    logic        HWRITE;
    logic [2:0]  HSIZE;
    logic [31:0] HWDATA;
    logic [31:0] HRDATA;
    logic        HREADY;
    logic [1:0]  HRESP;

    // DMA control signals
    logic channel_en;
    logic irq, write;
    logic [31:0] S_Addr = 32'h0000_0000; // Source address
    logic [31:0] D_Addr = 32'h0000_1000; // Destination address
    logic [31:0] T_Size = 32'd18;
    logic [31:0] B_Size = 32'd4;

    assign HWRITE = write;

    // Clock generation
    always #5 clk = ~clk;

    // DUT instantiation
    Dmac_Channel dmac (
        .clk        (clk),
        .rst        (rst),
        .channel_en (channel_en),
        .readyIn    (HREADY),
        .HResp      (HRESP),
        .R_Data     (HRDATA),
        .S_Address  (S_Addr),
        .D_Address  (D_Addr),
        .T_Size     (T_Size),
        .B_Size     (B_Size),
        .irq        (irq),
        .write      (write),
        .HTrans     (HTRANS),
        .MAddress   (HADDR),
        .MWData     (HWDATA)
    );

    // Instantiate source peripheral (read side)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) source (
        .HCLK       (clk),
        .HRESET     (rst), 
        .HSEL       (HADDR[12] == 1'b0), // Address bit[12] == 0 for source
        .HADDR      (HADDR),
        .HTRANS     (HTRANS),
        .HWRITE     (HWRITE),
        .HSIZE      (HSIZE),
        .HWDATA     (HWDATA),
        .HRDATA     (HRDATA),
        .HREADYIN   (1'b1),
        .HREADYOUT  (HREADY),
        .HRESP      (HRESP)
    );

    // Instantiate destination peripheral (write side)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) dest (
        .HCLK       (clk),
        .HRESET     (rst),
        .HSEL       (HADDR[12] == 1'b1), // Address bit[12] == 1 for destination
        .HADDR      (HADDR),
        .HTRANS     (HTRANS),
        .HWRITE     (HWRITE),
        .HSIZE      (HSIZE),
        .HWDATA     (HWDATA),
        .HRDATA     (),         // Not used for write
        .HREADYIN   (1'b1),
        .HREADYOUT  (),         // Not needed here
        .HRESP      ()          // Not needed here
    );

    // Initialization
    initial begin
        clk = 0;
        rst = 1;
        channel_en = 0;

        // Wait 2 cycles then deassert reset
        repeat (2) @(posedge clk);
        rst = 0;

        // Initialize source memory (mem[0] to mem[3])
        source.mem[0] = 32'hAABBCCDD;
        source.mem[1] = 32'h11223344;
        source.mem[2] = 32'h55667788;
        source.mem[3] = 32'h99AABBCC;
        source.mem[4] = 32'h123;
        source.mem[5] = 32'h456;
        source.mem[6] = 32'h1;
        source.mem[7] = 32'h2;
        source.mem[8] = 32'h3;
        source.mem[9] = 32'h4;
        source.mem[10] = 32'h5;
        source.mem[11] = 32'h6;
        source.mem[12] = 32'h7;
        source.mem[13] = 32'h8;
        source.mem[14] = 32'h9;
        source.mem[15] = 32'ha;
        source.mem[16] = 32'hb;
        source.mem[17] = 32'hc;

        // Start DMA
        @(posedge clk);
        channel_en = 1;

        // Wait for transfer to complete
        wait (irq == 1);
        $display("DMA Transfer Completed.");
        channel_en = 0;

        // Check results from destination memory
        $display("Dest mem[0] = %h", dest.mem[0]);
        $display("Dest mem[1] = %h", dest.mem[1]);
        $display("Dest mem[2] = %h", dest.mem[2]);
        $display("Dest mem[3] = %h", dest.mem[3]);

        #20 $finish;
    end

endmodule
