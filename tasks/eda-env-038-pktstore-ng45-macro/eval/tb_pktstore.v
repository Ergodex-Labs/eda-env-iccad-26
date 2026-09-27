// tb_pktstore: self-checking test for the F5 PoC design (sealed gate
// collateral). Streams packets with irregular valid/ready gaps through
// pktstore and checks every word and last flag in order. The same TB
// runs on the gold RTL (behavioral banks) and on the integrated RTL
// (fakeram45_256x32 kit model) — both must print TB_PASS.
//
// Handshake discipline: all stimulus changes on negedge; a transfer
// happens at the posedge for which valid && ready held through the
// preceding half-cycle. The checker samples at posedge, where the
// pre-edge values are exactly what the transfer edge consumes.
`timescale 1ns/1ps
module tb_pktstore;
    reg         clk = 0;
    reg         rst_n = 0;
    reg         in_valid = 0;
    reg  [31:0] in_data = 0;
    reg         in_last = 0;
    wire        in_ready;
    wire        out_valid;
    wire [31:0] out_data;
    wire        out_last;
    reg         out_ready = 0;

    pktstore dut (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_data(in_data), .in_last(in_last),
        .in_ready(in_ready),
        .out_valid(out_valid), .out_data(out_data), .out_last(out_last),
        .out_ready(out_ready)
    );

    always #5 clk = ~clk;

    // Expected stream: the DUT cuts a packet at 256 words, so the
    // reference splits the sent stream at in_last or every 256 words.
    reg [31:0] exp_data [0:4095];
    reg        exp_last [0:4095];
    integer    n_sent = 0, n_recv = 0, errors = 0;
    reg [31:0] lfsr = 32'h1234567;

    // Sender: packets of lengths 1, 3, 300 (cut at 256), 256, 40.
    integer pkt_lens [0:4];
    integer pi, wi, words_in_bank;
    initial begin
        pkt_lens[0] = 1; pkt_lens[1] = 3; pkt_lens[2] = 300;
        pkt_lens[3] = 256; pkt_lens[4] = 40;
        repeat (4) @(negedge clk);
        rst_n <= 1;
        @(negedge clk);
        words_in_bank = 0;
        for (pi = 0; pi < 5; pi = pi + 1) begin
            for (wi = 0; wi < pkt_lens[pi]; wi = wi + 1) begin
                lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
                // Irregular source gaps.
                while (lfsr[1:0] == 2'b00) begin
                    @(negedge clk);
                    lfsr = (lfsr >> 1) ^ (lfsr[0] ? 32'h80200003 : 32'h0);
                end
                // Drive the word at negedge; in_ready is stable here.
                in_valid = 1;
                in_data  = lfsr;
                in_last  = (wi == pkt_lens[pi] - 1);
                while (!in_ready) @(negedge clk);
                exp_data[n_sent] = lfsr;
                words_in_bank = words_in_bank + 1;
                exp_last[n_sent] = (wi == pkt_lens[pi] - 1)
                                   || (words_in_bank == 256);
                if (exp_last[n_sent]) words_in_bank = 0;
                n_sent = n_sent + 1;
                @(posedge clk);   // word accepted at this edge
                @(negedge clk);
                in_valid = 0;
                in_last  = 0;
            end
            words_in_bank = 0;
        end
    end

    // Receiver: samples at posedge, where pre-edge out_valid/out_ready/
    // out_data are exactly the values the transfer edge consumes.
    // out_ready is driven by NBA, so it applies from the next cycle on.
    reg [31:0] rl = 32'h89abcde;
    always @(posedge clk) begin
        if (out_valid && out_ready) begin
            if (out_data !== exp_data[n_recv]) begin
                $display("TB_FAIL data %0d: got %h want %h",
                         n_recv, out_data, exp_data[n_recv]);
                errors = errors + 1;
            end
            if (out_last !== exp_last[n_recv]) begin
                $display("TB_FAIL last %0d: got %b want %b",
                         n_recv, out_last, exp_last[n_recv]);
                errors = errors + 1;
            end
            n_recv = n_recv + 1;
        end
        rl <= (rl >> 1) ^ (rl[0] ? 32'h80200003 : 32'h0);
        out_ready <= rl[2] | rl[7];
    end

    initial begin
        #200000;
        if (n_recv == 600 && n_sent == 600 && errors == 0)
            $display("TB_PASS recv=%0d", n_recv);
        else
            $display("TB_FAIL recv=%0d sent=%0d errors=%0d",
                     n_recv, n_sent, errors);
        $finish;
    end
endmodule
