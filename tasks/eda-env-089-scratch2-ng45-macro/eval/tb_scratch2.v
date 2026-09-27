// tb_scratch2: self-checking test for the F5 scratchpad (sealed gate
// collateral). Drives concurrent, irregularly-gapped write and read
// streams, models the memory from the OBSERVED handshakes, and
// checks every read response in accept order. The same TB runs on
// the gold RTL (behavioral banks) and on the integrated RTL
// (fakeram45_256x32 kit model) — both must print TB_PASS.
`timescale 1ns/1ps
module tb_scratch2;
    reg              clk = 0;
    reg              rst_n = 0;
    reg              wr_valid = 0;
    reg  [8:0] wr_addr = 0;
    reg  [31:0]      wr_data = 0;
    wire             wr_ready;
    reg              rd_valid = 0;
    reg  [8:0] rd_addr = 0;
    wire             rd_ready;
    wire             rrsp_valid;
    wire [31:0]      rrsp_data;
    reg              rrsp_ready = 0;

    scratch2 dut (
        .clk(clk), .rst_n(rst_n),
        .wr_valid(wr_valid), .wr_addr(wr_addr), .wr_data(wr_data),
        .wr_ready(wr_ready),
        .rd_valid(rd_valid), .rd_addr(rd_addr), .rd_ready(rd_ready),
        .rrsp_valid(rrsp_valid), .rrsp_data(rrsp_data),
        .rrsp_ready(rrsp_ready)
    );

    always #5 clk = ~clk;

    reg [31:0] model  [0:512-1];
    reg        minit  [0:512-1];
    reg [31:0] exp_q  [0:4095];
    integer    eq_w = 0, eq_r = 0, errors = 0;
    integer    n_wr = 0, n_rd = 0;
    reg [31:0] wl = 32'h1234567;
    reg [31:0] rlx = 32'h7654321;
    integer mi;

    initial begin
        for (mi = 0; mi < 512; mi = mi + 1) begin
            model[mi] = 32'd0; minit[mi] = 1'b0;
        end
        repeat (4) @(negedge clk);
        rst_n <= 1;
    end

    // Writer: irregular stream of 900 writes.
    always @(negedge clk) begin
        if (rst_n && n_wr < 900) begin
            wl = (wl >> 1) ^ (wl[0] ? 32'h80200003 : 32'h0);
            wr_valid = wl[1] | wl[5];
            wr_addr  = wl[8+8:8];
            wr_data  = {wl[15:0], wl[31:16]};
        end else
            wr_valid = 0;
    end

    // Reader: irregular stream over INITIALIZED addresses only.
    always @(negedge clk) begin
        if (rst_n && n_rd < 700) begin
            rlx = (rlx >> 1) ^ (rlx[0] ? 32'h80200003 : 32'h0);
            rd_addr  = rlx[8+6:6];
            rd_valid = (rlx[2] | rlx[9]) && minit[rd_addr];
        end else
            rd_valid = 0;
    end

    // Observer: model from the handshakes; check responses in order.
    always @(posedge clk) begin
        if (rst_n) begin
            if (rd_valid && rd_ready) begin
                exp_q[eq_w] = model[rd_addr];
                eq_w = eq_w + 1;
                n_rd = n_rd + 1;
            end
            if (wr_valid && wr_ready) begin
                model[wr_addr] = wr_data;
                minit[wr_addr] = 1'b1;
                n_wr = n_wr + 1;
            end
            if (rrsp_valid && rrsp_ready) begin
                if (rrsp_data !== exp_q[eq_r]) begin
                    if (errors < 5)
                        $display("TB_FAIL rsp %0d: got %h want %h",
                                 eq_r, rrsp_data, exp_q[eq_r]);
                    errors = errors + 1;
                end
                eq_r = eq_r + 1;
            end
            rlx <= rlx;
        end
        rrsp_ready <= wl[3] | rlx[4];
    end

    initial begin
        #90000;
        if (n_rd >= 400 && eq_r == eq_w && errors == 0)
            $display("TB_PASS reads=%0d writes=%0d", eq_r, n_wr);
        else
            $display("TB_FAIL reads=%0d/%0d writes=%0d errors=%0d",
                     eq_r, eq_w, n_wr, errors);
        $finish;
    end
endmodule
