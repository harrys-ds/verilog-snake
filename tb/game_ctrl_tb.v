`timescale 1ns/1ps

module game_ctrl_tb;
    reg clk = 0;
    reg rst = 1;
    reg restart = 0;
    reg tick = 0;
    reg [4:0] head_x = 10;
    reg [3:0] head_y = 7;
    reg hit_occupied = 0;
    reg clear_en = 0;
    reg [4:0] clear_x = 0;
    reg [3:0] clear_y = 0;
    wire game_over, game_rst;
    integer errors;

    game_ctrl dut (
        .clk(clk), .rst(rst), .restart(restart), .tick(tick),
        .head_x(head_x), .head_y(head_y), .hit_occupied(hit_occupied),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .game_over(game_over), .game_rst(game_rst)
    );

    always #20 clk = ~clk;

    // One game move: set up the situation, pulse the tick, let the result settle
    task try_move(input [4:0] hx, input [3:0] hy, input occ,
                  input cen, input [4:0] cx, input [3:0] cy);
        begin
            @(negedge clk);
            head_x = hx; head_y = hy; hit_occupied = occ;
            clear_en = cen; clear_x = cx; clear_y = cy;
            tick = 1;
            @(negedge clk); tick = 0;
            repeat (3) @(negedge clk);
        end
    endtask

    task do_restart;
        begin
            @(negedge clk); restart = 1;
            @(negedge clk);
            if (game_rst !== 1'b1) begin
                errors = errors + 1;
                $display("FAIL: game_rst not high while restart is pressed");
            end
            restart = 0;
            @(negedge clk);
        end
    endtask

    task expect_over(input expected, input integer id);
        begin
            if (game_over !== expected) begin
                errors = errors + 1;
                $display("FAIL case %0d: game_over=%b, expected %b", id, game_over, expected);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        @(negedge clk);

        expect_over(0, 1);                         // a new game is running

        try_move(5, 5, 0, 0, 0, 0);                // ordinary move
        expect_over(0, 2);

        try_move(19, 5, 0, 0, 0, 0);               // right wall
        expect_over(1, 3);
        try_move(5, 5, 0, 0, 0, 0);                // a later safe move doesn't undo it
        expect_over(1, 4);
        do_restart; expect_over(0, 5);             // restart clears it

        try_move(0, 5, 0, 0, 0, 0);                // left wall
        expect_over(1, 6);
        do_restart;

        try_move(5, 0, 0, 0, 0, 0);                // top wall
        expect_over(1, 7);
        do_restart;

        try_move(5, 14, 0, 0, 0, 0);               // bottom wall
        expect_over(1, 8);
        do_restart;

        try_move(6, 6, 1, 0, 0, 0);                // own body, tail not leaving
        expect_over(1, 9);
        do_restart;

        try_move(6, 6, 1, 1, 6, 6);                // into the cell the tail is leaving: legal
        expect_over(0, 10);

        try_move(8, 8, 1, 1, 7, 7);                // tail is leaving a different cell: crash
        expect_over(1, 11);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule