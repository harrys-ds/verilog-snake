`timescale 1ns/1ps

module snake_top_tb;
    reg clk = 0;
    reg rst = 1;
    reg restart = 0;
    reg [3:0] btns = 0;              // {left, down, right, up}
    wire hsync, vsync, game_over;
    wire [3:0] r, g, b;
    integer errors;

    // the timer never fires on its own: this testbench injects every tick
    snake_top #(.TICK_DIV(100000000)) dut (
        .clk(clk), .rst(rst), .restart(restart),
        .btn_up(btns[0]), .btn_right(btns[1]),
        .btn_down(btns[2]), .btn_left(btns[3]),
        .hsync(hsync), .vsync(vsync), .game_over(game_over),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

    task tap(input [3:0] bt);
        begin
            @(negedge clk); btns = bt;
            repeat (5) @(negedge clk);
            btns = 0;
            repeat (4) @(negedge clk);
        end
    endtask

    task game_tick_once;
        begin
            @(negedge clk); force dut.core.tick = 1'b1;
            @(negedge clk); release dut.core.tick;
            repeat (6) @(negedge clk);
        end
    endtask

    task check_head(input [4:0] ex, input [3:0] ey, input integer id);
        begin
            if (dut.core.head_x !== ex || dut.core.head_y !== ey) begin
                errors = errors + 1;
                $display("FAIL case %0d: head at (%0d,%0d), expected (%0d,%0d)",
                         id, dut.core.head_x, dut.core.head_y, ex, ey);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        repeat (50) @(negedge clk);

        check_head(10, 7, 1);              // start

        tap(4'b0001); game_tick_once;      // up
        check_head(10, 6, 2);

        tap(4'b1000); game_tick_once;      // left
        check_head(9, 6, 3);

        tap(4'b0010); game_tick_once;      // right is a U-turn: ignored, keeps going left
        check_head(8, 6, 4);

        tap(4'b0100); game_tick_once;      // down
        check_head(8, 7, 5);

        if (game_over !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: game ended unexpectedly");
        end

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule