// sboxpipe: registered 32-bit path through four parallel AES S-boxes.
// The combinational depth of aes_sbox IS the critical path — the F12
// rewrite target. Frozen wrapper (eda-env-037); aes_sbox.v is the
// granted, equivalence-gated file.
module sboxpipe (
  input  wire        clk,
  input  wire        rst_n,
  input  wire [31:0] din,
  output reg  [31:0] dout
);
  reg  [31:0] d_q;
  wire [31:0] s;
  always @(posedge clk) begin
    if (!rst_n) begin
      d_q  <= 32'd0;
      dout <= 32'd0;
    end else begin
      d_q  <= din;
      dout <= s;
    end
  end
  aes_sbox u0 (.a(d_q[7:0]),   .d(s[7:0]));
  aes_sbox u1 (.a(d_q[15:8]),  .d(s[15:8]));
  aes_sbox u2 (.a(d_q[23:16]), .d(s[23:16]));
  aes_sbox u3 (.a(d_q[31:24]), .d(s[31:24]));
endmodule
