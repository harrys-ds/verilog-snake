module vga_top #(
    parameter TICK_DIV = 3125000     // clocks per game tick (~8 per second)
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] dir,           // 0 up, 1 right, 2 down, 3 left
    input  wire       grow,          // 1 = snake grows on its next move
    output wire       hsync,
    output wire       vsync,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire        active;
    wire [9:0]  x, y;
    wire        tick;
    wire [4:0]  head_x;
    wire [3:0]  head_y;

    wire        set_en, clear_en;
    wire [4:0]  set_x, clear_x;
    wire [3:0]  set_y, clear_y;
    wire [8:0]  length;
    wire        body_occupied;

    vga_sync sync (
        .clk(clk), .rst(rst),
        .hsync(hsync), .vsync(vsync),
        .active(active), .x(x), .y(y)
    );

    game_tick #(.DIV(TICK_DIV)) ticker (
        .clk(clk), .rst(rst), .tick(tick)
    );

    snake_head head (
        .clk(clk), .rst(rst), .tick(tick), .dir(dir),
        .head_x(head_x), .head_y(head_y)
    );

    snake_body body (
        .clk(clk), .rst(rst), .tick(tick), .grow(grow),
        .head_x(head_x), .head_y(head_y),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .length(length)
    );

    snake_map map (
        .clk(clk), .rst(rst),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .rd_x(x[9:5]), .rd_y(y[8:5]),
        .rd_occupied(body_occupied)
    );

    pixel_gen pixels (
        .active(active), .x(x), .y(y),
        .head_x(head_x), .head_y(head_y),
        .body_occupied(body_occupied),
        .r(r), .g(g), .b(b)
    );
endmodule