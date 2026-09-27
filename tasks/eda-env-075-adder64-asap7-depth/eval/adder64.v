// adder64: 64+64 -> 65 pipelined adder (3 stages: input regs, add,
// output reg). Authored F12.2 RTL (recipe-only depth row): the carry
// structure the mapper builds IS the critical path; the synthesis
// recipe decides ripple vs prefix.
module adder64 (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [63:0] a,
  input  wire [63:0] b,
  output reg  [64:0] s
);
  reg [63:0] a_q, b_q;
  reg [64:0] s_q;
  always @(posedge clk) begin
    if (!rst_n) begin
      a_q <= 64'd0;
      b_q <= 64'd0;
      s_q <= 65'd0;
      s   <= 65'd0;
    end else begin
      a_q <= a;
      b_q <= b;
      s_q <= {1'b0, a_q} + {1'b0, b_q};
      s   <= s_q;
    end
  end
endmodule
