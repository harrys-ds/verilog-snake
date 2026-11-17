module snake_head (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,       // one-clock pulse: time to move
    input  wire [1:0] dir,        // 0 up, 1 right, 2 down, 3 left
    output reg  [4:0] head_x,     // cell column
    output reg  [3:0] head_y      // cell row
);
    localparam UP = 2'd0, RIGHT = 2'd1, DOWN = 2'd2, LEFT = 2'd3;

    always @(posedge clk) begin
        if (rst) begin
            head_x <= 10;         // start near the middle
            head_y <= 7;
        end else if (tick) begin
            case (dir)
                UP:    head_y <= head_y - 1;
                RIGHT: head_x <= head_x + 1;
                DOWN:  head_y <= head_y + 1;
                LEFT:  head_x <= head_x - 1;
            endcase
        end
    end
endmodule
