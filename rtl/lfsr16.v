module lfsr16 (
    input  wire        clk,
    input  wire        rst,
    output reg  [15:0] q
);
    // taps for the polynomial x^16 + x^14 + x^13 + x^11 + 1
    wire feedback = q[0] ^ q[2] ^ q[3] ^ q[5];

    always @(posedge clk) begin
        if (rst) q <= 16'hACE1;              // any non-zero seed works
        else     q <= {feedback, q[15:1]};   // shift right, feedback enters at the top
    end
endmodule