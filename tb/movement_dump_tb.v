`timescale 1ns/1ps

module movement_dump_tb;
    reg clk = 0;
    reg rst = 1;
    reg [1:0] dir = 2'd1;            // moving right
    wire hsync, vsync;
    wire [3:0] r, g, b;
    integer f;

    vga_top #(.TICK_DIV(420000)) dut (
        .clk(clk), .rst(rst), .dir(dir),
        .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b)
    );

    always #20 clk = ~clk;

    // Save one full frame to the already-open file, then close it
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

        f = $fopen("frame0.ppm", "w");
        dump_frame(f);                         // frame 0: head at column 10

        repeat (3 * 800 * 525) @(posedge clk); // skip frames 1, 2, 3

        f = $fopen("frame4.ppm", "w");
        dump_frame(f);                         // frame 4: head should be at column 14

        $display("frames written");
        $finish;
    end
endmodule