// mult16: 16x16 -> 32 pipelined multiplier (3 stages: input regs,
// multiply, output reg). Frozen F1 RTL (eda-env-018).
module mult16 (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [15:0] a,
  input  wire [15:0] b,
  output reg  [31:0] p
);
  reg [15:0] a_q, b_q;
  reg [31:0] m_q;
  always @(posedge clk) begin
    if (!rst_n) begin
      a_q <= 16'd0;
      b_q <= 16'd0;
      m_q <= 32'd0;
      p   <= 32'd0;
    end else begin
      a_q <= a;
      b_q <= b;
      m_q <= a_q * b_q;
      p   <= m_q;
    end
  end
endmodule
