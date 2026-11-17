module snake_map (
    input  wire       clk,
    input  wire       rst,

    // write ports: mark a cell as occupied / free
    input  wire       set_en,
    input  wire [4:0] set_x,
    input  wire [3:0] set_y,
    input  wire       clear_en,
    input  wire [4:0] clear_x,
    input  wire [3:0] clear_y,

    // read port: is the cell at (rd_x, rd_y) occupied?
    input  wire [4:0] rd_x,
    input  wire [3:0] rd_y,
    output wire       rd_occupied
);
    reg [299:0] cells;               // one bit per cell

    wire [8:0] set_idx   = set_y   * 20 + set_x;
    wire [8:0] clear_idx = clear_y * 20 + clear_x;
    wire [8:0] rd_idx    = rd_y    * 20 + rd_x;

    always @(posedge clk) begin
        if (rst) begin
            cells <= 300'b0;
        end else begin
            if (clear_en) cells[clear_idx] <= 1'b0;
            if (set_en)   cells[set_idx]   <= 1'b1;   // set wins if both hit the same cell
        end
    end

    // Reading is combinational, and anything outside the board reads as empty
    assign rd_occupied = (rd_idx < 300) ? cells[rd_idx] : 1'b0;
endmodule