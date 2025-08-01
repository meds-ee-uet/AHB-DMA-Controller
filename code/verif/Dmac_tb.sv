// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A testbench to enable the DMAC with a request and according to that, the
//              respective channel is enabled. At the end checks if the data in the
//              destination is the same as the data transfered from the source.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

`timescale 1ns/1ps

module Dmac_Top_tb;

    logic clk, rst;
    logic [31:0] MRData;
    logic write, HSel;
    logic [31:0] HWData, HAddr;
    logic HReadyOut;
    logic [1:0] HResp;
    logic [1:0] DmacReq;
    logic Bus_Grant;

    logic [31:0] MAddress, MWData;
    logic [3:0]  MBurst_Size;
    logic MWrite;
    logic [1:0] MTrans;
    logic Bus_Req, Interrupt;
    logic [1:0] ReqAck;

    // Clock
    always #5 clk = ~clk;
    // Instantiate DUT
    Dmac_Top dut (
        .clk(clk), .rst(rst),
        .MRData(MRData), .write(write), .HSel(HSel), .STrans(2'b10),
        .HWData(HWData), .HAddr(HAddr), .HReady(1'b1), .M_HResp(HResp),
        .DmacReq(DmacReq), .Bus_Grant(Bus_Grant), .HReadyOut(), .S_HResp(),
        .MAddress(MAddress), .MWData(MWData), .MBurst_Size(MBurst_Size),
        .MWrite(MWrite), .MTrans(MTrans), .Bus_Req(Bus_Req),
        .Interrupt(Interrupt), .ReqAck(ReqAck)
    );


    // Mock source peripheral (read from memory)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) source (
        .HCLK(clk),
        .HRESET(rst),
        .HSEL(MAddress[12] == 1'b0),
        .HADDR(MAddress),
        .HTRANS(MTrans),
        .HWRITE(1'b0),
        .HREADYIN(1'b1),
        .HWDATA(32'h0),
        .HRDATA(MRData),  // Output to DMA
        .HREADYOUT(HReadyOut),
        .HRESP(HResp),
        .HSIZE()
    );

    // Mock destination peripheral (write to memory)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) dest (
        .HCLK(clk),
        .HRESET(rst),
        .HSEL(MAddress[12] == 1'b1),
        .HADDR(MAddress),
        .HTRANS(MTrans),
        .HWRITE(MWrite),
        .HREADYIN(1'b1),
        .HWDATA(MWData),  // Input from DMA
        .HRDATA(),        // Not used
        .HREADYOUT(),
        .HRESP(),
        .HSIZE()
    );

    always @(Interrupt) begin
        $display("Time = %0t ps, Interrupt changed to %b", $time, Interrupt);
    end
    // Stimulus
    initial begin
        // Initial state
        clk = 0;
        rst = 1;
        write = 0;
        HSel = 0;
        HWData = 0;
        HAddr = 0;
        DmacReq = 0;
        Bus_Grant = 0;

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

        // Wait a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // Request from Peripheral 
        @(posedge clk);
        DmacReq = 2'b01;
        // Program DMA channel via CPU-like interface
        @(posedge clk);
        HSel = 1; write = 1;
        HAddr = 32'h0000_0000;  // Size Reg  
        @(posedge clk);
        HAddr = 32'h0000_0004;  // Source
        HWData = 32'd10;
        @(posedge clk);
        HAddr = 32'h0000_0008;  // Destination
        HWData = 32'h0000_0000; 
        @(posedge clk);
        HAddr = 32'h0000_000C;  // Control register 
        HWData = 32'h0000_1000; 

        @(posedge clk);
        HWData = 32'h0001_0006;
        HSel = 0;
        write = 0;

        // Grant bus to DMA
        repeat (2) @(posedge clk);
        Bus_Grant = 1;
        // DmacReq = 2'b0;

        // Wait until transfer is done
        wait (Interrupt == 1);
        repeat(2) @(posedge clk)
        $display("Time = %0t ps, Interrupt asserted!", $time);
        // Verify destination memory
        $display("\033[1;36mDMA transfer completed. Checking destination memory...\033[0m");
        monitor(10);
        $stop;
    end

task monitor(input logic [31:0] transfer_size);
    automatic int passed = 0;
    automatic int failed = 0;
    for(int i = 0; i < transfer_size; i++) begin
        if (source.mem[i] == dest.mem[i]) begin
            $display("\033[1;32mPASS: {Source[%-2d] = %x} == {Destination[%-2d] = %x}\033[0m", i, source.mem[i], i , dest.mem[i]);
            passed += 1;
        end else begin
            $display("\033[1;31mFAIL: {Source[%-2d] = %x} != {Destination[%-2d] = %x}\033[0m", i, source.mem[i], i , dest.mem[i]);
            failed += 1;
        end
    end
    $display("\033[1;35mTest Cases:\033[0m\n    \033[1;32mPassed = %d\033[0m, \033[1;31mFailed = %d\033[0m", passed, failed);
endtask

endmodule
