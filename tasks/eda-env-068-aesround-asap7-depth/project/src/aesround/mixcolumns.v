// mixcolumns: AES MixColumns over a 128-bit state (4 columns of 4
// bytes; byte i: row = i%4, col = i/4; byte 0 = bits [127:120]).
// GRANTED rewrite surface — must stay combinationally identical.
module mixcolumns (
    input  [127:0] in,
    output [127:0] out
);
    function [7:0] xt;
        input [7:0] b;
        xt = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
    endfunction
    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : g_col
            wire [7:0] s0 = in[127-32*c -: 8];
            wire [7:0] s1 = in[119-32*c -: 8];
            wire [7:0] s2 = in[111-32*c -: 8];
            wire [7:0] s3 = in[103-32*c -: 8];
            assign out[127-32*c -: 8] = xt(s0) ^ xt(s1) ^ s1 ^ s2 ^ s3;
            assign out[119-32*c -: 8] = s0 ^ xt(s1) ^ xt(s2) ^ s2 ^ s3;
            assign out[111-32*c -: 8] = s0 ^ s1 ^ xt(s2) ^ xt(s3) ^ s3;
            assign out[103-32*c -: 8] = xt(s0) ^ s0 ^ s1 ^ s2 ^ xt(s3);
        end
    endgenerate
endmodule
