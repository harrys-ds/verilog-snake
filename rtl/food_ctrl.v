module food_ctrl (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick,          // game tick (the body consumes `grow` on it)
    input  wire [4:0]  head_x,
    input  wire [3:0]  head_y,
    input  wire [15:0] rnd,           // from the LFSR

    // ask the map whether a candidate cell is occupied
    output wire [4:0]  cand_x,
    output wire [3:0]  cand_y,
    input  wire        cand_occupied,

    output reg  [4:0]  food_x,
    output reg  [3:0]  food_y,
    output reg         food_valid,
    output reg         grow           // high from the moment food is eaten until the next tick
);
    // candidate cell taken straight from the random bits
    assign cand_x = rnd[4:0];
    assign cand_y = rnd[8:5];

    // food must stay inside the border and off the snake
    wire in_range = (cand_x >= 1) && (cand_x <= 18) &&
                    (cand_y >= 1) && (cand_y <= 13);
    wire cand_ok  = in_range && !cand_occupied;

    // the head has reached the food
    wire eaten = food_valid && (head_x == food_x) && (head_y == food_y);

    always @(posedge clk) begin
        if (rst) begin
            food_valid <= 0;
            food_x     <= 0;
            food_y     <= 0;
            grow       <= 0;
        end else begin
            if (tick) grow <= 0;               // the body latched it on this edge

            if (eaten) begin
                food_valid <= 0;               // start looking for a new spot
                grow       <= 1;
            end else if (!food_valid && cand_ok) begin
                food_x     <= cand_x;          // accept this candidate
                food_y     <= cand_y;
                food_valid <= 1;
            end
        end
    end
endmodule