module vga_sync(
    input wire clk,        // ~25 MHz clock
    input wire rst,
    output wire hsync,
    output wire vsync,
    output wire active, // high inside the 640x480 visible area
    output wire [9:0] x, // pixel x coordinate
    output wire [9:0] y  // pixel y coordinate
);
    reg [9:0] hc, vc;

    always @(posedge clk) begin
        if (rst) begin
            hc <= 0;
            vc <= 0;
        end else if (hc == 799) begin
            hc <= 0;
            vc <= (vc == 524) ? 0 : vc + 1;
        end else begin
            hc <= hc + 1;
        end
    end

    assign hsync = ~(hc >= 656 && hc < 752);
    assign vsync = ~(vc >= 490 && vc < 492);
    assign active = (hc < 640) && (vc < 480);
    assign x = hc;
    assign y = vc;
endmodule