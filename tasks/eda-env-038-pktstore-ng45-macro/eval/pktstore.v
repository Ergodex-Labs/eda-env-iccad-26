// pktstore: store-and-forward packet buffer with two ping-pong banks.
// A packet (up to 256 words of 32 bits, delimited by in_last) streams in
// on the input handshake and is stored whole in the filling bank. When a
// bank holds a complete packet, the packet streams out on the output
// handshake from that bank while the other bank fills. Each bank is a
// single-port SRAM: a bank that fills only writes, a bank that drains
// only reads, so the single port is never contended.
module pktstore (
    input             clk,
    input             rst_n,

    input             in_valid,
    input      [31:0] in_data,
    input             in_last,
    output            in_ready,

    output reg        out_valid,
    output     [31:0] out_data,
    output reg        out_last,
    input             out_ready
);
    reg        full0, full1;      // bank holds a complete undrained packet
    reg        fill_sel;          // bank that fills next/now
    reg        drain_sel;         // bank that drains next/now
    reg [7:0]  wptr;
    reg [8:0]  rptr;         // 9 bits: counts up to 256 (no wrap at full banks)
    reg [8:0]  len0, len1;        // stored packet length in words (1..256)
    reg        out_bank;          // bank whose read data is on out_data

    // ---- fill side -------------------------------------------------------
    wire fill_full = fill_sel ? full1 : full0;
    assign in_ready = rst_n && !fill_full;
    wire in_fire  = in_valid && in_ready;
    // A packet ends on in_last, or is cut at the 256-word bank capacity.
    wire in_done  = in_fire && (in_last || (wptr == 8'd255));

    // ---- drain side ------------------------------------------------------
    wire       drain_full = drain_sel ? full1 : full0;
    wire [8:0] drain_len  = drain_sel ? len1 : len0;
    // Issue the next read when the drain bank is full and the output
    // register is free or being accepted this cycle.
    wire rd_issue  = drain_full && (out_ready || !out_valid)
                     && (rptr < drain_len);
    wire rd_islast = (rptr == (drain_len - 9'd1));
    wire out_fire_last = out_valid && out_ready && out_last;

    // ---- bank ports (never write and read the same bank) -----------------
    wire        we0 = in_fire  && (fill_sel  == 1'b0);
    wire        rd0 = rd_issue && (drain_sel == 1'b0);
    wire        cs0 = we0 || rd0;
    wire [7:0]  a0  = we0 ? wptr : rptr[7:0];
    wire [31:0] q0;
    spram_256x32 bank0 (
        .clk(clk), .cs(cs0), .we(we0), .addr(a0), .wdata(in_data), .rdata(q0)
    );

    wire        we1 = in_fire  && (fill_sel  == 1'b1);
    wire        rd1 = rd_issue && (drain_sel == 1'b1);
    wire        cs1 = we1 || rd1;
    wire [7:0]  a1  = we1 ? wptr : rptr[7:0];
    wire [31:0] q1;
    spram_256x32 bank1 (
        .clk(clk), .cs(cs1), .we(we1), .addr(a1), .wdata(in_data), .rdata(q1)
    );

    assign out_data = out_bank ? q1 : q0;

    // ---- state -----------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            full0     <= 1'b0;
            full1     <= 1'b0;
            fill_sel  <= 1'b0;
            drain_sel <= 1'b0;
            wptr      <= 8'd0;
            rptr      <= 9'd0;
            len0      <= 9'd0;
            len1      <= 9'd0;
            out_valid <= 1'b0;
            out_last  <= 1'b0;
            out_bank  <= 1'b0;
        end else begin
            // Fill completion: mark the bank full and switch fill banks.
            if (in_done) begin
                if (fill_sel) begin
                    full1 <= 1'b1;
                    len1  <= {1'b0, wptr} + 9'd1;
                end else begin
                    full0 <= 1'b1;
                    len0  <= {1'b0, wptr} + 9'd1;
                end
                fill_sel <= ~fill_sel;
                wptr     <= 8'd0;
            end else if (in_fire) begin
                wptr <= wptr + 8'd1;
            end

            // Read pipeline: the bank read registers into the SRAM output,
            // out_valid/out_last/out_bank track it in lockstep.
            if (rd_issue) begin
                out_valid <= 1'b1;
                out_last  <= rd_islast;
                out_bank  <= drain_sel;
                rptr      <= rptr + 9'd1;
            end else if (out_valid && out_ready) begin
                out_valid <= 1'b0;
            end

            // Drain completion: free the bank and switch drain banks.
            if (out_fire_last) begin
                if (drain_sel)
                    full1 <= 1'b0;
                else
                    full0 <= 1'b0;
                drain_sel <= ~drain_sel;
                rptr      <= 9'd0;
            end
        end
    end
endmodule
