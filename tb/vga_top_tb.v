`timescale 1ns/1ps

module vga_top_tb;
    reg [1:0] dir = 2'd1;
    reg clk = 0;
    reg rst = 1;
    wire hsync, vsync;
    wire [3:0] r, g, b;

    vga_top dut (
        .clk(clk), .rst(rst),
        .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b)
    );

    // 25 MHz clock = 40 ns period, so toggle every 20 ns
    always #20 clk = ~clk;

    integer green_count;
    integer errors;

    initial begin
        $dumpfile("vga_top.vcd");
        $dumpvars(0, vga_top_tb);

        errors = 0;
        green_count = 0;

        // hold reset for a few clocks, then release
        repeat (4) @(posedge clk);
        rst = 0;

        // run exactly one frame and count clocks where green is on
        repeat (800 * 525) begin
            @(posedge clk);
            if (g != 0) green_count = green_count + 1;
        end

        $display("green pixel count = %0d (expected 1024)", green_count);
        if (green_count != 1024) errors = errors + 1;

        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);

        $finish;
    end
endmodule