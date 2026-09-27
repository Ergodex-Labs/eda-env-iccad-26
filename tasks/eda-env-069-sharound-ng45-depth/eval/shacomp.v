// shacomp: one SHA-256 compression step (a..h, k, w) -> (a'..h').
// GRANTED rewrite surface — must stay combinationally identical.
module shacomp (
    input  [255:0] state_in,   // {a,b,c,d,e,f,g,h}
    input  [31:0]  k,
    input  [31:0]  w,
    output [255:0] state_out
);
    wire [31:0] a = state_in[255:224], b = state_in[223:192];
    wire [31:0] c = state_in[191:160], d = state_in[159:128];
    wire [31:0] e = state_in[127:96],  f = state_in[95:64];
    wire [31:0] g = state_in[63:32],   h = state_in[31:0];
    function [31:0] rotr;
        input [31:0] x; input [4:0] n;
        rotr = (x >> n) | (x << (32 - n));
    endfunction
    wire [31:0] s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
    wire [31:0] ch = (e & f) ^ (~e & g);
    wire [31:0] t1 = h + s1 + ch + k + w;
    wire [31:0] s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
    wire [31:0] mj = (a & b) ^ (a & c) ^ (b & c);
    wire [31:0] t2 = s0 + mj;
    assign state_out = {t1 + t2, a, b, c, d + t1, e, f, g};
endmodule
