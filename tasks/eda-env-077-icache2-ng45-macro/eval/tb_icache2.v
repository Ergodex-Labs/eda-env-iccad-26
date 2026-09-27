// tb_icache2: self-checking test for the F5 instruction cache
// (sealed gate collateral). Drives 600 reads with mixed locality
// (sequential runs and random jumps) against a 4096-word reference
// memory served on the miss side with irregular delays, and checks
// every response word. The same TB runs on the gold RTL (behavioral
// banks) and on the integrated RTL (fakeram45_256x32 kit
// model) — both must print TB_PASS.
`timescale 1ns/1ps
module tb_icache2;
    reg         clk = 0;
    reg         rst_n = 0;
    reg         cpu_valid = 0;
    reg  [11:0] cpu_addr = 0;
    wire        cpu_ready;
    wire        rsp_valid;
    wire [31:0] rsp_data;
    reg         rsp_ready = 0;
    wire        mem_req_valid;
    wire [11:0] mem_req_addr;
    wire        mem_rsp_ready;
    reg         mem_rsp_valid = 0;
    reg  [31:0] mem_rsp_data = 0;
    reg         mem_req_ready_r = 0;

    icache2 dut (
        .clk(clk), .rst_n(rst_n),
        .cpu_valid(cpu_valid), .cpu_addr(cpu_addr),
        .cpu_ready(cpu_ready),
        .rsp_valid(rsp_valid), .rsp_data(rsp_data),
        .rsp_ready(rsp_ready),
        .mem_req_valid(mem_req_valid), .mem_req_addr(mem_req_addr),
        .mem_req_ready(mem_req_ready_r),
        .mem_rsp_valid(mem_rsp_valid), .mem_rsp_data(mem_rsp_data),
        .mem_rsp_ready(mem_rsp_ready)
    );

    always #5 clk = ~clk;

    // Reference memory and the miss-side server (one outstanding
    // request; irregular grant and response delays).
    reg [31:0] mmodel [0:4095];
    reg        pend = 0;
    reg [11:0] paddr = 0;
    reg [31:0] sl = 32'h2468ace;
    always @(posedge clk) begin
        sl <= (sl >> 1) ^ (sl[0] ? 32'h80200003 : 32'h0);
        mem_req_ready_r <= !pend && !mem_rsp_valid && sl[1];
        if (mem_req_valid && mem_req_ready_r && !pend) begin
            pend  <= 1'b1;
            paddr <= mem_req_addr;
            mem_req_ready_r <= 1'b0;
        end
        if (pend && !mem_rsp_valid && sl[3]) begin
            mem_rsp_valid <= 1'b1;
            mem_rsp_data  <= mmodel[paddr];
        end
        if (mem_rsp_valid && mem_rsp_ready) begin
            mem_rsp_valid <= 1'b0;
            pend          <= 1'b0;
        end
    end

    // Driver: serial accesses, sequential runs + random jumps.
    reg [31:0] exp_seq [0:599];
    integer    n_recv = 0, errors = 0;
    reg [31:0] lfsr = 32'h1234567;
    reg [11:0] nxt = 0;
    integer ai, mi;
    initial begin
        for (mi = 0; mi < 4096; mi = mi + 1) begin
            lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
            mmodel[mi] = lfsr;
        end
        repeat (4) @(negedge clk);
        rst_n <= 1;
        @(negedge clk);
        for (ai = 0; ai < 600; ai = ai + 1) begin
            lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
            if (lfsr[1:0] == 2'b00)
                nxt = lfsr[13:2];        // jump
            else
                nxt = nxt + 12'd1;       // sequential run
            cpu_valid = 1;
            cpu_addr  = nxt;
            while (!cpu_ready) @(negedge clk);
            exp_seq[ai] = mmodel[nxt];
            @(posedge clk);              // request accepted here
            @(negedge clk);
            cpu_valid = 0;
            wait (n_recv == ai + 1);
            @(negedge clk);
        end
        repeat (10) @(negedge clk);
        if (n_recv == 600 && errors == 0)
            $display("TB_PASS recv=%0d", n_recv);
        else
            $display("TB_FAIL recv=%0d errors=%0d", n_recv, errors);
        $finish;
    end

    // Checker: irregular consumer (NBA-driven rsp_ready).
    reg [31:0] rl = 32'h89abcde;
    always @(posedge clk) begin
        if (rsp_valid && rsp_ready) begin
            if (rsp_data !== exp_seq[n_recv]) begin
                $display("TB_FAIL data %0d: got %h want %h",
                         n_recv, rsp_data, exp_seq[n_recv]);
                errors = errors + 1;
            end
            n_recv = n_recv + 1;
        end
        rl <= (rl >> 1) ^ (rl[0] ? 32'h80200003 : 32'h0);
        rsp_ready <= rl[2] | rl[7];
    end

    initial begin
        #3000000;
        $display("TB_FAIL timeout recv=%0d", n_recv);
        $finish;
    end
endmodule
