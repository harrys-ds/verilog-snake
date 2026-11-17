module game_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire       restart,        // button: start a new game
    input  wire       tick,           // the (gated) game tick

    input  wire [4:0] head_x,         // head position (already updated for this move)
    input  wire [3:0] head_y,
    input  wire       hit_occupied,   // map says the head's cell was already taken

    input  wire       clear_en,       // the tail cell being freed on this move
    input  wire [4:0] clear_x,
    input  wire [3:0] clear_y,

    output reg        game_over,
    output wire       game_rst        // reset for all the game logic
);
    reg tick_d;                       // same one-clock delay the body uses

    wire wall         = (head_x == 0) || (head_x == 19) ||
                        (head_y == 0) || (head_y == 14);
    wire tail_leaving = clear_en && (clear_x == head_x) && (clear_y == head_y);
    wire self_hit     = hit_occupied && !tail_leaving;

    assign game_rst = rst | restart;

    always @(posedge clk) begin
        if (game_rst) begin
            game_over <= 0;
            tick_d    <= 0;
        end else begin
            tick_d <= tick;
            if (tick_d && (wall || self_hit))
                game_over <= 1;       // once set, stays set until a restart
        end
    end
endmodule