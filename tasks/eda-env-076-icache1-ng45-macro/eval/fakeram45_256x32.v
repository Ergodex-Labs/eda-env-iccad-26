// fakeram45_256x32 — behavioral model for the Nangate45 fakeram macro.
// Part of the F5 macro kit. The physical views are the platform's frozen
// fakeram45_256x32.lef/.lib. Control pins are ACTIVE-LOW (same polarity
// as the ariane133 macros.v wrapper in the same platform):
//   ce_in=0, we_in=0 -> masked write of wd_in at addr_in; rd_out holds.
//   ce_in=0, we_in=1 -> rd_out <= mem[addr_in] (1-cycle read latency).
//   ce_in=1          -> rd_out holds; memory unchanged.
module fakeram45_256x32 (
    input             clk,
    input             ce_in,
    input             we_in,
    input      [7:0]  addr_in,
    input      [31:0] wd_in,
    input      [31:0] w_mask_in,
    output reg [31:0] rd_out
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (!ce_in) begin
            if (!we_in)
                mem[addr_in] <= (wd_in & w_mask_in)
                              | (mem[addr_in] & ~w_mask_in);
            else
                rd_out <= mem[addr_in];
        end
    end
endmodule
