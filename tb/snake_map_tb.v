`timescale 1ns/1ps

module snake_map_tb;
    reg clk = 0;
    reg rst = 1;
    reg set_en = 0, clear_en = 0;
    reg [4:0] set_x = 0, clear_x = 0, rd_x = 0;
    reg [3:0] set_y = 0, clear_y = 0, rd_y = 0;
    wire rd_occupied;
    integer errors;

    snake_map dut (
        .clk(clk), .rst(rst),
        .set_en(set_en), .set_x(set_x), .set_y(set_y),
        .clear_en(clear_en), .clear_x(clear_x), .clear_y(clear_y),
        .rd_x(rd_x), .rd_y(rd_y), .rd_occupied(rd_occupied)
    );

    always #20 clk = ~clk;

    // Mark one cell occupied (one clock-edge write)
    task write_set(input [4:0] sx, input [3:0] sy);
        begin
            @(negedge clk); set_x = sx; set_y = sy; set_en = 1;
            @(negedge clk); set_en = 0;
        end
    endtask

    // Mark one cell free
    task write_clear(input [4:0] cx, input [3:0] cy);
        begin
            @(negedge clk); clear_x = cx; clear_y = cy; clear_en = 1;
            @(negedge clk); clear_en = 0;
        end
    endtask

    // Read a cell and compare with what we expect
    task check(input [4:0] cx, input [3:0] cy, input expected, input integer id);
        begin
            rd_x = cx; rd_y = cy; #1;
            if (rd_occupied !== expected) begin
                errors = errors + 1;
                $display("FAIL case %0d: cell (%0d,%0d) read %b, expected %b",
                         id, cx, cy, rd_occupied, expected);
            end
        end
    endtask

    initial begin
        errors = 0;
        repeat (4) @(negedge clk);
        rst = 0;
        @(negedge clk);

        check(0, 0, 0, 1);                       // everything empty after reset

        write_set(0, 0);   check(0, 0, 1, 2);    // first cell
        write_set(19, 14); check(19, 14, 1, 3);  // last cell
        check(1, 0, 0, 4);                       // neighbour to the right untouched
        check(0, 1, 0, 5);                       // cell below untouched

        write_set(19, 0);  check(19, 0, 1, 6);   // end of row 0...
        check(0, 1, 0, 7);                       // ...must not leak into start of row 1

        write_set(10, 7);  check(10, 7, 1, 8);
        write_clear(10, 7); check(10, 7, 0, 9);  // clearing works
        check(0, 0, 1, 10);                      // other cells keep their value

        // reset wipes the whole map
        @(negedge clk); rst = 1;
        @(negedge clk); rst = 0;
        check(0, 0, 0, 11);
        check(19, 14, 0, 12);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule