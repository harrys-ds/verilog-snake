`timescale 1ns/1ps

module frame_dump_tb;
    reg [1:0] dir = 2'd1;
    reg grow = 0;
    reg clk = 0;
    reg rst = 1;
    wire hsync, vsync;
    wire [3:0] r, g, b;
    integer f;

    vga_top dut (
        .clk(clk), .rst(rst), .dir(dir), .grow(grow),
        .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

    initial begin
        f = $fopen("frame.ppm", "w");
        $fwrite(f, "P3\n640 480\n255\n");   // header: ASCII PPM, size, max value

        repeat (4) @(posedge clk);
        rst = 0;

        // one frame: write a pixel every clock while inside the visible area
        repeat (800 * 525) begin
            @(posedge clk);
            if (dut.active)
                $fwrite(f, "%0d %0d %0d\n", r * 17, g * 17, b * 17);
        end

        $fclose(f);
        $display("frame.ppm written");
        $finish;
    end
endmodule