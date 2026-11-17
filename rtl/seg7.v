// 4-bit digit -> seven-segment pattern, active-low {g,f,e,d,c,b,a}
module seg7 (
    input  wire [3:0] digit,
    input  wire       blank,      // 1 = turn every segment off
    output reg  [6:0] seg
);
    always @* begin
        if (blank) seg = 7'b1111111;
        else begin
            case (digit)
                4'd0:    seg = ~7'h3F;
                4'd1:    seg = ~7'h06;
                4'd2:    seg = ~7'h5B;
                4'd3:    seg = ~7'h4F;
                4'd4:    seg = ~7'h66;
                4'd5:    seg = ~7'h6D;
                4'd6:    seg = ~7'h7D;
                4'd7:    seg = ~7'h07;
                4'd8:    seg = ~7'h7F;
                4'd9:    seg = ~7'h6F;
                default: seg = 7'b1111111;   // 10-15 are not decimal digits: blank
            endcase
        end
    end
endmodule