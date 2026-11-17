module pixel_gen (
    input  wire       active,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [4:0] head_x,   // snake head cell column
    input  wire [3:0] head_y,   // snake head cell row
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire [4:0] cell_x = x[9:5];
    wire [3:0] cell_y = y[8:5];

    wire border  = (cell_x == 0) || (cell_x == 19) ||
                   (cell_y == 0) || (cell_y == 14);

    // Is the pixel being drawn inside the head's cell?
    wire is_head = (cell_x == head_x) && (cell_y == head_y);

    assign r = 4'h0;
    assign g = (active && is_head) ? 4'hF : 4'h0;
    assign b = (active && border)  ? 4'hF : 4'h0;
endmodule