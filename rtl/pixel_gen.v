module pixel_gen (
    input wire       active, // high inside the 640x480 visible area
    input wire [9:0] x,      // pixel x coordinate
    input wire [9:0] y,      // pixel y coordinate
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    // 64x64 square centered on the 640x480 screen
    wire square = (x >= 288 && x < 352) && (y >= 208 && y < 272);
    wire show   = active && square;

    assign r = 4'h0;
    assign g = show ? 4'hf : 4'h0; //green square
    assign b = 4'h0;
endmodule