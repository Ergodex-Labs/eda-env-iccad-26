// shastep: registered wrapper around one SHA-256 compression step.
// FROZEN wrapper; shacomp.v is the rewrite surface.
module shastep (
    input              clk,
    input              ld,
    input      [255:0] state_i,
    input      [31:0]  k_i,
    input      [31:0]  w_i,
    output reg [255:0] state_o
);
    reg [255:0] r_s;
    reg [31:0]  r_k, r_w;
    wire [255:0] nx;
    always @(posedge clk) if (ld) begin
        r_s <= state_i; r_k <= k_i; r_w <= w_i;
    end
    shacomp u_c (.state_in(r_s), .k(r_k), .w(r_w), .state_out(nx));
    always @(posedge clk) state_o <= nx;
endmodule
