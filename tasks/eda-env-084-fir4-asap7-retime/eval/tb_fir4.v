// tb_fir4: sealed contract testbench for the F12.6 retime task.
// Drives a free-running input stream and checks that the output
// during every cycle c (after warm-up) equals
//   13*x[c-4] + 7*x[c-5] + 5*x[c-6] + 3*x[c-7]
// — i.e. the FIR function at EXACTLY 4 cycles of latency. A retimed
// implementation passes; a functionally different or re-latencied one
// does not. Prints TB_PASS / TB_FAIL.
`timescale 1ns/1ps
module tb_fir4;
    reg         clk = 0;
    reg         rst_n = 0;
    reg  [15:0] x = 0;
    wire [21:0] y;

    fir4 dut (.clk(clk), .rst_n(rst_n), .x(x), .y(y));

    always #5 clk = ~clk;

    reg [15:0] xs [0:4095];
    integer    c = 0, errors = 0, checked = 0;
    reg [31:0] lfsr = 32'h1234567;
    reg [21:0] exp;

    initial begin
        repeat (4) @(negedge clk);
        rst_n <= 1;
    end

    always @(negedge clk) begin
        if (rst_n) begin
            lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
            x = lfsr[15:0];
        end
    end

    always @(posedge clk) begin
        if (rst_n) begin
            xs[c] = x;               // input sampled at the end of cycle c
            if (c >= 12) begin
                exp = 22'd13*xs[c-4] + 22'd7*xs[c-5]
                    + 22'd5*xs[c-6] + 22'd3*xs[c-7];
                if (y !== exp) begin
                    if (errors < 5)
                        $display("TB_FAIL y at c=%0d: got %d want %d",
                                 c, y, exp);
                    errors = errors + 1;
                end
                checked = checked + 1;
            end
            c = c + 1;
        end
    end

    initial begin
        #22000;
        if (checked >= 2000 && errors == 0)
            $display("TB_PASS checked=%0d", checked);
        else
            $display("TB_FAIL checked=%0d errors=%0d", checked, errors);
        $finish;
    end
endmodule
