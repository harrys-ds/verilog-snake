`timescale 1ns/1ps
module pixel_gen_tb;
    reg active;
    reg [9:0] x, y;
    wire [3:0] r, g, b;
    integer errors;

    pixel_gen dut (.active(active), .x(x), .y(y), .r(r), .g(g), .b(b));

    initial begin
        errors = 0;
        // Case 1: inside the square, active -> green should be 15
        active = 1; x = 320; y = 240; #10;
        if (g !== 4'hF) begin errors = errors + 1; $display("FAIL case 1"); end
        // TODO Case 2: just outside, e.g. x = 287 -> green should be 0
        // TODO Case 3: the first pixel x = 288, y = 208 -> inside, green 15
        // TODO Case 4: x = 351, y = 271 (last pixel inside) -> green 15
        // TODO Case 5: inside the square area but active = 0 -> green 0
        if (errors == 0) $display("PASS"); else $display("FAIL: %0d", errors);
        $finish;
    end
endmodule