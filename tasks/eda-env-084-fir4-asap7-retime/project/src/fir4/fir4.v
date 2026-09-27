// fir4: 4-tap FIR (constant coefficients 13, 7, 5, 3) with a fixed
// 4-cycle latency CONTRACT (policed by the frozen tb_fir4.v): the
// output during cycle c equals
//   13*x[c-4] + 7*x[c-5] + 5*x[c-6] + 3*x[c-7]
// where x[k] is the input sampled at the end of cycle k. Register
// rebalancing is allowed; the function and the latency are not.
module fir4 (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [15:0] x,
  output wire [21:0] y
);
  reg [15:0] x0, x1, x2, x3;
  reg [21:0] m_q, r1, r2;
  always @(posedge clk) begin
    if (!rst_n) begin
      x0 <= 16'd0; x1 <= 16'd0; x2 <= 16'd0; x3 <= 16'd0;
      m_q <= 22'd0; r1 <= 22'd0; r2 <= 22'd0;
    end else begin
      x0 <= x; x1 <= x0; x2 <= x1; x3 <= x2;
      m_q <= 22'd13*x0 + 22'd7*x1 + 22'd5*x2 + 22'd3*x3;
      r1 <= m_q;
      r2 <= r1;
    end
  end
  assign y = r2;
endmodule
