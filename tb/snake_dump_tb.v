`timescale 1ns/1ps

module snake_dump_tb;
    reg clk = 0;
    reg rst = 1;
    reg [1:0] dir = 2'd1;            // moving right
    reg grow = 1;                    // growing at first
    wire hsync, vsync;
    wire [3:0] r, g, b;
    integer f;

    vga_top #(.TICK_DIV(420000)) dut (
        .clk(clk), .rst(rst), .dir(dir), .grow(grow),
        .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

    task dump_frame(input integer fd);
        begin
            $fwrite(fd, "P3\n640 480\n255\n");
            repeat (800 * 525) begin
                @(posedge clk);
                if (dut.active)
                    $fwrite(fd, "%0d %0d %0d\n", r * 17, g * 17, b * 17);
            end
            $fclose(fd);
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        rst = 0;

        f = $fopen("snake0.ppm", "w");
        dump_frame(f);                          // frame 0: length 1

        repeat (3 * 800 * 525) @(posedge clk);  // frames 1-3
        f = $fopen("snake4.ppm", "w");
        dump_frame(f);                          // frame 4: grown to length 5

        grow = 0;                               // stop growing: now it just crawls
        repeat (3 * 800 * 525) @(posedge clk);  // frames 5-7
        f = $fopen("snake8.ppm", "w");
        dump_frame(f);                          // frame 8: still length 5, moved 4 cells

        $display("frames written");
        $finish;
    end
endmodule