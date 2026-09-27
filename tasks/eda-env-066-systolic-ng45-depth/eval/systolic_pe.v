// systolic: 4x4 weight-stationary systolic matrix-multiply array,
// 8-bit operands, 24-bit accumulators. Activations stream west->east,
// partial sums flow north->south. Frozen F1 RTL (eda-env NG45 row).
module systolic_pe (
  input  wire        clk,
  input  wire        rst_n,
  input  wire        w_load,
  input  wire [7:0]  w_in,
  input  wire [7:0]  a_in,
  input  wire [23:0] p_in,
  output reg  [7:0]  a_out,
  output reg  [23:0] p_out
);
  reg [7:0] w_q;
  always @(posedge clk) begin
    if (!rst_n) begin
      w_q <= 8'd0; a_out <= 8'd0; p_out <= 24'd0;
    end else begin
      if (w_load) w_q <= w_in;
      a_out <= a_in;
      p_out <= p_in + a_in * w_q;
    end
  end
endmodule

