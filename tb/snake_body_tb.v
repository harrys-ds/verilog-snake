`timescale 1ns/1ps

module snake_body_tb;
    reg clk = 0;
    reg rst = 1;
    reg tick = 0;
    reg grow = 0;
    reg [4:0] head_x = 10;
    reg [3:0] head_y = 7;
    reg [4:0] rd_x = 0;
    reg [3:0] rd_y = 0;

    wire       set_en, clear_en, rd_occupied;
    wire [4:0] set_x, clear_x;
    wire [3:0] set_y, clear_y;
    wire [8:0] length;
    integer errors;

    snake_body body (
        .clk(clk), .rst(rst), .tick(tick), .grow(grow),
        .head_x(head_x), .head_y(head_y),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .length(length)
    );

    snake_map map (
        .clk(clk), .rst(rst),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .rd_x(rd_x), .rd_y(rd_y), .rd_occupied(rd_occupied)
    );

    always #20 clk = ~clk;

    // Move the head to (nx, ny) with one tick pulse; g = 1 means the snake grows
    task move(input [4:0] nx, input [3:0] ny, input g);
        begin
            @(negedge clk); grow = g; head_x = nx; head_y = ny; tick = 1;
            @(negedge clk); tick = 0;
            repeat (3) @(negedge clk);        // let the update finish
        end
    endtask

    task check_cell(input [4:0] cx, input [3:0] cy, input expected, input integer id);
        begin
            rd_x = cx; rd_y = cy; #1;
            if (rd_occupied !== expected) begin
                errors = errors + 1;
                $display("FAIL case %0d: cell (%0d,%0d) is %b, expected %b",
                         id, cx, cy, rd_occupied, expected);
            end
        end
    endtask

    task check_len(input [8:0] expected, input integer id);
        begin
            if (length !== expected) begin
                errors = errors + 1;
                $display("FAIL case %0d: length %0d, expected %0d", id, length, expected);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        repeat (3) @(negedge clk);

        // start: a single segment at (10,7)
        check_cell(10, 7, 1, 1);
        check_len(1, 2);

        // move right, no growth: the snake just crawls
        move(11, 7, 0);
        check_cell(11, 7, 1, 3);
        check_cell(10, 7, 0, 4);              // old tail cell is now free
        check_len(1, 5);

        // move right and grow: tail stays, snake gets longer
        move(12, 7, 1);
        check_cell(12, 7, 1, 6);
        check_cell(11, 7, 1, 7);              // still occupied
        check_len(2, 8);

        // move right, no growth: length stays 2, tail frees up
        move(13, 7, 0);
        check_cell(13, 7, 1, 9);
        check_cell(12, 7, 1, 10);
        check_cell(11, 7, 0, 11);
        check_len(2, 12);

        // turn down
        move(13, 8, 0);
        check_cell(13, 8, 1, 13);
        check_cell(13, 7, 1, 14);
        check_cell(12, 7, 0, 15);
        check_len(2, 16);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule