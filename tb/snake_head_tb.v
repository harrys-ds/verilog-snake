`timescale 1ns/1ps

module snake_head_tb;
    reg clk = 0;
    reg rst = 1;
    reg tick = 0;
    reg [1:0] dir = 0;
    wire [4:0] head_x;
    wire [3:0] head_y;
    integer errors;

    snake_head dut (
        .clk(clk), .rst(rst), .tick(tick), .dir(dir),
        .head_x(head_x), .head_y(head_y)
    );

    always #20 clk = ~clk;

    // Send exactly one tick pulse, then wait for the result to settle
    task pulse;
        begin
            @(negedge clk); tick = 1;
            @(negedge clk); tick = 0;
            @(negedge clk);
        end
    endtask

    // Compare the head position with what we expect
    task check(input [4:0] exp_x, input [3:0] exp_y, input integer id);
        begin
            if (head_x !== exp_x || head_y !== exp_y) begin
                errors = errors + 1;
                $display("FAIL case %0d: got (%0d,%0d), expected (%0d,%0d)",
                         id, head_x, head_y, exp_x, exp_y);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        @(negedge clk);

        check(10, 7, 1);                          // starts at (10,7)

        dir = 2'd1; pulse; pulse; pulse;          // right x3
        check(13, 7, 2);

        dir = 2'd2; pulse; pulse;                 // down x2
        check(13, 9, 3);

        dir = 2'd3; pulse;                        // left x1
        check(12, 9, 4);

        dir = 2'd0; pulse; pulse;                 // up x2
        check(12, 7, 5);

        repeat (5) @(negedge clk);                // no tick -> no movement
        check(12, 7, 6);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule