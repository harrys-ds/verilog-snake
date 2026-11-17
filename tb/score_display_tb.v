`timescale 1ns/1ps

module score_display_tb;
    reg  [8:0] value = 0;
    wire [6:0] hex0, hex1, hex2;
    integer errors;

    score_display dut (.value(value), .hex0(hex0), .hex1(hex1), .hex2(hex2));

    localparam [6:0] BLANK = 7'b1111111;

    task check(input [8:0] v, input [6:0] e0, input [6:0] e1, input [6:0] e2, input integer id);
        begin
            value = v;
            #1;
            if (hex0 !== e0 || hex1 !== e1 || hex2 !== e2) begin
                errors = errors + 1;
                $display("FAIL case %0d (value %0d): got %b %b %b, expected %b %b %b",
                         id, v, hex2, hex1, hex0, e2, e1, e0);
            end
        end
    endtask

    initial begin
        errors = 0;

        //     value  ones      tens      hundreds
        check(0,      ~7'h3F,   BLANK,    BLANK,    1);   //   0
        check(7,      ~7'h07,   BLANK,    BLANK,    2);   //   7
        check(10,     ~7'h3F,   ~7'h06,   BLANK,    3);   //  10
        check(42,     ~7'h5B,   ~7'h66,   BLANK,    4);   //  42
        check(99,     ~7'h6F,   ~7'h6F,   BLANK,    5);   //  99
        check(100,    ~7'h3F,   ~7'h3F,   ~7'h06,   6);   // 100: middle zero shows
        check(305,    ~7'h6D,   ~7'h3F,   ~7'h4F,   7);   // 305
        check(188,    ~7'h7F,   ~7'h7F,   ~7'h06,   8);   // 188

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule