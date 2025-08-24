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
    logic [31:0] MRData, MRData_S, MRData_D;
    logic [1:0] HResp;
    logic [1:0] DmacReq;
    logic Bus_Grant;

    logic HReady, HReadyOut_D, HReadyOut_S;
    logic [31:0] MAddress, MWData;
    logic [3:0]  MBurst_Size;
    logic MWrite;
    logic [1:0] MTrans;
    logic [3:0] MWStrb;
    logic Bus_Req, Interrupt;
    logic [1:0] ReqAck;

    logic [9:0] temp_src_addr, temp_dst_addr, temp_trans_size;
    logic [1:0]  temp_hsize;
    logic [3:0]  temp_Strb;

    logic [1:0] latched_hsel;
    logic [1:0] selected_hsel;

    // Clock
    always #5 clk = ~clk;
    // Instantiate DUT
    Dmac_Top dut (
        .clk(clk), .rst(rst),
        .MRData(MRData), .HReady(HReady), .M_HResp(HResp),
        .DmacReq(DmacReq), .Bus_Grant(Bus_Grant),
        .MAddress(MAddress), .MWData(MWData), .MBurst_Size(MBurst_Size),
        .MWrite(MWrite), .MTrans(MTrans), .Bus_Req(Bus_Req),
        .Interrupt(Interrupt), .ReqAck(ReqAck), .MWStrb(MWStrb)
    );


    // Mock source peripheral (read from memory)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) source (
        .HCLK(clk),
        .HRESET(rst),
        .HSEL(selected_hsel[1]),
        .HADDR(MAddress),
        .HTRANS(MTrans),
        .HWRITE(MWrite),
        .HREADYIN(HReady),
        .HWDATA(MWData),
        .HRDATA(MRData_S),  // Output to DMA
        .HREADYOUT(HReadyOut_S),
        .HRESP(HResp),
        .HSIZE(),
        .WSTRB(MWStrb)
    );

    // Mock destination peripheral (write to memory)
    mock_ahb_peripheral #(.MEM_DEPTH(256)) dest (
        .HCLK(clk),
        .HRESET(rst),
        .HSEL(selected_hsel[0]),
        .HADDR(MAddress),
        .HTRANS(MTrans),
        .HWRITE(MWrite),
        .HREADYIN(HReady),
        .HWDATA(MWData),  // Input from DMA
        .HRDATA(MRData_D),        // Not used
        .HREADYOUT(HReadyOut_D),
        .HRESP(),
        .HSIZE(),
        .WSTRB(MWStrb)
    );

    always_comb begin
        if (latched_hsel == 2'b10) begin
            HReady = HReadyOut_S;
            MRData = MRData_S;
        end else if (latched_hsel == 2'b01) begin
            HReady = HReadyOut_D;
            MRData = MRData_D;
        end else if (latched_hsel == 2'b00)
            HReady = 1'b1;
    end

    int check = 0;
    int count = 0;

    always_ff @(posedge clk) begin
        if (rst)
            latched_hsel = 2'b0;
        else if (HReady)
            latched_hsel <= selected_hsel;
    end

    always @(Interrupt) begin
        $display("Time = %0t ps, Interrupt changed to %b", $time, Interrupt);
    end

    assign selected_hsel = (MAddress[28]) ? 2'b01: 2'b10;

    always_comb begin
        if (dut.DmacReq_Reg[1]) begin
            temp_src_addr = {dest.mem[32'h0000_00A1][1:0], dest.mem[32'h0000_00A0]};
            temp_dst_addr = {dest.mem[32'h0000_00A5][1:0], dest.mem[32'h0000_00A4]};
            temp_trans_size = {24'b0, dest.mem[32'h0000_00A8]};
            temp_hsize = dest.mem[32'h0000_00AC][7:4];
        end else if(dut.DmacReq_Reg == 2'b01) begin    
            temp_src_addr = {source.mem[32'h0000_00A1][1:0], source.mem[32'h0000_00A0]};
            temp_dst_addr = {source.mem[32'h0000_00A5][1:0], source.mem[32'h0000_00A4]};
            temp_trans_size = {24'b0, source.mem[32'h0000_00A8]};
            temp_hsize = source.mem[32'h0000_00AC][7:4];
        end
    end

    always_comb begin
        case (temp_hsize)
            2'b00: begin  // Byte
                case (temp_src_addr[1:0])
                    2'b00: temp_Strb = 4'b0001;
                    2'b01: temp_Strb = 4'b0010;
                    2'b10: temp_Strb = 4'b0100;
                    2'b11: temp_Strb = 4'b1000;
                    default: temp_Strb = 4'b0000;
                endcase
            end
            2'b01: begin  // Halfword
                case (temp_src_addr[1:0])
                    2'b00: temp_Strb = 4'b0011;  
                    2'b10: temp_Strb = 4'b1100;
                    default: temp_Strb = 4'b0000; 
                endcase
            end
            2'b10: temp_Strb = 4'b1111;  // Word — all bytes active
            default: temp_Strb = 4'b0000;
        endcase
    end

    int passed = 0;
    int failed = 0;

    // Stimulus
    initial begin
        // Initial state
        clk = 0;
        rst = 1;
        DmacReq = 0;
        Bus_Grant = 0;

        // Initializing Source
        for (int i = 0; i < 100; i++) begin
            source.mem[i] = i+i;
        end

        // Initializing Destination
        for (int i = 100; i < 200; i++) begin
            dest.mem[i-100] = i+i;
        end

        // 1st peripheral configuration
        
        source.mem[32'h0000_00A3] = 8'h00;
        source.mem[32'h0000_00A2] = 8'h00;
        source.mem[32'h0000_00A1] = 8'h00;
        source.mem[32'h0000_00A0] = 8'h00;

        source.mem[32'h0000_00A7] = 8'h10;
        source.mem[32'h0000_00A6] = 8'h00;
        source.mem[32'h0000_00A5] = 8'h00;
        source.mem[32'h0000_00A4] = 8'h00;

        source.mem[32'h0000_00AB] = 8'h00;
        source.mem[32'h0000_00AA] = 8'h00;
        source.mem[32'h0000_00A9] = 8'h00;
        source.mem[32'h0000_00A8] = 8'd22;

        source.mem[32'h0000_00AF] = 8'h00;
        source.mem[32'h0000_00AE] = 8'h01;
        source.mem[32'h0000_00AD] = 8'h00;
        source.mem[32'h0000_00AC] = 8'h22;

        // 2nd peripheral configuration

        dest.mem[32'h0000_00A3] = 8'h10;
        dest.mem[32'h0000_00A2] = 8'h00;
        dest.mem[32'h0000_00A1] = 8'h00;
        dest.mem[32'h0000_00A0] = 8'h04;

        dest.mem[32'h0000_00A7] = 8'h00;
        dest.mem[32'h0000_00A6] = 8'h00;
        dest.mem[32'h0000_00A5] = 8'h00;
        dest.mem[32'h0000_00A4] = 8'h00;

        dest.mem[32'h0000_00AB] = 8'h00;
        dest.mem[32'h0000_00AA] = 8'h00;
        dest.mem[32'h0000_00A9] = 8'h00;
        dest.mem[32'h0000_00A8] = 8'd22;

        dest.mem[32'h0000_00AF] = 8'h00;
        dest.mem[32'h0000_00AE] = 8'h01;
        dest.mem[32'h0000_00AD] = 8'h00;
        dest.mem[32'h0000_00AC] = 8'h21;

        // Wait a few cycles
        repeat (5) @(posedge clk);
        rst = 0;

        // Request from Peripheral 
        @(posedge clk);
        DmacReq = 2'b11;

        // Grant bus to DMA
        @(posedge clk);
        Bus_Grant = 1;
        
        wait(ReqAck != 2'b00);

        if (ReqAck[1])
            DmacReq[1] = 1'b0;
        else if(ReqAck[0])
            DmacReq[0] = 1'b0;

        // Wait until transfer is done
        
        while (!check) begin
            wait (Interrupt == 1)
            @(negedge clk)
            if (Interrupt == 1)
                check = 1;
        end

        repeat(2) @(posedge clk)
        $display("Time = %0t ps, Interrupt asserted!", $time);

        // Verify destination memory
        $display("\033[1;36mDMA transfer completed. Checking destination memory...\033[0m");
        monitor(temp_trans_size, temp_src_addr, temp_dst_addr);

        $stop;
    end

task monitor(input logic [31:0] transfer_size, input logic [9:0] src_addr, dst_addr);
    for(int i = src_addr[9:2] << 2, j = dst_addr, k = 0; k < transfer_size; i=i+4, j=j+4, k++) begin
        $display("\033[1;36m---------Word No. %-2d---------\033[0m", k+1);
        for (int a = i, b = j, c = 0; (a < i+4) && (b < j+4) && (c < 4); a++, b++, c++) begin
            if (temp_Strb[c])
                check_byte(a, b, dut.DmacReq_Reg[1]? dest.mem[32'h0000_00A3][4] ? 1:0 : source.mem[32'h0000_00A3][4] ? 1:0);
            else
                $display("\033[1;35mInvalid Byte\033[0m");
        end
    end
    $display("\033[1;35mValid Bytes Transferred:\033[0m\n    \033[1;32mSuccessfull = %d\033[0m, \033[1;31mUnsuccessfull = %d\033[0m", passed, failed);
endtask

task check_byte(input int saddr, daddr, input bit dir);
    byte sdata, ddata;
    if (dir == 0) begin
        // Source -> Dest
        sdata = source.mem[saddr];
        ddata = dest.mem[daddr];
    end else begin
        // Dest -> Source
        sdata = dest.mem[saddr];
        ddata = source.mem[daddr];
    end
    if (sdata == ddata) begin
        $display("\033[1;32mPASS: {[%0s][%-2d] = %x} == {[%0s][%-2d] = %x}\033[0m",
                 (dir==1)?"Source":"Dest", (dir==1)?saddr:daddr, ddata,
                 (dir==1)?"Dest":"Source", (dir==1)?daddr:saddr, sdata);
        passed += 1;
    end else begin
        $display("\033[1;31mFAIL: {[%0s][%-2d] = %x} != {[%0s][%-2d] = %x}\033[0m",
                 (dir==1)?"Source":"Dest", (dir==1)?saddr:daddr, ddata,
                 (dir==1)?"Dest":"Source", (dir==1)?daddr:saddr, sdata);
        failed += 1;
    end
endtask

endmodule
