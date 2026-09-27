// icache2: direct-mapped read-through instruction cache — 64 lines
// of 4 words of 32 bits. BOTH stores are single-port SRAM banks
// (spram_256x32): bank0 holds the data words, bank1 holds one tag
// word per line ({27'b0, valid, tag[3:0]} at address {2'b00, line}).
// A lookup reads the tag word first, then hits from bank0 or refills
// the line from the memory side (data words, then the tag word) and
// replays. The FSM serializes each bank's operations, so neither
// single port is ever contended.
module icache2 (
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
    localparam S_IDLE = 3'd0, S_TAG = 3'd1, S_TAGW = 3'd2,
               S_RSP = 3'd3, S_RFILL = 3'd4, S_RWAIT = 3'd5,
               S_TWRITE = 3'd6;
    reg [2:0]  state;
    reg [11:0] a_q;
    reg [1:0]  rw;

    wire [5:0] line = a_q[7:2];
    wire       tag_hit;
    assign cpu_ready     = rst_n && (state == S_IDLE);
    assign mem_rsp_ready = (state == S_RWAIT);
    assign mem_req_addr  = {a_q[11:2], rw};
    wire cpu_fire = cpu_valid && cpu_ready;
    wire mrq_fire = mem_req_valid && mem_req_ready;
    wire mrs_fire = mem_rsp_valid && mem_rsp_ready;

    // ---- data bank (bank0) -------------------------------------------
    wire       d_rd = (state == S_TAGW) && tag_hit;
    wire       d_wr = mrs_fire;
    spram_256x32 bank0 (
        .clk(clk), .cs(d_rd || d_wr), .we(d_wr),
        .addr(d_wr ? {line, rw} : {line, a_q[1:0]}),
        .wdata(mem_rsp_data), .rdata(rsp_data)
    );

    // ---- tag bank (bank1) --------------------------------------------
    wire        t_rd = (state == S_TAG);
    wire        t_wr = (state == S_TWRITE);
    wire [31:0] tag_q;
    spram_256x32 bank1 (
        .clk(clk), .cs(t_rd || t_wr), .we(t_wr),
        .addr({2'b00, line}),
        .wdata({27'b0, 1'b1, a_q[11:8]}), .rdata(tag_q)
    );
    assign tag_hit = tag_q[4] && (tag_q[3:0] == a_q[11:8]);

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE; a_q <= 12'd0; rw <= 2'd0;
            rsp_valid <= 1'b0; mem_req_valid <= 1'b0;
        end else begin
            case (state)
              S_IDLE: if (cpu_fire) begin
                a_q   <= cpu_addr;
                state <= S_TAG;     // tag word read issues next cycle
              end
              S_TAG: state <= S_TAGW;  // tag word lands in tag_q
              S_TAGW: begin
                if (tag_hit) begin
                    rsp_valid <= 1'b1;  // data read issues this edge
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
                if (rw == 2'd3)
                    state <= S_TWRITE;  // then write the tag word
                else begin
                    rw            <= rw + 2'd1;
                    mem_req_valid <= 1'b1;
                    state         <= S_RFILL;
                end
              end
              S_TWRITE: state <= S_TAG;  // replay: now a hit
              S_RSP: if (rsp_valid && rsp_ready) begin
                rsp_valid <= 1'b0;
                state     <= S_IDLE;
              end
              default: state <= S_IDLE;
            endcase
        end
    end
endmodule
