module snake_top #(
    parameter TICK_DIV = 3125000
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       restart,
    input  wire       btn_up,
    input  wire       btn_right,
    input  wire       btn_down,
    input  wire       btn_left,
    output wire       hsync,
    output wire       vsync,
    output wire       game_over,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire [1:0] dir;
    wire       move_tick;

    // a restart also puts the direction back to "right"
    dir_ctrl dirs (
        .clk(clk), .rst(rst | restart), .tick(move_tick),
        .btn_up(btn_up), .btn_right(btn_right),
        .btn_down(btn_down), .btn_left(btn_left),
        .dir(dir)
    );

    vga_top #(.TICK_DIV(TICK_DIV)) core (
        .clk(clk), .rst(rst), .restart(restart), .dir(dir), .grow(1'b0),
        .hsync(hsync), .vsync(vsync), .game_over(game_over),
        .move_tick(move_tick),
        .r(r), .g(g), .b(b)
    );
endmodule