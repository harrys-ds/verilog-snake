module vga_top #(
    parameter TICK_DIV = 3125000     // clocks per game tick (~8 per second)
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       restart,       // button: start a new game
    input  wire [1:0] dir,           // 0 up, 1 right, 2 down, 3 left
    input  wire       grow,          // forces growth on the next move (for testing)
    output wire       hsync,
    output wire       vsync,
    output wire       game_over,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire        active;
    wire [9:0]  x, y;
    wire        tick;                // raw tick from the timer
    wire        tick_run = tick & ~game_over;   // no moving once the game is over
    wire        game_rst;
    wire [4:0]  head_x;
    wire [3:0]  head_y;

    wire        set_en, clear_en;
    wire [4:0]  set_x, clear_x;
    wire [3:0]  set_y, clear_y;
    wire [8:0]  length;
    wire        body_occupied, head_cell_occupied;

    wire [15:0] rnd;
    wire [4:0]  cand_x, food_x;
    wire [3:0]  cand_y, food_y;
    wire        cand_occupied, food_valid, food_grow;

    wire        grow_all = grow | food_grow;

    // video timing is never restarted by the game
    vga_sync sync (
        .clk(clk), .rst(rst),
        .hsync(hsync), .vsync(vsync),
        .active(active), .x(x), .y(y)
    );

    game_ctrl ctrl (
        .clk(clk), .rst(rst), .restart(restart), .tick(tick_run),
        .head_x(head_x), .head_y(head_y), .hit_occupied(head_cell_occupied),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .game_over(game_over), .game_rst(game_rst)
    );

    // everything below restarts with the game
    game_tick #(.DIV(TICK_DIV)) ticker (
        .clk(clk), .rst(game_rst), .tick(tick)
    );

    snake_head head (
        .clk(clk), .rst(game_rst), .tick(tick_run), .dir(dir),
        .head_x(head_x), .head_y(head_y)
    );

    snake_body body (
        .clk(clk), .rst(game_rst), .tick(tick_run), .grow(grow_all),
        .head_x(head_x), .head_y(head_y),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .length(length)
    );

    snake_map map (
        .clk(clk), .rst(game_rst),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .rd_x(x[9:5]), .rd_y(y[8:5]), .rd_occupied(body_occupied),
        .rd2_x(cand_x), .rd2_y(cand_y), .rd2_occupied(cand_occupied),
        .rd3_x(head_x), .rd3_y(head_y), .rd3_occupied(head_cell_occupied)
    );

    // the random generator keeps running across restarts, so each game differs
    lfsr16 rng (
        .clk(clk), .rst(rst), .q(rnd)
    );

    food_ctrl food (
        .clk(clk), .rst(game_rst), .tick(tick_run),
        .head_x(head_x), .head_y(head_y), .rnd(rnd),
        .cand_x(cand_x), .cand_y(cand_y), .cand_occupied(cand_occupied),
        .food_x(food_x), .food_y(food_y), .food_valid(food_valid),
        .grow(food_grow)
    );

    pixel_gen pixels (
        .active(active), .x(x), .y(y),
        .head_x(head_x), .head_y(head_y),
        .body_occupied(body_occupied),
        .food_x(food_x), .food_y(food_y), .food_valid(food_valid),
        .game_over(game_over),
        .r(r), .g(g), .b(b)
    );
endmodule