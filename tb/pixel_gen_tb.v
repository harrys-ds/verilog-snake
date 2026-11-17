`timescale 1ns/1ps

module pixel_gen_tb;
    reg active;
    reg [9:0] x, y;
    wire [3:0] r, g, b;
    integer errors;

    pixel_gen dut (
        .active(active), .x(x), .y(y),
        .r(r), .g(g), .b(b)
    );

    // Compare the outputs to the expected colors and count a failure if they differ
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

        // Case 1: top-left corner is in the border -> blue
        active = 1; x = 0;   y = 0;   check(4'h0, 4'h0, 4'hF, 1);
        // Case 2: bottom-right corner is in the border -> blue
        active = 1; x = 639; y = 479; check(4'h0, 4'h0, 4'hF, 2);
        // Case 3: inside the test cell (column 10, row 7) -> green
        active = 1; x = 320; y = 240; check(4'h0, 4'hF, 4'h0, 3);
        // Case 4: empty cell in the middle of the board -> black
        active = 1; x = 100; y = 100; check(4'h0, 4'h0, 4'h0, 4);
        // Case 5: border position but active is low -> must be black
        active = 0; x = 0;   y = 0;   check(4'h0, 4'h0, 4'h0, 5);

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);

        $finish;
    end
endmodule