module score_display (
    input  wire [8:0] value,        // 0..511
    output wire [6:0] hex0,         // ones
    output wire [6:0] hex1,         // tens
    output wire [6:0] hex2          // hundreds
);
    wire [3:0] ones     = value % 10;
    wire [3:0] tens     = (value / 10) % 10;
    wire [3:0] hundreds = value / 100;

    seg7 d0 (.digit(ones),     .blank(1'b0),         .seg(hex0));  // always show the ones
    seg7 d1 (.digit(tens),     .blank(value < 10),   .seg(hex1));  // blank below 10
    seg7 d2 (.digit(hundreds), .blank(value < 100),  .seg(hex2));  // blank below 100
endmodule