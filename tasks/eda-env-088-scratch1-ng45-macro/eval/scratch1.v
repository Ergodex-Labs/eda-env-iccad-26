// scratch1: 256-word shared scratchpad — a DMA-style write port and
// an independent read port arbitrated onto one single-port SRAM bank
// (spram_256x32). Reads have priority when the response register is
// free; a write is accepted on any cycle no read is granted. Read
// responses arrive in read-accept order with one cycle of latency.
module scratch1 (
    input             clk,
    input             rst_n,

    input             wr_valid,
    input      [7:0]  wr_addr,
    input      [31:0] wr_data,
    output            wr_ready,

    input             rd_valid,
    input      [7:0]  rd_addr,
    output            rd_ready,

    output reg        rrsp_valid,
    output     [31:0] rrsp_data,
    input             rrsp_ready
);
    wire rsp_free  = rrsp_ready || !rrsp_valid;
    wire rd_grant  = rst_n && rd_valid && rsp_free;
    wire wr_grant  = rst_n && wr_valid && !rd_grant;

    assign rd_ready = rd_grant;
    assign wr_ready = rst_n && !rd_grant;

    spram_256x32 bank0 (
        .clk(clk), .cs(rd_grant || wr_grant), .we(wr_grant),
        .addr(wr_grant ? wr_addr : rd_addr),
        .wdata(wr_data), .rdata(rrsp_data)
    );

    always @(posedge clk) begin
        if (!rst_n)
            rrsp_valid <= 1'b0;
        else if (rd_grant)
            rrsp_valid <= 1'b1;
        else if (rrsp_valid && rrsp_ready)
            rrsp_valid <= 1'b0;
    end
endmodule
