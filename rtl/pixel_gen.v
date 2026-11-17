module pixel_gen (
    input  wire       active, // high inside the 640x480 visible area
    input  wire [9:0] x,      // pixel x coordinate
    input  wire [9:0] y,      // pixel y coordinate
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    // Which 32x32 cell is this pixel in? (20 columns x 15 rows)
    wire [4:0] cell_x = x[9:5];   // 0..19
    wire [3:0] cell_y = y[8:5];   // 0..14

    // Border: the outermost ring of cells
    wire border = (cell_x == 0) || (cell_x == 19) ||
                  (cell_y == 0) || (cell_y == 14);

    // One test cell near the middle
    wire test_cell = (cell_x == 10) && (cell_y == 7);

    assign r = 4'h0;
    assign g = (active && test_cell) ? 4'hF : 4'h0;   // green cell
    assign b = (active && border)    ? 4'hF : 4'h0;   // blue border
endmodule