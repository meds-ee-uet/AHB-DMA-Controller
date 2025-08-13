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

typedef enum logic [3:0] {
    IDLE                = 4'b0000,
    BUS_REQD            = 4'b0001,
    WAIT_FOR_SRC        = 4'b0010,
    WAIT_FOR_DST        = 4'b0011,
    WAIT_FOR_TRANS_SIZE = 4'b0100,
    WAIT_FOR_CTRL       = 4'b0101,
    MSB_REQ             = 4'b0110,
    LSB_REQ             = 4'b0111,
    WAIT                = 4'b1000
} state_t;

typedef enum logic [1:0] {
    Idle    = 2'b00,
    Busy    = 2'b01,
    Non_Seq = 2'b10,
    Seq     = 2'b11
} HTrans_t;

module Dmac_Main_Ctrl(
    input  logic clk,
    input  logic rst,
    input  logic [1:0] DmacReq, DmacReq_Reg,
    input  logic [1:0] con_new_sel,
    input  logic irq,
    input  logic Bus_Grant,
    input  logic C_config, HReady,

    output logic [1:0] con_sel,
    output logic Bus_Req,
    output logic DmacReq_Reg_en, SAddr_Reg_en, DAddr_Reg_en, Trans_sz_Reg_en, Ctrl_Reg_en,
    output logic [1:0] addr_inc_sel,
    output logic Interrupt,
    output logic con_en, config_write, PeriAddr_reg_en,
    output logic Channel_en_1, Channel_en_2,
    output logic [1:0] ReqAck,
    output HTrans_t config_HTrans
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
        Bus_Req         = 1;
        Interrupt       = 0;
        con_en          = 0;
        Channel_en_1    = 0;
        Channel_en_2    = 0;
        SAddr_Reg_en    = 0;
        addr_inc_sel    = 0;
        config_write    = 0;
        DmacReq_Reg_en  = 0;
        DAddr_Reg_en    = 0;
        Trans_sz_Reg_en = 0;
        Ctrl_Reg_en     = 0;
        PeriAddr_reg_en = 0;
        con_sel         = 2'b00;
        ReqAck          = 2'b00;
        config_HTrans   = Idle;
        next_state      = current_state;  // Default next state

        case (current_state)
            IDLE: begin
                if(DmacReq != 2'b00) begin
                    Bus_Req = 1;
                    DmacReq_Reg_en = 1;
                    PeriAddr_reg_en = 1;
                    next_state = BUS_REQD;
                end
            end

            BUS_REQD: begin
                if(Bus_Grant && HReady && DmacReq_Reg[1]) begin
                    con_sel = 2'b10;
                    config_write = 0;
                    addr_inc_sel = 2'b00;
                    config_HTrans = Non_Seq;
                    ReqAck = 2'b10;
                    next_state = WAIT_FOR_SRC;
                end else if(Bus_Grant && HReady && DmacReq_Reg == 2'b01) begin
                    con_sel = 2'b10;
                    config_write = 0;
                    addr_inc_sel = 2'b00;
                    config_HTrans = Non_Seq;
                    ReqAck = 2'b01;
                    next_state = WAIT_FOR_SRC;
                end
            end

            WAIT_FOR_SRC: begin
                if (!HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b01;
                    config_HTrans  = Busy;
                end else if (Bus_Grant && HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b01;
                    config_HTrans  = Non_Seq;
                    SAddr_Reg_en   = 1;
                    next_state     = WAIT_FOR_DST;
                end
            end

            WAIT_FOR_DST: begin
                if (!HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b10;
                    config_HTrans  = Busy;
                end else if (Bus_Grant && HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b10;
                    config_HTrans  = Non_Seq;
                    DAddr_Reg_en   = 1;
                    next_state     = WAIT_FOR_TRANS_SIZE;
                end
            end

            WAIT_FOR_TRANS_SIZE: begin
                if (!HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b11;
                    config_HTrans  = Busy;
                end else if (Bus_Grant && HReady) begin
                    con_sel        = 2'b10;
                    config_write   = 0;
                    addr_inc_sel   = 2'b11;
                    Trans_sz_Reg_en = 1;
                    config_HTrans  = Non_Seq;
                    next_state = WAIT_FOR_CTRL;
                end
            end

            WAIT_FOR_CTRL: begin
                con_sel        = 2'b10;
                config_write   = 0;
                addr_inc_sel   = 2'b11;

                if (!HReady) begin
                    config_HTrans = Busy;
                end
                else if (Bus_Grant && DmacReq_Reg[1]) begin
                    Ctrl_Reg_en   = 1;
                    config_HTrans = Idle;
                    next_state    = MSB_REQ;
                end
                else if (Bus_Grant && (DmacReq_Reg == 2'b01)) begin
                    Ctrl_Reg_en   = 1;
                    config_HTrans = Idle;
                    next_state    = LSB_REQ;
                end
            end

            MSB_REQ: begin
                if (!irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Channel_en_1 = 1;
                    con_en       = 0;
                    con_sel      = 2'b00;
                    next_state   = WAIT;
                end else if (irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Interrupt  = 1;
                    con_sel = 2'b01;
                    Channel_en_1 = 1;
                    next_state = IDLE;
                end else
                    Bus_Req = 1;
            end

            LSB_REQ: begin
                if (!irq && ({C_config, Bus_Grant} == 2'b11)) begin
                    Channel_en_2 = 1;
                    con_en       = 1;
                    con_sel      = 2'b01;
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
                if (({Bus_Grant, con_new_sel} == 3'b000)) begin
                    next_state = MSB_REQ;
                    Channel_en_1 = 0;
                    Bus_Req    = 1;
                end else if (({Bus_Grant, con_new_sel} == 3'b001)) begin
                    next_state = LSB_REQ;
                    Channel_en_2 = 0;
                    Bus_Req    = 1;
                    con_sel    = 2'b01;
                end else
                 if (!irq && con_new_sel == 2'b00) begin
                    con_sel    = 2'b00;
                    con_en     = 1;
                    Channel_en_1 = 1;
                    next_state = WAIT;
                end else if (!irq && con_new_sel == 2'b01) begin
                    con_sel    = 2'b01;
                    con_en     = 1;
                    Channel_en_2 = 1;
                    next_state = WAIT;
                end else if (irq && ({Bus_Grant, con_new_sel} == 3'b100)) begin
                    Interrupt  = 1;
                    Channel_en_1 = 1;
                    con_sel = con_new_sel;
                    next_state = IDLE;
                end else if (irq && ({Bus_Grant, con_new_sel} == 3'b101)) begin
                    Interrupt  = 1;
                    Channel_en_2 = 1;
                    con_sel = con_new_sel;
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule
