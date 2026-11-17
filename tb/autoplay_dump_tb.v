`timescale 1ns/1ps

module autoplay_dump_tb;
    reg clk = 0;
    reg rst = 1;
    reg [1:0] dir = 2'd1;            // start moving right
    reg grow = 0;
    wire hsync, vsync;
    wire [3:0] r, g, b;
    integer f, n;
    reg [1:0] want;

    // TICK_DIV is huge, so the timer never fires: this testbench injects every tick itself
    vga_top #(.TICK_DIV(100000000)) dut (
        .clk(clk), .rst(rst), .dir(dir), .grow(grow),
        .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

    // Save one full frame as a PPM image
    task dump_frame(input integer fd);
        begin
            $fwrite(fd, "P3\n640 480\n255\n");
            repeat (800 * 525) begin
                @(posedge clk);
                if (dut.active)
                    $fwrite(fd, "%0d %0d %0d\n", r * 17, g * 17, b * 17);
            end
            $fclose(fd);
        end
    endtask

    // Force one game tick, then give the design a few clocks to finish moving
    task game_tick_once;
        begin
            @(negedge clk); force dut.tick = 1'b1;
            @(negedge clk); release dut.tick;
            repeat (6) @(negedge clk);
        end
    endtask

    // Pick a direction toward the food, without reversing straight into the body
    task steer;
        begin
            if (dut.food_valid) begin
                if      (dut.head_x < dut.food_x) want = 2'd1;   // right
                else if (dut.head_x > dut.food_x) want = 2'd3;   // left
                else if (dut.head_y < dut.food_y) want = 2'd2;   // down
                else                              want = 2'd0;   // up

                if ((want == 2'd1 && dir == 2'd3) || (want == 2'd3 && dir == 2'd1) ||
                    (want == 2'd0 && dir == 2'd2) || (want == 2'd2 && dir == 2'd0)) begin
                    // that would be a U-turn: sidestep instead
                    if (dir == 2'd1 || dir == 2'd3) dir = (dut.head_y < 13) ? 2'd2 : 2'd0;
                    else                            dir = (dut.head_x < 18) ? 2'd1 : 2'd3;
                end else begin
                    dir = want;
                end
            end
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (50) @(posedge clk);          // let the first food appear

        f = $fopen("food_start.ppm", "w");
        dump_frame(f);                       // length 1, one red food cell

        // play until the snake has eaten three pieces of food (length 4)
        n = 0;
        while (dut.length < 4 && n < 300 && !dut.game_over) begin            steer;
            game_tick_once;
            n = n + 1;
        end

        $display("length %0d after %0d moves", dut.length, n);

        f = $fopen("food_end.ppm", "w");
        dump_frame(f);                       // grown snake, new food somewhere else

        $finish;
    end
endmodule