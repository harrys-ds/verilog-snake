`timescale 1ns/1ps

module dir_ctrl_tb;
    reg clk = 0;
    reg rst = 1;
    reg tick = 0;
    reg [3:0] btns = 0;              // {left, down, right, up}
    wire [1:0] dir;
    integer errors;

    dir_ctrl dut (
        .clk(clk), .rst(rst), .tick(tick),
        .btn_up(btns[0]), .btn_right(btns[1]),
        .btn_down(btns[2]), .btn_left(btns[3]),
        .dir(dir)
    );

    always #20 clk = ~clk;

    // Hold a button for a few clocks, release it, and let the result settle
    task tap(input [3:0] b);
        begin
            @(negedge clk); btns = b;
            repeat (5) @(negedge clk);
            btns = 0;
            repeat (4) @(negedge clk);
        end
    endtask

    task pulse_tick;
        begin
            @(negedge clk); tick = 1;
            @(negedge clk); tick = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task check(input [1:0] expected, input integer id);
        begin
            if (dir !== expected) begin
                errors = errors + 1;
                $display("FAIL case %0d: dir=%0d, expected %0d", id, dir, expected);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        repeat (2) @(negedge clk);

        check(1, 1);                       // starts moving right

        tap(4'b0001); check(0, 2);         // up is fine
        tap(4'b0100); check(2, 3);         // down is legal: the last real move was still "right"

        pulse_tick;   check(2, 4);         // the snake now moves down
        tap(4'b0001); check(2, 5);         // up would be a U-turn: ignored
        tap(4'b1000); check(3, 6);         // left is fine

        pulse_tick;   check(3, 7);         // the snake now moves left
        tap(4'b0001); check(0, 8);         // up is fine
        tap(4'b0010); check(0, 9);         // right is a U-turn against the last move: ignored

        // a button that arrives on the very edge of a tick (dir_next is up here)
        @(negedge clk); btns = 4'b0100;    // down is the opposite of up
        @(negedge clk);
        @(negedge clk);
        tick = 1;                          // this tick lands on the first edge that sees the button
        @(negedge clk);
        tick = 0; btns = 0;
        repeat (4) @(negedge clk);
        check(0, 10);                      // still up: the reversal must not slip through

        tap(4'b0100); check(0, 11);        // and down stays illegal after the move

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule