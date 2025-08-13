// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: Module for Instantiating DMAC's Controller and Datapath.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module Dmac_Top (
    input  logic        clk,
    input  logic        rst,

    // AHB-lite Bus Interface (from peripheral (slave)) 
    input  logic [31:0] MRData,
    input  logic        HReady,
    input  logic [1:0]  M_HResp,

    // DMA request signals from two sources
    input  logic [1:0]  DmacReq,     // {channel_1_req, channel_2_req}
    input  logic        Bus_Grant,  // from arbiter

    // Outputs to Bus
    output logic [31:0] MAddress,
    output logic [31:0] MWData,
    output logic [3:0]  MBurst_Size,
    output logic        MWrite,
    output logic [1:0]  MTrans,
    output logic [3:0]  MWStrb,

    // Control/Status
    output logic        Bus_Req,
    output logic        Interrupt,
    output logic [1:0]  ReqAck
);

    // Internal control signals
    logic con_en, irq, C_config;
    logic DmacReq_Reg_en, SAddr_Reg_en, DAddr_Reg_en, Trans_sz_Reg_en, Ctrl_Reg_en;
    logic config_write, PeriAddr_reg_en;
    logic channel_en_1, channel_en_2;
    logic [1:0] addr_inc_sel, con_sel, con_new_sel, config_HTrans, DmacReq_Reg;

    // Instantiate Datapath
    Dmac_Main_Datapath datapath_inst (
        .clk            (clk),
        .rst            (rst),
        .channel_en_1   (channel_en_1),
        .channel_en_2   (channel_en_2),
        .MRData         (MRData),
        .HReady         (HReady),
        .M_HResp        (M_HResp),
        .con_en         (con_en),
        .con_sel        (con_sel),
        .DmacReq        (DmacReq),
        .DmacReq_Reg_en (DmacReq_Reg_en),
        .SAddr_Reg_en   (SAddr_Reg_en),
        .DAddr_Reg_en   (DAddr_Reg_en),
        .Trans_sz_Reg_en(Trans_sz_Reg_en),
        .Ctrl_Reg_en    (Ctrl_Reg_en),
        .PeriAddr_reg_en(PeriAddr_reg_en),
        .addr_inc_sel   (addr_inc_sel),
        .config_HTrans  (config_HTrans),
        .config_write   (config_write),

        .C_config       (C_config),
        .irq            (irq),
        .con_new_sel    (con_new_sel),
        .MAddress       (MAddress),
        .MWData         (MWData),
        .MBurst_Size    (MBurst_Size),
        .MWrite         (MWrite),
        .MTrans         (MTrans),
        .MWStrb         (MWStrb),
        .DmacReq_Reg    (DmacReq_Reg)
    );

    // Instantiate Controller
    Dmac_Main_Ctrl controller_inst (
        .clk            (clk),
        .rst            (rst),
        .DmacReq        (DmacReq),
        .con_new_sel    (con_new_sel),
        .irq            (irq),
        .Bus_Grant      (Bus_Grant),
        .C_config       (C_config),
        .DmacReq_Reg    (DmacReq_Reg),
        .HReady         (HReady),

        .con_sel        (con_sel),
        .Bus_Req        (Bus_Req),
        .Interrupt      (Interrupt),
        .con_en         (con_en),
        .Channel_en_1   (channel_en_1),
        .Channel_en_2   (channel_en_2),
        .ReqAck         (ReqAck),
        .DmacReq_Reg_en (DmacReq_Reg_en),
        .SAddr_Reg_en   (SAddr_Reg_en),
        .DAddr_Reg_en   (DAddr_Reg_en),
        .Trans_sz_Reg_en(Trans_sz_Reg_en),
        .Ctrl_Reg_en    (Ctrl_Reg_en),
        .PeriAddr_reg_en(PeriAddr_reg_en),
        .addr_inc_sel   (addr_inc_sel),
        .config_HTrans  (config_HTrans),
        .config_write   (config_write)
    );

endmodule
