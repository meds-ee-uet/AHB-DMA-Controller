// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: Module used to call the Channel's Datapath and controller.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

module Dmac_Channel (
    input  logic        clk,
    input  logic        rst,
    input  logic        channel_en,
    input  logic        readyIn,
    input  logic [1:0]  M_HResp,
    input  logic [31:0] S_Address,
    input  logic [31:0] D_Address,
    input  logic [31:0] T_Size,
    input  logic [31:0] B_Size,
    input  logic [31:0] R_Data,
    input  logic [1:0]  HSize,

    output logic        irq,
    output logic        write,
    output logic [1:0]  HTrans,
    output logic [31:0] MAddress,
    output logic [31:0] MWData,
    output logic  [3:0] MWStrb
);

    // Internal wires
    logic s_sel, d_sel, b_sel, t_sel;
    logic s_en, d_en, ts_en, burst_en, count_en;
    logic h_sel, rd_en, wr_en;
    logic fifo_full, fifo_empty;
    logic trigger;
    logic bs0, tslb, ts0;

    // Instantiate the datapath
    Dmac_Channel_Datapath datapath_inst (
        .clk         (clk),
        .rst         (rst),
        .s_sel       (s_sel),
        .d_sel       (d_sel),
        .b_sel       (b_sel),
        .t_sel       (t_sel),
        .s_en        (s_en),
        .d_en        (d_en),
        .ts_en       (ts_en),
        .burst_en    (burst_en),
        .count_en    (count_en),
        .h_sel       (h_sel),
        .wr_en       (wr_en),
        .rd_en       (rd_en),
        .trigger     (trigger),
        .S_Address   (S_Address),
        .D_Address   (D_Address),
        .T_Size      (T_Size),
        .B_Size      (B_Size),
        .R_Data      (R_Data),
        .bs0         (bs0),
        .tslb        (tslb),
        .ts0         (ts0),
        .fifo_full   (fifo_full),
        .fifo_empty  (fifo_empty),
        .MAddress    (MAddress),
        .MWData      (MWData)
    );

    // Instantiate the controller
    channel_ctrl controller_inst (
        .clk         (clk),
        .rst         (rst),
        .channel_en  (channel_en),
        .readyIn     (readyIn),
        .fifo_full   (fifo_full),
        .fifo_empty  (fifo_empty),
        .bsz         (bs0),
        .tslb        (tslb),
        .tsz         (ts0),
        .M_HResp     (M_HResp),
        .irq         (irq),
        .HTrans      (HTrans),
        .write       (write),
        .b_sel       (b_sel),
        .d_sel       (d_sel),
        .t_sel       (t_sel),
        .s_sel       (s_sel),
        .h_sel       (h_sel),
        .d_en        (d_en),
        .s_en        (s_en),
        .ts_en       (ts_en),
        .burst_en    (burst_en),
        .count_en    (count_en),
        .rd_en       (rd_en),
        .wr_en       (wr_en),
        .trigger     (trigger)
    );
endmodule
