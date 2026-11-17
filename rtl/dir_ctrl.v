module dir_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,         // the tick the snake head moves on
    input  wire       btn_up,
    input  wire       btn_right,
    input  wire       btn_down,
    input  wire       btn_left,
    output wire [1:0] dir           // 0 up, 1 right, 2 down, 3 left
);
    reg [3:0] s1, s2;               // two-stage synchronizer for the buttons
    reg [1:0] dir_cur;              // direction of the last move
    reg [1:0] dir_next;             // direction requested for the next move

    wire pressed = |s2;
    wire [1:0] request = s2[0] ? 2'd0 :     // up has priority if several are pressed
                         s2[1] ? 2'd1 :
                         s2[2] ? 2'd2 : 2'd3;

    // On a tick edge the head moves in dir_next, so that is what a new request
    // must not reverse; otherwise compare against the last move.
    wire [1:0] ref_dir = tick ? dir_next : dir_cur;
    wire legal = pressed && (request != (ref_dir ^ 2'b10));

    always @(posedge clk) begin
        if (rst) begin
            s1       <= 4'b0;
            s2       <= 4'b0;
            dir_cur  <= 2'd1;       // start moving right
            dir_next <= 2'd1;
        end else begin
            s1 <= {btn_left, btn_down, btn_right, btn_up};
            s2 <= s1;
            if (tick)  dir_cur  <= dir_next;
            if (legal) dir_next <= request;
        end
    end

    assign dir = dir_next;
endmodule