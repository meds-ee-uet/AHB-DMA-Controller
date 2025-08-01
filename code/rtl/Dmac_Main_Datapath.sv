// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: Main Datapath of the DMAC, Contains 2 Channels and handles only 1 request
//              at a time, which the lower priority or late request has to wait untill the
//              one being attended to isn't complete. Contains the Slave and Master
//              Interface as well.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module Dmac_Main_Datapath(
    input logic clk,
    input logic rst,
    input logic write,
    input logic HSel,
    input logic [1:0] STrans, //From CPU to configure it
    input logic channel_en_1,
    input logic channel_en_2,
    input logic [31:0] HWData,
    input logic [31:0] HAddr,
    input logic [31:0] MRData,
    input logic HReady,
    input logic [1:0] M_HResp,
    input logic con_en,
    input logic con_sel,

    output logic C_config,
    output logic irq,
    output logic con_new_sel,
    output logic [31:0] MAddress,
    output logic [31:0] MWData,
    output logic [3:0] MBurst_Size,
    output logic MWrite,
    output logic [3:0] MWStrb,
    output logic [1:0] MTrans
);

logic dmac_selected;
logic [3:0] decoded_address;
logic [31:0] Size_Reg, SAddr_Reg, DAddr_Reg, Ctrl_Reg;
logic [31:0] latched_address;
logic latched_write, latched_sel;
logic [1:0] latched_STrans;

assign  dmac_selected = latched_write && latched_STrans[1] && latched_sel;
assign decoded_address = latched_address[5:2];

assign C_config = Ctrl_Reg[16];

always_ff @( posedge clk ) begin
    if (rst) begin
        latched_address = 32'b0;
        latched_write = 0;
        latched_STrans = 2'b0;
        latched_sel = 0;
    end else begin
        latched_address <= HAddr;
        latched_STrans <= STrans;
        latched_sel <= HSel;
        latched_write <= write;
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        Size_Reg <= 32'b0;
        SAddr_Reg <= 32'b0;
        DAddr_Reg <= 32'b0;
        Ctrl_Reg <= 32'b0;
    end
    else if (irq)
        Ctrl_Reg <= 32'b0;
    else if (dmac_selected) begin
        case (decoded_address)
            4'b0000: Size_Reg <=  HWData;
            4'b0001: SAddr_Reg <= HWData;
            4'b0010: DAddr_Reg <= HWData;
            4'b0011: Ctrl_Reg <=  HWData;
            default: ;
        endcase
    end
end

// Channel 1 signals

logic irq_1;
logic write_1;
logic [1:0]  MTrans_1;
logic [31:0] MAddress_1;
logic [31:0] MWData_1;
logic [3:0] MWStrb_1;

Dmac_Channel channel_1 (
    .clk(clk),
    .rst(rst),
    .channel_en(channel_en_1),
    .readyIn(HReady),
    .M_HResp(M_HResp),
    .S_Address(SAddr_Reg),
    .D_Address(DAddr_Reg),
    .T_Size(Size_Reg),
    .B_Size({{28{1'b0}}, {Ctrl_Reg[3:0]}}),
    .R_Data(MRData),
    .HSize(Ctrl_Reg[5:4]),

    .irq(irq_1),
    .write(write_1),
    .HTrans(MTrans_1),
    .MAddress(MAddress_1),
    .MWData(MWData_1),
    .MWStrb(MWStrb_1)
);

// Channel 2 signals

logic irq_2;
logic write_2;
logic [1:0]  MTrans_2;
logic [31:0] MAddress_2;
logic [31:0] MWData_2;
logic [3:0] MWStrb_2;

Dmac_Channel channel_2 (
    .clk(clk),
    .rst(rst),
    .channel_en(channel_en_2),
    .readyIn(HReady),
    .M_HResp(M_HResp),
    .S_Address(SAddr_Reg),
    .D_Address(DAddr_Reg),
    .T_Size(Size_Reg),
    .B_Size({{28{1'b0}}, {Ctrl_Reg[3:0]}}) ,
    .R_Data(MRData),
    .HSize(Ctrl_Reg[5:4]),

    .irq(irq_2),
    .write(write_2),
    .HTrans(MTrans_2),
    .MAddress(MAddress_2),
    .MWData(MWData_2),
    .MWStrb(MWStrb_2)
);

assign MAddress = con_sel? MAddress_2 : MAddress_1;
assign MWData = con_sel? MWData_2 : MWData_1;
assign MTrans = con_sel? MTrans_2 : MTrans_1;
assign MBurst_Size = Ctrl_Reg[3:0];
assign MWrite = con_sel? write_2 : write_1;
assign irq = irq_1 || irq_2; 
assign MWStrb = con_sel? MWStrb_2 : MWStrb_1;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        con_new_sel <= 0;
        // irq <= 0;
    end
    else if (con_en) begin
        con_new_sel <= con_sel;
    end
    // irq <= irq_1 || irq_2;

end



    
endmodule