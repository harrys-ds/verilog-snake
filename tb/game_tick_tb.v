`timescale 1ns/1ps

module game_tick_tb;
    reg clk = 0;
    reg rst = 1;
    wire tick;

    game_tick #(.DIV(10)) dut (.clk(clk), .rst(rst), .tick(tick));

    always #20 clk = ~clk;

    integer ticks;
    integer errors;
    reg prev_tick;

    initial begin
        ticks = 0;
        errors = 0;
        prev_tick = 0;

        repeat (4) @(negedge clk);
        rst = 0;

        // run 100 clocks; with DIV = 10 we expect exactly 10 ticks
        repeat (100) begin
            @(negedge clk);
            if (tick) ticks = ticks + 1;
            // a tick must last only one clock
            if (tick && prev_tick) errors = errors + 1;
            prev_tick = tick;
        end

        $display("tick count = %0d (expected 10)", ticks);
        if (ticks != 10) errors = errors + 1;

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);
        $finish;
    end
endmodule
