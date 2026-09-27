// keyvault2: key vault that stores 64 keys of 256 bits (8 words of
// 32) in two single-port SRAM banks (spram_256x32, bank = index bit
// 5). A key loads as an 8-word stream on the load handshake and
// streams out as an 8-word response on the fetch handshake. The vault
// FSM serializes loads and fetches, and one key lives whole in one
// bank, so neither single port is ever contended.
module keyvault2 (
    input             clk,
    input             rst_n,

    input             ld_valid,
    input      [5:0]  ld_index,
    input      [31:0] ld_data,
    output            ld_ready,

    input             fk_valid,
    input      [5:0]  fk_index,
    output            fk_ready,

    output reg        out_valid,
    output     [31:0] out_data,
    output reg        out_last,
    input             out_ready
);
    localparam S_IDLE = 2'd0, S_LOAD = 2'd1, S_FETCH = 2'd2;
    reg [1:0] state;
    reg [5:0] key_sel;
    reg [2:0] word;
    reg       rd_done;
    reg       out_bank;

    assign fk_ready = rst_n && (state == S_IDLE);
    assign ld_ready = rst_n && (((state == S_IDLE) && !fk_valid)
                                || (state == S_LOAD));
    wire ld_fire = ld_valid && ld_ready;
    wire fk_fire = fk_valid && fk_ready;

    // ---- bank ports (FSM-serialized; one key = one bank) -------------
    wire       rd_issue = (state == S_FETCH) && !rd_done
                          && (out_ready || !out_valid);
    wire [5:0] wr_key   = (state == S_IDLE) ? ld_index : key_sel;
    wire [2:0] wr_word  = (state == S_IDLE) ? 3'd0 : word;
    wire [7:0] wa = {wr_key[4:0], wr_word};
    wire [7:0] ra = {key_sel[4:0], word};

    wire        we0 = ld_fire  && !wr_key[5];
    wire        rd0 = rd_issue && !key_sel[5];
    wire [31:0] q0;
    spram_256x32 bank0 (
        .clk(clk), .cs(we0 || rd0), .we(we0),
        .addr(we0 ? wa : ra), .wdata(ld_data), .rdata(q0)
    );

    wire        we1 = ld_fire  && wr_key[5];
    wire        rd1 = rd_issue && key_sel[5];
    wire [31:0] q1;
    spram_256x32 bank1 (
        .clk(clk), .cs(we1 || rd1), .we(we1),
        .addr(we1 ? wa : ra), .wdata(ld_data), .rdata(q1)
    );

    assign out_data = out_bank ? q1 : q0;

    wire out_fire_last = out_valid && out_ready && out_last;

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= S_IDLE; key_sel <= 6'd0; word <= 3'd0;
            rd_done <= 1'b0; out_valid <= 1'b0; out_last <= 1'b0;
            out_bank <= 1'b0;
        end else begin
            case (state)
              S_IDLE: begin
                if (fk_fire) begin
                    state    <= S_FETCH;
                    key_sel  <= fk_index;
                    out_bank <= fk_index[5];
                    word     <= 3'd0;
                    rd_done  <= 1'b0;
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
