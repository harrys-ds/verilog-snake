`timescale 1ns/1ps

module pixel_gen_tb;
    reg active;
    reg [9:0] x, y;
    reg [4:0] head_x;
    reg [3:0] head_y;
    reg body_occupied;
    wire [3:0] r, g, b;
    integer errors;

    pixel_gen dut (
        .active(active), .x(x), .y(y),
        .head_x(head_x), .head_y(head_y),
        .body_occupied(body_occupied),
        .r(r), .g(g), .b(b)
    );

    task check(input [3:0] exp_r, input [3:0] exp_g, input [3:0] exp_b, input integer id);
        begin
            #10;
            if (r !== exp_r || g !== exp_g || b !== exp_b) begin
                errors = errors + 1;
                $display("FAIL case %0d: got r=%h g=%h b=%h, expected r=%h g=%h b=%h",
                         id, r, g, b, exp_r, exp_g, exp_b);
            end
        end
    endtask

    initial begin
        errors = 0;
        head_x = 10; head_y = 7; body_occupied = 0;

        // 1: top-left corner is border -> blue
        active = 1; x = 0;   y = 0;   check(4'h0, 4'h0, 4'hF, 1);
        // 2: bottom-right corner is border -> blue
        active = 1; x = 639; y = 479; check(4'h0, 4'h0, 4'hF, 2);
        // 3: inside the head's cell (10,7) -> bright green
        active = 1; x = 320; y = 240; check(4'h0, 4'hF, 4'h0, 3);
        // 4: empty cell -> black
        active = 1; x = 100; y = 100; check(4'h0, 4'h0, 4'h0, 4);
        // 5: border position but active low -> black
        active = 0; x = 0;   y = 0;   check(4'h0, 4'h0, 4'h0, 5);

        // 6: move the head to (3,3); pixel (100,100) is cell (3,3) -> bright green
        active = 1; head_x = 3; head_y = 3; x = 100; y = 100;
        check(4'h0, 4'hF, 4'h0, 6);
        // 7: the old head position is empty now -> black
        x = 320; y = 240; check(4'h0, 4'h0, 4'h0, 7);

        // 8: body cell (occupied, not the head) -> dim green
        body_occupied = 1; x = 320; y = 240; check(4'h0, 4'h8, 4'h0, 8);
        // 9: head cell that is also occupied -> head wins, bright green
        x = 100; y = 100; check(4'h0, 4'hF, 4'h0, 9);
        // 10: occupied but active low -> black
        active = 0; x = 320; y = 240; check(4'h0, 4'h0, 4'h0, 10);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule