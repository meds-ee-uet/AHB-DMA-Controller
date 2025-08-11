// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: Main Controller of the DMAC, decides when to configure the slave when
//              request from peripheral is made and requests for the hold of the bus
//              Decides which channel to enable according to the request and gives priority
//              to the peripheral handling the DmacReq[1] signal. Also contains the Master
//              Interface of the DMAC.
//
// Authors: Muhammad Mouzzam and Danish Hassan 
// Date: July 23rd, 2025

typedef enum logic [1:0] {
    IDLE                = 2'b00,
    BUS_REQD            = 3'b001,
    WAIT_FOR_DST        = 3'b010,
    WAIT_FOR_TRANS_SIZE = 3'b011,
    WAIT_FOR_CTRL       = 3'b100,
    MSB_REQ             = 3'b101,
    LSB_REQ             = 3'b110,
    WAIT                = 3'b111
} state_t;

module Dmac_Main_Ctrl(
    input  logic clk,
    input  logic rst,
    input  logic [1:0] DmacReq,
    input  logic con_new_sel,
    input  logic irq,
    input  logic Bus_Grant,
    input  logic C_config,

    output logic con_sel,
    output logic Bus_Req,
    output logic HReadyOut,
    output logic [1:0] S_HResp,
    output logic Interrupt,
    output logic con_en,
    output logic Channel_en_1, Channel_en_2,
    output logic hold,
    output logic [1:0] ReqAck
);

    state_t current_state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always_comb begin
        // Default outputs
        hold         = 0;
        Bus_Req      = 0;
        Interrupt    = 0;
        con_en       = 0;
        con_sel      = 0;
        Channel_en_1 = 0;
        Channel_en_2 = 0;
        HReadyOut    = 0;
        ReqAck       = 2'b00;
        S_HResp      = 2'b00;
        next_state   = current_state;  // Default next state

        case (current_state)
            IDLE: begin
                
            end

            MSB_REQ: begin
                if (!irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Channel_en_1 = 1;
                    con_en       = 0;
                    con_sel      = 0;
                    ReqAck       = 2'b10;
                    next_state   = WAIT;
                end else if (irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Interrupt  = 1;
                    con_sel = 1;
                    Channel_en_1 = 1;
                    next_state = IDLE;
                end else
                    Bus_Req = 1;
            end

            LSB_REQ: begin
                if (!irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Channel_en_2 = 1;
                    con_en       = 1;
                    con_sel      = 1;
                    ReqAck       = 2'b01;
                    next_state   = WAIT;
                end else if (irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Interrupt  = 1;
                    con_sel = 1;
                    Channel_en_2 = 1;
                    next_state = IDLE;
                end else
                    Bus_Req = 1;
            end

            WAIT: begin
                if (({Bus_Grant, con_new_sel} == 2'b00)) begin
                    next_state = MSB_REQ;
                    Channel_en_1 = 0;
                    Bus_Req    = 1;
                end else if (({Bus_Grant, con_new_sel} == 2'b01)) begin
                    next_state = LSB_REQ;
                    Channel_en_2 = 0;
                    Bus_Req    = 1;
                    con_sel    = 1;
                end else
                 if (!irq && !con_new_sel) begin
                    con_sel    = 0;
                    con_en     = 1;
                    Channel_en_1 = 1;
                    next_state = WAIT;
                end else if (!irq && con_new_sel) begin
                    con_sel    = 1;
                    con_en     = 1;
                    Channel_en_2 = 1;
                    next_state = WAIT;
                end else if (irq && ({Bus_Grant, con_new_sel} == 2'b10)) begin
                    Interrupt  = 1;
                    Channel_en_1 = 1;
                    con_sel = con_new_sel;
                    next_state = IDLE;
                end else if (irq && ({Bus_Grant, con_new_sel} == 2'b11)) begin
                    Interrupt  = 1;
                    Channel_en_2 = 1;
                    con_sel = con_new_sel;
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
