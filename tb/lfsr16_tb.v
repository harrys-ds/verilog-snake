`timescale 1ns/1ps

module lfsr16_tb;
    reg clk = 0;
    reg rst = 1;
    wire [15:0] q;
    integer steps;
    integer errors;

    lfsr16 dut (.clk(clk), .rst(rst), .q(q));

    always #20 clk = ~clk;

    initial begin
        errors = 0;
        steps = 0;

        repeat (4) @(negedge clk);
        if (q !== 16'hACE1) begin
            errors = errors + 1;
            $display("FAIL: seed after reset is %h, expected ACE1", q);
        end
        rst = 0;

        // shift until the seed comes back, and make sure zero is never reached
        begin : count
            repeat (70000) begin
                @(negedge clk);
                steps = steps + 1;
                if (q === 16'h0000) errors = errors + 1;
                if (q === 16'hACE1) disable count;
            end
        end

        $display("steps until the seed returned = %0d (expected 65535)", steps);
        if (steps != 65535) errors = errors + 1;

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule