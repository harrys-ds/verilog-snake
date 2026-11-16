`timescale 1ns/1ps

module vga_sync_tb;
    reg clk = 0;
    reg rst = 1;
    wire hsync, vsync, active;
    wire [9:0] x, y;

    vga_sync dut (
        .clk(clk), .rst(rst),
        .hsync(hsync), .vsync(vsync),
        .active(active), .x(x), .y(y)
    );

    // 25 MHz clock = 40 ns period, so toggle every 20 ns
    always #20 clk = ~clk;

    integer hsync_low_count;
    integer vsync_low_count;
    integer active_count;
    integer errors;

    initial begin
        $dumpfile("vga_sync.vcd");
        $dumpvars(0, vga_sync_tb);

        errors = 0;
        hsync_low_count = 0;
        vsync_low_count = 0;
        active_count = 0;

        // hold reset for a few clocks, then release
        repeat (4) @(posedge clk);
        rst = 0;

        // Check 1: hsync is low for 96 clocks out of one 800-clock line
        while (x != 0) @(posedge clk);
        repeat (800) begin
            @(posedge clk);
            if (hsync == 0) hsync_low_count = hsync_low_count + 1;
        end
        $display("hsync low count   = %0d (expected 96)", hsync_low_count);
        if (hsync_low_count != 96) errors = errors + 1;

        // Check 2: over one full frame (800 x 525 clocks),
        // active is high 640*480 times and vsync is low 2 lines (1600 clocks)
        repeat (800 * 525) begin
            @(posedge clk);
            if (active == 1) active_count = active_count + 1;
            if (vsync == 0)  vsync_low_count = vsync_low_count + 1;
        end
        $display("active count      = %0d (expected 307200)", active_count);
        $display("vsync low count   = %0d (expected 1600)", vsync_low_count);
        if (active_count != 307200)  errors = errors + 1;
        if (vsync_low_count != 1600) errors = errors + 1;

        // Report
        if (errors == 0) $display("PASS");
        else             $display("FAIL: %0d check(s) failed", errors);

        $finish;
    end
endmodule