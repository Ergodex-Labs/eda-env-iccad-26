// aesround: one registered AES-style round datapath — SubBytes (16
// S-boxes), ShiftRows (byte rotation within rows), MixColumns — between
// input and output registers. FROZEN wrapper; mixcolumns.v is the
// rewrite surface.
module aesround (
    input              clk,
    input              ld,
    input      [127:0] din,
    output reg [127:0] dout
);
    reg  [127:0] r_in;
    wire [127:0] sb, sr, mc;
    always @(posedge clk) if (ld) r_in <= din;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : g_sbox
            aes_sbox u_s (.a(r_in[127-8*i -: 8]), .d(sb[127-8*i -: 8]));
        end
    endgenerate
    // ShiftRows: byte index i (row = i%4, col = i/4); row r rotates
    // left by r columns: out[row, col] = in[row, (col+row)%4].
    generate
        for (i = 0; i < 16; i = i + 1) begin : g_sr
            localparam integer ROW = i % 4;
            localparam integer COL = i / 4;
            localparam integer SRC = ((COL + ROW) % 4) * 4 + ROW;
            assign sr[127-8*i -: 8] = sb[127-8*SRC -: 8];
        end
    endgenerate
    mixcolumns u_mc (.in(sr), .out(mc));
    always @(posedge clk) dout <= mc;
endmodule
