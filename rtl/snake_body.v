module snake_body (
    input  wire       clk,
    input  wire       rst,
    input  wire       tick,         // one-clock pulse: the snake moves
    input  wire       grow,         // 1 = snake ate, so keep the tail on this move
    input  wire [4:0] head_x,       // head position (already updated by snake_head)
    input  wire [3:0] head_y,

    // commands to snake_map
    output wire       set_en,
    output wire [4:0] set_x,
    output wire [3:0] set_y,
    output wire       clear_en,
    output wire [4:0] clear_x,
    output wire [3:0] clear_y,

    output wire [8:0] length        // number of segments
);
    reg [8:0] queue [0:511];        // segment positions, packed as {y, x}
    reg [8:0] head_ptr, tail_ptr;
    reg       init_done;
    reg       tick_d;               // tick, delayed one clock
    reg       grow_q;               // grow, latched when the tick arrives

    wire init = !init_done;
    wire move = tick_d;

    // The head register updates on the same edge that sees the tick, so we
    // act one clock later (tick_d) when head_x/head_y already hold the new cell.
    wire [8:0] tail_pos = queue[tail_ptr];

    assign set_en   = !rst && (init || move);
    assign set_x    = head_x;
    assign set_y    = head_y;
    assign clear_en = !rst && move && !grow_q;
    assign clear_x  = tail_pos[4:0];
    assign clear_y  = tail_pos[8:5];

    assign length   = head_ptr - tail_ptr;

    always @(posedge clk) begin
        if (rst) begin
            init_done <= 0;
            tick_d    <= 0;
            grow_q    <= 0;
            head_ptr  <= 0;
            tail_ptr  <= 0;
        end else begin
            tick_d <= tick;
            if (tick) grow_q <= grow;

            if (init) begin
                // first cycle after reset: record the starting cell
                queue[head_ptr] <= {head_y, head_x};
                head_ptr  <= head_ptr + 1;
                init_done <= 1;
            end else if (move) begin
                queue[head_ptr] <= {head_y, head_x};
                head_ptr <= head_ptr + 1;
                if (!grow_q) tail_ptr <= tail_ptr + 1;   // drop the tail unless growing
            end
        end
    end
endmodule