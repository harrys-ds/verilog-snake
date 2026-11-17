`timescale 1ns/1ps

module food_ctrl_tb;
    reg clk = 0;
    reg rst = 1;
    reg tick = 0;
    reg [4:0] head_x = 10;
    reg [3:0] head_y = 7;

    wire [15:0] rnd;
    wire [4:0]  cand_x, food_x;
    wire [3:0]  cand_y, food_y;
    wire        cand_occ, food_valid, grow;

    reg        set_en = 0;
    reg [4:0]  set_x = 0;
    reg [3:0]  set_y = 0;

    reg [299:0] shadow;        // our own record of which cells we marked
    integer errors, i, waited;
    reg [4:0] fx;
    reg [3:0] fy;

    lfsr16 rng (.clk(clk), .rst(rst), .q(rnd));

    snake_map map (
        .clk(clk), .rst(rst),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(1'b0), .clear_x(5'd0), .clear_y(4'd0),
        .rd_x(5'd0), .rd_y(4'd0), .rd_occupied(),
        .rd2_x(cand_x), .rd2_y(cand_y), .rd2_occupied(cand_occ)
    );

    food_ctrl dut (
        .clk(clk), .rst(rst), .tick(tick),
        .head_x(head_x), .head_y(head_y), .rnd(rnd),
        .cand_x(cand_x), .cand_y(cand_y), .cand_occupied(cand_occ),
        .food_x(food_x), .food_y(food_y), .food_valid(food_valid),
        .grow(grow)
    );

    always #20 clk = ~clk;

    // Wait (up to 200 clocks) until food exists
    task wait_food;
        begin
            waited = 0;
            while (!food_valid && waited < 200) begin
                @(negedge clk);
                waited = waited + 1;
            end
            if (!food_valid) begin
                errors = errors + 1;
                $display("FAIL: no food appeared within 200 clocks");
            end
        end
    endtask

    // The food must be inside the border and not on a cell we marked
    task check_food(input integer id);
        begin
            if (food_x < 1 || food_x > 18 || food_y < 1 || food_y > 13) begin
                errors = errors + 1;
                $display("FAIL case %0d: food (%0d,%0d) is outside the border", id, food_x, food_y);
            end
            if (shadow[food_y * 20 + food_x]) begin
                errors = errors + 1;
                $display("FAIL case %0d: food (%0d,%0d) is on the snake", id, food_x, food_y);
            end
        end
    endtask

    initial begin
        errors = 0;
        shadow = 300'b0;

        repeat (4) @(negedge clk);
        rst = 0;

        // the snake starts as one cell at (10,7), marked in the map like the body would
        @(negedge clk); set_x = 10; set_y = 7; set_en = 1; shadow[7 * 20 + 10] = 1;
        @(negedge clk); set_en = 0;

        wait_food;
        check_food(0);

        // eat 40 pieces of food in a row
        for (i = 1; i <= 40; i = i + 1) begin
            fx = food_x;
            fy = food_y;

            // head arrives on the food, and the map marks that cell at the same time
            @(negedge clk);
            head_x = fx; head_y = fy;
            set_x = fx;  set_y = fy;  set_en = 1;
            shadow[fy * 20 + fx] = 1;
            @(negedge clk);
            set_en = 0;

            // right after eating: food is gone and grow is raised
            if (food_valid !== 1'b0 || grow !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL round %0d: after eating, food_valid=%b grow=%b", i, food_valid, grow);
            end

            // a new food must appear in a legal spot
            wait_food;
            check_food(i);

            // the next tick consumes grow
            @(negedge clk); tick = 1;
            @(negedge clk); tick = 0;
            @(negedge clk);
            if (grow !== 1'b0) begin
                errors = errors + 1;
                $display("FAIL round %0d: grow did not clear on tick", i);
            end
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule