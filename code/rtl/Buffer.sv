// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A Basic Buffer which acts as a mock peripheral for the DMAC, for ideal
//              transfer, readyOut and HResp are kept at 1 and Okay - 00 respectively.
//              Takes the address first, then the data and stores it in a RegFile.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module mock_ahb_peripheral #(
    parameter MEM_DEPTH = 1024
)(
    input  logic        HCLK,
    input  logic        HRESET,

    // AHB-Lite Signals
    input  logic        HSEL,
    input  logic [31:0] HADDR,
    input  logic [1:0]  HTRANS,
    input  logic        HWRITE,
    input  logic [2:0]  HSIZE,
    input  logic [31:0] HWDATA,
    input  logic [3:0]  WSTRB,
    output logic [31:0] HRDATA,
    input  logic        HREADYIN,
    output logic        HREADYOUT,
    output logic [1:0]  HRESP
);

    // Memory array
    logic [7:0] mem [0:MEM_DEPTH-1];

    // Internal latched control signals (captured during address phase)
    logic [31:0] latched_addr;
    logic        latched_write;
    logic        latched_valid;
    logic [2:0]  latched_size;
    logic        latched_sel;

    // Word-aligned address (256 x 32-bit memory = 8-bit address)
    logic [7:0] addr_index;
    assign addr_index = latched_addr[9:0];

    // Peripheral is always ready and always responds OKAY
    assign HREADYOUT = 1'b1;
    assign HRESP     = 2'b00;

    // Address Phase: Latch control signals
    always_ff @(posedge HCLK or posedge HRESET) begin
        if (HRESET) begin
            latched_addr  <= 32'd0;
            latched_write <= 1'b0;
            latched_valid <= 1'b0;
            latched_size  <= 3'b000;
            latched_sel   <= 1'b0;
        end else if (HREADYIN) begin
            latched_valid <= HSEL && HTRANS[1]; // Non-IDLE
            latched_addr  <= HADDR;
            latched_write <= HWRITE;
            latched_size  <= HSIZE;
            latched_sel   <= HSEL;
        end
    end

    // Data Phase: Perform write
    always_ff @(posedge HCLK) begin
        if (latched_valid && latched_sel && latched_write) begin
            if (WSTRB[0])
                mem[addr_index] <= HWDATA[7:0];
            if (WSTRB[1])
                mem[addr_index+1] <= HWDATA[15:8];
            if (WSTRB[2])
                mem[addr_index+2] <= HWDATA[23:16];
            if (WSTRB[1])
                mem[addr_index+3] <= HWDATA[31:24];
        end
    end

    // Data Phase: Perform read (combinational)
    always_comb begin
        if (latched_valid && latched_sel && !latched_write) begin
            HRDATA = {mem[addr_index+3], mem[addr_index+2], mem[addr_index+1], mem[addr_index]};
        end else begin
            HRDATA = 32'd0;
        end
    end

endmodule
