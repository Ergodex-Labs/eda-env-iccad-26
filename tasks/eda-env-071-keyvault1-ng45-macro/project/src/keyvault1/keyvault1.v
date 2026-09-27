// keyvault1: key vault that stores 32 keys of 256 bits (8 words of
// 32) in one single-port SRAM bank (spram_256x32). A key loads as an
// 8-word stream on the load handshake and streams out as an 8-word
// response on the fetch handshake. The vault FSM serializes loads and
// fetches, so the single port is never contended.
module keyvault1 (
    input             clk,
    input             rst_n,

    input             ld_valid,
    input      [4:0]  ld_index,
    input      [31:0] ld_data,
    output            ld_ready,

    input             fk_valid,
    input      [4:0]  fk_index,
    output            fk_ready,

    output reg        out_valid,
    output     [31:0] out_data,
    output reg        out_last,
    input             out_ready
);
    localparam S_IDLE = 2'd0, S_LOAD = 2'd1, S_FETCH = 2'd2;
    reg [1:0] state;
    reg [4:0] key_sel;
    reg [2:0] word;
    reg       rd_done;

    assign fk_ready = rst_n && (state == S_IDLE);
    assign ld_ready = rst_n && (((state == S_IDLE) && !fk_valid)
                                || (state == S_LOAD));
    wire ld_fire = ld_valid && ld_ready;
    wire fk_fire = fk_valid && fk_ready;

    // ---- bank port (FSM-serialized: at most one request per cycle) ---
    wire       rd_issue = (state == S_FETCH) && !rd_done
                          && (out_ready || !out_valid);
    wire [4:0] wr_key   = (state == S_IDLE) ? ld_index : key_sel;
    wire [2:0] wr_word  = (state == S_IDLE) ? 3'd0 : word;
    wire       cs   = ld_fire || rd_issue;
    wire [7:0] addr = ld_fire ? {wr_key, wr_word} : {key_sel, word};
    spram_256x32 bank0 (
        .clk(clk), .cs(cs), .we(ld_fire), .addr(addr),
        .wdata(ld_data), .rdata(out_data)
    );

    wire out_fire_last = out_valid && out_ready && out_last;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE; key_sel <= 5'd0; word <= 3'd0;
            rd_done <= 1'b0; out_valid <= 1'b0; out_last <= 1'b0;
        end else begin
            case (state)
              S_IDLE: begin
                if (fk_fire) begin
                    state   <= S_FETCH;
                    key_sel <= fk_index;
                    word    <= 3'd0;
                    rd_done <= 1'b0;
                end else if (ld_fire) begin
                    state   <= S_LOAD;
                    key_sel <= ld_index;
                    word    <= 3'd1;   // word 0 is written at this edge
                end
              end
              S_LOAD: if (ld_fire) begin
                word <= word + 3'd1;
                if (word == 3'd7)
                    state <= S_IDLE;
              end
              default: ;               // S_FETCH is sequenced below
            endcase

            if (rd_issue) begin
                out_valid <= 1'b1;
                out_last  <= (word == 3'd7);
                word      <= word + 3'd1;
                if (word == 3'd7)
                    rd_done <= 1'b1;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
                out_last  <= 1'b0;
            end
            if (out_fire_last) begin
                state     <= S_IDLE;
                out_valid <= 1'b0;
                out_last  <= 1'b0;
            end
        end
    end
endmodule
