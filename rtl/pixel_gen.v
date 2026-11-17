module pixel_gen (
    input  wire       active,
    input  wire [9:0] x,
    input  wire [9:0] y,
    input  wire [4:0] head_x,         // snake head cell column
    input  wire [3:0] head_y,         // snake head cell row
    input  wire       body_occupied,  // map says this pixel's cell holds a snake segment
    input  wire [4:0] food_x,         // food cell
    input  wire [3:0] food_y,
    input  wire       food_valid,     // 0 while a new food spot is being chosen
    input  wire       game_over,      // 1 = the game has ended  
    output wire [3:0] r,
    output wire [3:0] g,
    output wire [3:0] b
);
    wire [4:0] cell_x = x[9:5];
    wire [3:0] cell_y = y[8:5];

    wire border  = (cell_x == 0) || (cell_x == 19) ||
                   (cell_y == 0) || (cell_y == 14);
    wire is_head = (cell_x == head_x) && (cell_y == head_y);
    wire is_food = food_valid && (cell_x == food_x) && (cell_y == food_y);

    // head = bright green, other body cells = dim green, otherwise off
    wire [3:0] green_level = is_head ? 4'hF : (body_occupied ? 4'h8 : 4'h0);

    assign r = (active && (is_food || (game_over && border))) ? 4'hF : 4'h0;
    assign g = active ? green_level : 4'h0;
    assign b = (active && border && !game_over)               ? 4'hF : 4'h0;
endmodule