// tb_keyvault1: self-checking test for the F5 key vault (sealed gate
// collateral). Loads all 32 keys with irregular source gaps,
// fetches them in a shuffled order against an irregular consumer, and
// checks every word and last flag. The same TB runs on the gold RTL
// (behavioral bank) and on the integrated RTL (fakeram45_256x32 kit
// model) — both must print TB_PASS.
//
// Handshake discipline (038 pattern): all stimulus changes on
// negedge; a transfer happens at the posedge for which valid && ready
// held through the preceding half-cycle. The checker samples at
// posedge, where the pre-edge values are what the edge consumes.
`timescale 1ns/1ps
module tb_keyvault1;
    reg              clk = 0;
    reg              rst_n = 0;
    reg              ld_valid = 0;
    reg  [4:0] ld_index = 0;
    reg  [31:0]      ld_data = 0;
    wire             ld_ready;
    reg              fk_valid = 0;
    reg  [4:0] fk_index = 0;
    wire             fk_ready;
    wire             out_valid;
    wire [31:0]      out_data;
    wire             out_last;
    reg              out_ready = 0;

    keyvault1 dut (
        .clk(clk), .rst_n(rst_n),
        .ld_valid(ld_valid), .ld_index(ld_index), .ld_data(ld_data),
        .ld_ready(ld_ready),
        .fk_valid(fk_valid), .fk_index(fk_index), .fk_ready(fk_ready),
        .out_valid(out_valid), .out_data(out_data), .out_last(out_last),
        .out_ready(out_ready)
    );

    always #5 clk = ~clk;

    reg [31:0] ref_mem [0:255];
    reg [31:0] exp_seq [0:255];
    integer    n_recv = 0, errors = 0;
    reg [31:0] lfsr = 32'h1234567;

    integer ki, wi, kj, ks;
    initial begin
        repeat (4) @(negedge clk);
        rst_n <= 1;
        @(negedge clk);
        // Load every key, with irregular source gaps.
        for (ki = 0; ki < 32; ki = ki + 1) begin
            for (wi = 0; wi < 8; wi = wi + 1) begin
                lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
                while (lfsr[1:0] == 2'b00) begin
                    @(negedge clk);
                    lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
                end
                ld_valid = 1;
                ld_index = ki;
                ld_data  = lfsr;
                while (!ld_ready) @(negedge clk);
                ref_mem[ki*8 + wi] = lfsr;
                @(posedge clk);      // word accepted at this edge
                @(negedge clk);
                ld_valid = 0;
            end
        end
        // Fetch in shuffled order; wait out each 8-word response.
        for (kj = 0; kj < 32; kj = kj + 1) begin
            ks = (kj * 7 + 5) % 32;
            for (wi = 0; wi < 8; wi = wi + 1)
                exp_seq[kj*8 + wi] = ref_mem[ks*8 + wi];
            fk_valid = 1;
            fk_index = ks;
            while (!fk_ready) @(negedge clk);
            @(posedge clk);          // request accepted at this edge
            @(negedge clk);
            fk_valid = 0;
            wait (n_recv == (kj + 1) * 8);
            @(negedge clk);
        end
        repeat (10) @(negedge clk);
        if (n_recv == 256 && errors == 0)
            $display("TB_PASS recv=%0d", n_recv);
        else
            $display("TB_FAIL recv=%0d errors=%0d", n_recv, errors);
        $finish;
    end

    // Receiver: samples at posedge; out_ready is driven by NBA, so it
    // applies from the next cycle on (irregular consumer).
    reg [31:0] rl = 32'h89abcde;
    always @(posedge clk) begin
        if (out_valid && out_ready) begin
            if (out_data !== exp_seq[n_recv]) begin
                $display("TB_FAIL data %0d: got %h want %h",
                         n_recv, out_data, exp_seq[n_recv]);
                errors = errors + 1;
            end
            if (out_last !== ((n_recv % 8) == 7)) begin
                $display("TB_FAIL last %0d: got %b", n_recv, out_last);
                errors = errors + 1;
            end
            n_recv = n_recv + 1;
        end
        rl <= (rl >> 1) ^ (rl[0] ? 32'h80200003 : 32'h0);
        out_ready <= rl[2] | rl[7];
    end

    initial begin
        #4000000;
        $display("TB_FAIL timeout recv=%0d", n_recv);
        $finish;
    end
endmodule
