module vga_top(
    input wire clk,        // ~25 MHz clock
    input wire rst,
    output wire hsync,
    output wire vsync,
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire active;
    wire [9:0] x, y;

    vga_sync sync (
        .clk(clk), .rst(rst),
        .hsync(hsync), .vsync(vsync),
        .active(active), .x(x), .y(y)
    );

    pixel_gen pixels (
        .active(active), .x(x), .y(y),
        .r(r), .g(g), .b(b)
    );
endmodule