// counter.v
module counter_struct #(
    parameter WIDTH = 3
) (
    input  wire             clk,
    input  wire             reset,
    input  wire             count_up,
    input  wire             count_down,
    output wire  [WIDTH-1:0] cnt
);

    
    // Set a constant of one
    wire [WIDTH-1:0] one = {{WIDTH-1{1'b0}}, 1'b1};
    wire [WIDTH-1:0] inc;
    // count_up -> carry in 0
    // count_down -> carry in 1
    wire count_mode = ~count_up & count_down;

    adder_rca #(WIDTH) inc_adder (
        .x        (cnt),
        .y        (one),
        .carry_in (count_mode),
        .sum      (inc),
        .carry_out()
    );

    // register stage using D flip-flops
    wire load_enable = count_up | count_down;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : dffs
            dff dff_inst (
                .clk        (clk),
                .reset      (reset),
                .load_enable(load_enable),
                .data_in    (inc[i]),
                .data_out   (cnt[i])
            );
        end
    endgenerate

endmodule