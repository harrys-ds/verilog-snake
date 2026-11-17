module game_tick #(
    parameter DIV = 3125000          // clock cycles between ticks
) (
    input  wire clk,
    input  wire rst,
    output reg  tick
);
    reg [31:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            tick  <= 0;
        end else if (count == DIV - 1) begin
            count <= 0;
            tick  <= 1;
        end else begin
            count <= count + 1;
            tick  <= 0;
        end
    end
endmodule