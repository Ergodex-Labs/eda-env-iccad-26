// Frozen wrapper (the PE file is the rewrite surface).
module systolic (
  input  wire         clk,
  input  wire         rst_n,
  input  wire         w_load,
  input  wire [63:0]  w_flat,    // 8 weights loaded per column set
  input  wire [31:0]  a_flat,    // 4 activations, one per row
  output wire [95:0]  p_flat     // 4 column sums, 24 bits each
);
  wire [7:0]  a [0:3][0:4];
  wire [23:0] p [0:4][0:3];
  genvar r, c;
  generate
    for (r = 0; r < 4; r = r + 1) begin : g_row
      assign a[r][0] = a_flat[8*r+7 -: 8];
    end
    for (c = 0; c < 4; c = c + 1) begin : g_col
      assign p[0][c] = 24'd0;
      assign p_flat[24*c+23 -: 24] = p[4][c];
    end
    for (r = 0; r < 4; r = r + 1) begin : g_r
      for (c = 0; c < 4; c = c + 1) begin : g_c
        wire [7:0]  a_o;
        wire [23:0] p_o;
        systolic_pe pe (
          .clk(clk), .rst_n(rst_n), .w_load(w_load),
          .w_in(w_flat[8*((r+c)%8)+7 -: 8]),
          .a_in(a[r][c]), .p_in(p[r][c]),
          .a_out(a_o), .p_out(p_o));
        assign a[r][c+1] = a_o;
        assign p[r+1][c] = p_o;
      end
    end
  endgenerate
endmodule
