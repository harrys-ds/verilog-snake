module vga_top #(
    parameter TICK_DIV = 3125000     // clocks per game tick (~8 per second)
) (
    input  wire       clk,
    input  wire       rst,
    input  wire [1:0] dir,           // 0 up, 1 right, 2 down, 3 left
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

    pixel_gen pixels (
        .active(active), .x(x), .y(y),
        .head_x(head_x), .head_y(head_y),
        .r(r), .g(g), .b(b)
    );
endmodule