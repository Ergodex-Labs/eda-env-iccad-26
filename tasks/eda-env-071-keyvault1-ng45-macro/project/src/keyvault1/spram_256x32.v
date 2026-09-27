// spram_256x32: single-port synchronous SRAM bank, behavioral.
// Port contract (FROZEN — the module interface must not change):
//   cs=1, we=1 -> write wdata to addr; rdata holds.
//   cs=1, we=0 -> rdata <= mem[addr] (1-cycle read latency).
//   cs=0      -> rdata holds; memory unchanged.
module spram_256x32 (
    input             clk,
    input             cs,
    input             we,
    input      [7:0]  addr,
    input      [31:0] wdata,
    output reg [31:0] rdata
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (cs) begin
            if (we)
                mem[addr] <= wdata;
            else
                rdata <= mem[addr];
        end
    end
endmodule
