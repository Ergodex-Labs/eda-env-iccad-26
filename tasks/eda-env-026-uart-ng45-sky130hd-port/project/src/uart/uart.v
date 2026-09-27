// uart: 8N1 transmitter + receiver with a 16x-oversampling baud
// generator (divisor programmable). Frozen F1 RTL (eda-env Sky130hd row).
module uart #(
  parameter DIV_W = 16
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire [DIV_W-1:0] baud_div,
  // TX
  input  wire  [7:0]      tx_data,
  input  wire             tx_valid,
  output reg              tx_ready,
  output reg              txd,
  // RX
  input  wire             rxd,
  output reg  [7:0]       rx_data,
  output reg              rx_valid
);
  // baud tick (16x oversample)
  reg [DIV_W-1:0] div_cnt;
  wire tick16 = (div_cnt == baud_div);
  always @(posedge clk) begin
    if (!rst_n) div_cnt <= {DIV_W{1'b0}};
    else div_cnt <= tick16 ? {DIV_W{1'b0}} : div_cnt + 1'b1;
  end
  // ---- TX ----
  reg [3:0] tx_os;      // oversample phase
  reg [3:0] tx_bit;     // 0 start, 1-8 data, 9 stop
  reg [7:0] tx_sh;
  reg       tx_busy;
  always @(posedge clk) begin
    if (!rst_n) begin
      txd <= 1'b1; tx_busy <= 1'b0; tx_ready <= 1'b1;
      tx_os <= 4'd0; tx_bit <= 4'd0; tx_sh <= 8'd0;
    end else begin
      if (!tx_busy) begin
        tx_ready <= 1'b1;
        if (tx_valid) begin
          tx_sh <= tx_data; tx_busy <= 1'b1; tx_ready <= 1'b0;
          tx_bit <= 4'd0; tx_os <= 4'd0; txd <= 1'b0; // start bit
        end
      end else if (tick16) begin
        if (tx_os == 4'hF) begin
          tx_os <= 4'd0;
          tx_bit <= tx_bit + 4'd1;
          if (tx_bit < 4'd8) begin
            txd <= tx_sh[0]; tx_sh <= {1'b0, tx_sh[7:1]};
          end else if (tx_bit == 4'd8) begin
            txd <= 1'b1; // stop bit
          end else begin
            tx_busy <= 1'b0; tx_ready <= 1'b1;
          end
        end else tx_os <= tx_os + 4'd1;
      end
    end
  end
  // ---- RX ----
  reg [1:0] rxd_q;
  reg [3:0] rx_os;
  reg [3:0] rx_bit;
  reg [7:0] rx_sh;
  reg       rx_busy;
  always @(posedge clk) begin
    if (!rst_n) begin
      rxd_q <= 2'b11; rx_busy <= 1'b0; rx_valid <= 1'b0;
      rx_os <= 4'd0; rx_bit <= 4'd0; rx_sh <= 8'd0; rx_data <= 8'd0;
    end else begin
      rx_valid <= 1'b0;
      if (tick16) begin
        rxd_q <= {rxd_q[0], rxd};
        if (!rx_busy) begin
          if (rxd_q[1] == 1'b0) begin // start edge seen
            rx_busy <= 1'b1; rx_os <= 4'd8; rx_bit <= 4'd0; // mid-bit align
          end
        end else begin
          if (rx_os == 4'hF) begin
            rx_os <= 4'd0;
            rx_bit <= rx_bit + 4'd1;
            if (rx_bit < 4'd8) rx_sh <= {rxd_q[1], rx_sh[7:1]};
            else begin // stop bit position
              rx_busy <= 1'b0;
              rx_data <= rx_sh;
              rx_valid <= (rxd_q[1] == 1'b1);
            end
          end else rx_os <= rx_os + 4'd1;
        end
      end
    end
  end
endmodule
