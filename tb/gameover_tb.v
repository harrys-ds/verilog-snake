`timescale 1ns/1ps

module gameover_tb;
    reg clk = 0;
    reg rst = 1;
    reg restart = 0;
    reg [1:0] dir = 2'd1;            // moving right
    reg grow = 0;
    wire hsync, vsync, game_over;
    wire [3:0] r, g, b;
    integer f, errors;

    // the timer never fires on its own: this testbench injects every tick
    vga_top #(.TICK_DIV(100000000)) dut (
        .clk(clk), .rst(rst), .restart(restart), .dir(dir), .grow(grow),
        .hsync(hsync), .vsync(vsync), .game_over(game_over),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

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

    task game_tick_once;
        begin
            @(negedge clk); force dut.tick = 1'b1;
            @(negedge clk); release dut.tick;
            repeat (6) @(negedge clk);
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (50) @(posedge clk);

        // from column 10, nine moves right put the head on column 19: the wall
        repeat (9) game_tick_once;
        if (game_over !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: game did not end at the wall");
        end
        if (dut.head_x !== 5'd19) begin
            errors = errors + 1;
            $display("FAIL: head is at column %0d, expected 19", dut.head_x);
        end

        // further ticks must be ignored
        repeat (3) game_tick_once;
        if (dut.head_x !== 5'd19) begin
            errors = errors + 1;
            $display("FAIL: snake kept moving after game over (column %0d)", dut.head_x);
        end

        f = $fopen("gameover.ppm", "w");
        dump_frame(f);

        // restart: everything back to a fresh game
        @(negedge clk); restart = 1;
        @(negedge clk); restart = 0;
        repeat (5) @(negedge clk);
        if (game_over !== 1'b0 || dut.head_x !== 5'd10 ||
            dut.head_y !== 4'd7 || dut.length !== 9'd1) begin
            errors = errors + 1;
            $display("FAIL: restart did not reset the game");
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule