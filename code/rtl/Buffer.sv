module mock_ahb_peripheral #(
    parameter MEM_DEPTH = 1024,
    parameter DELAY_CYCLES = 2 // configurable wait states
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

    // Latched control signals
    logic [31:0] latched_addr;
    logic        latched_write;
    logic        latched_valid;
    logic [2:0]  latched_size;
    logic        latched_sel;

    // Delay counter
    integer delay_cnt;
    logic   delay_active;

    // Word-aligned address
    logic [9:0] addr_index;
    assign addr_index = latched_addr[9:0];

    // OKAY response
    assign HRESP = 2'b00;

    // Address Phase: latch control
    always_ff @(posedge HCLK or posedge HRESET) begin
        if (HRESET) begin
            latched_addr  <= 32'd0;
            latched_write <= 1'b0;
            latched_valid <= 1'b0;
            latched_size  <= 3'b000;
            latched_sel   <= 1'b0;
            delay_cnt     <= 0;
            delay_active  <= 1'b0;
        end else if (HREADYIN) begin
            latched_valid <= HSEL && HTRANS[1]; // NON-IDLE
            latched_addr  <= HADDR;
            latched_write <= HWRITE;
            latched_size  <= HSIZE;
            latched_sel   <= HSEL;

            // Start delay when valid transfer detected
            if (HSEL && HTRANS[1]) begin
                delay_cnt    <= DELAY_CYCLES;
                delay_active <= (DELAY_CYCLES > 0);
            end
        end else if (delay_active && delay_cnt > 0) begin
            delay_cnt <= delay_cnt - 1;
            if (delay_cnt == 1) delay_active <= 1'b0; // last cycle
        end
    end

    // HREADYOUT: low during delay
    assign HREADYOUT = !delay_active;

    // Data Phase: perform write after delay
    always_ff @(posedge HCLK) begin
        if (!delay_active && latched_valid && latched_sel && latched_write) begin
            if (WSTRB[0]) mem[addr_index]   <= HWDATA[7:0];
            if (WSTRB[1]) mem[addr_index+1] <= HWDATA[15:8];
            if (WSTRB[2]) mem[addr_index+2] <= HWDATA[23:16];
            if (WSTRB[3]) mem[addr_index+3] <= HWDATA[31:24];
        end
    end

    // Data Phase: perform read after delay
    always_comb begin
        if (!delay_active && latched_valid && latched_sel && !latched_write) begin
            HRDATA = {mem[(addr_index[9:2]*4)+3], 
                      mem[(addr_index[9:2]*4)+2], 
                      mem[(addr_index[9:2]*4)+1], 
                      mem[(addr_index[9:2]*4)]};
        end else begin
            HRDATA = 32'd0;
        end
    end

endmodule
