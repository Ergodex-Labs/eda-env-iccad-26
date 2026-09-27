// elevator_fsm: 8-floor elevator controller. Moore FSM with request
// latching, direction-scan arbitration, and door timing.
// Frozen F1 RTL (eda-env Sky130hd row).
module elevator_fsm (
  input  wire       clk,
  input  wire       rst_n,
  input  wire [7:0] req_up,
  input  wire [7:0] req_down,
  input  wire [7:0] req_car,
  output reg  [2:0] floor,
  output reg        moving_up,
  output reg        moving_down,
  output reg        door_open
);
  localparam S_IDLE = 3'd0, S_UP = 3'd1, S_DOWN = 3'd2,
             S_OPEN = 3'd3, S_WAIT = 3'd4;
  reg [2:0] state;
  reg [7:0] pending;
  reg [3:0] door_cnt;
  wire [7:0] reqs = req_up | req_down | req_car | pending;
  wire any_above = |(reqs & (8'hFF << floor) & ~(8'h01 << floor));
  wire any_below = |(reqs & ~(8'hFF << floor));
  wire here      = reqs[floor];
  always @(posedge clk) begin
    if (!rst_n) begin
      state <= S_IDLE; floor <= 3'd0; pending <= 8'd0; door_cnt <= 4'd0;
      moving_up <= 1'b0; moving_down <= 1'b0; door_open <= 1'b0;
    end else begin
      pending <= (pending | req_up | req_down | req_car)
                 & ~(door_open ? (8'h01 << floor) : 8'h00);
      case (state)
        S_IDLE: begin
          moving_up <= 1'b0; moving_down <= 1'b0; door_open <= 1'b0;
          if (here) state <= S_OPEN;
          else if (any_above) state <= S_UP;
          else if (any_below) state <= S_DOWN;
        end
        S_UP: begin
          moving_up <= 1'b1; moving_down <= 1'b0;
          floor <= floor + 3'd1;
          state <= S_WAIT;
        end
        S_DOWN: begin
          moving_down <= 1'b1; moving_up <= 1'b0;
          floor <= floor - 3'd1;
          state <= S_WAIT;
        end
        S_WAIT: begin
          if (here) state <= S_OPEN;
          else if (moving_up && any_above) state <= S_UP;
          else if (moving_down && any_below) state <= S_DOWN;
          else state <= S_IDLE;
        end
        S_OPEN: begin
          moving_up <= 1'b0; moving_down <= 1'b0; door_open <= 1'b1;
          door_cnt <= door_cnt + 4'd1;
          if (door_cnt == 4'hF) begin
            door_open <= 1'b0; door_cnt <= 4'd0; state <= S_IDLE;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
