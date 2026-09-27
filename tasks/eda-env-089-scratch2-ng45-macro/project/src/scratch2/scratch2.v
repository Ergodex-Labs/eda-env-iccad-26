// scratch2: 512-word shared scratchpad — a DMA-style write port and
// an independent read port over TWO single-port SRAM banks
// (spram_256x32, bank = addr[8]). Within a bank reads have priority;
// a read and a write to DIFFERENT banks proceed in the same cycle.
// Read responses arrive in read-accept order with one cycle of
// latency.
module scratch2 (
    input             clk,
    input             rst_n,

    input             wr_valid,
    input      [8:0]  wr_addr,
    input      [31:0] wr_data,
    output            wr_ready,

    input             rd_valid,
    input      [8:0]  rd_addr,
    output            rd_ready,

    output reg        rrsp_valid,
    output     [31:0] rrsp_data,
    input             rrsp_ready
);
    wire rsp_free = rrsp_ready || !rrsp_valid;
    wire rb = rd_addr[8];
    wire wb = wr_addr[8];

    wire rd_grant = rst_n && rd_valid && rsp_free;
    // A write yields only when the read is granted on ITS bank.
    wire wr_block = rd_grant && (rb == wb);
    wire wr_grant = rst_n && wr_valid && !wr_block;

    assign rd_ready = rd_grant;
    assign wr_ready = rst_n && !wr_block;

    wire        rd0 = rd_grant && !rb;
    wire        wr0 = wr_grant && !wb;
    wire [31:0] q0;
    spram_256x32 bank0 (
        .clk(clk), .cs(rd0 || wr0), .we(wr0),
        .addr(wr0 ? wr_addr[7:0] : rd_addr[7:0]),
        .wdata(wr_data), .rdata(q0)
    );

    wire        rd1 = rd_grant && rb;
    wire        wr1 = wr_grant && wb;
    wire [31:0] q1;
    spram_256x32 bank1 (
        .clk(clk), .cs(rd1 || wr1), .we(wr1),
        .addr(wr1 ? wr_addr[7:0] : rd_addr[7:0]),
        .wdata(wr_data), .rdata(q1)
    );

    reg out_bank;
    assign rrsp_data = out_bank ? q1 : q0;

    always @(posedge clk) begin
        if (!rst_n) begin
            rrsp_valid <= 1'b0;
            out_bank   <= 1'b0;
        end else begin
            if (rd_grant) begin
                rrsp_valid <= 1'b1;
                out_bank   <= rb;
            end else if (rrsp_valid && rrsp_ready)
                rrsp_valid <= 1'b0;
        end
    end
endmodule
