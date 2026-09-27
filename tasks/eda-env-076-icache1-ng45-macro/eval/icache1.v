// icache1: direct-mapped read-through instruction cache — 64 lines
// of 4 words of 32 bits. The data store is one single-port SRAM bank
// (spram_256x32); the tag/valid store is a flop array. A CPU-side
// request either hits (data streams from the bank) or misses (the
// line refills word-by-word from the memory side, then the lookup
// replays). The FSM serializes all bank operations, so the single
// port is never contended.
module icache1 (
    input             clk,
    input             rst_n,

    input             cpu_valid,
    input      [11:0] cpu_addr,
    output            cpu_ready,

    output reg        rsp_valid,
    output     [31:0] rsp_data,
    input             rsp_ready,

    output reg        mem_req_valid,
    output     [11:0] mem_req_addr,
    input             mem_req_ready,

    input             mem_rsp_valid,
    input      [31:0] mem_rsp_data,
    output            mem_rsp_ready
);
    localparam S_IDLE = 3'd0, S_TAG = 3'd1, S_RSP = 3'd2,
               S_RFILL = 3'd3, S_RWAIT = 3'd4;
    reg [2:0]  state;
    reg [11:0] a_q;
    reg [1:0]  rw;
    reg [63:0] valid_mem;
    reg [3:0]  tag_mem [0:63];

    wire [5:0] line = a_q[7:2];
    wire       hit  = valid_mem[line] && (tag_mem[line] == a_q[11:8]);

    assign cpu_ready     = rst_n && (state == S_IDLE);
    assign mem_rsp_ready = (state == S_RWAIT);
    assign mem_req_addr  = {a_q[11:2], rw};
    wire cpu_fire = cpu_valid && cpu_ready;
    wire mrq_fire = mem_req_valid && mem_req_ready;
    wire mrs_fire = mem_rsp_valid && mem_rsp_ready;

    // ---- bank port (FSM-serialized) ----------------------------------
    wire       rd_issue = (state == S_TAG) && hit;
    wire       wr_fire  = mrs_fire;
    wire       cs   = rd_issue || wr_fire;
    wire [7:0] addr = wr_fire ? {line, rw} : {line, a_q[1:0]};
    spram_256x32 bank0 (
        .clk(clk), .cs(cs), .we(wr_fire), .addr(addr),
        .wdata(mem_rsp_data), .rdata(rsp_data)
    );

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE; a_q <= 12'd0; rw <= 2'd0;
            valid_mem <= 64'd0; rsp_valid <= 1'b0;
            mem_req_valid <= 1'b0;
            for (i = 0; i < 64; i = i + 1)
                tag_mem[i] <= 4'd0;
        end else begin
            case (state)
              S_IDLE: if (cpu_fire) begin
                a_q   <= cpu_addr;
                state <= S_TAG;
              end
              S_TAG: begin
                if (hit) begin
                    rsp_valid <= 1'b1;   // bank read issues this edge
                    state     <= S_RSP;
                end else begin
                    rw            <= 2'd0;
                    mem_req_valid <= 1'b1;
                    state         <= S_RFILL;
                end
              end
              S_RFILL: if (mrq_fire) begin
                mem_req_valid <= 1'b0;
                state         <= S_RWAIT;
              end
              S_RWAIT: if (mrs_fire) begin
                if (rw == 2'd3) begin
                    valid_mem[line] <= 1'b1;
                    tag_mem[line]   <= a_q[11:8];
                    state           <= S_TAG;  // replay: now a hit
                end else begin
                    rw            <= rw + 2'd1;
                    mem_req_valid <= 1'b1;
                    state         <= S_RFILL;
                end
              end
              S_RSP: if (rsp_valid && rsp_ready) begin
                rsp_valid <= 1'b0;
                state     <= S_IDLE;
              end
              default: state <= S_IDLE;
            endcase
        end
    end
endmodule
