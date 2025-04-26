`timescale 1ns / 1ps

module incrementer #(
    parameter WIDTH = 2
) (
    input  wire                 clk,
    input  wire                 rst_b,
    input  wire                 enable,
    input  wire [    WIDTH-1:0] in,
    output wire [WIDTH - 1 : 0] out
);

    wire [WIDTH - 1 : 0] sum;
    wire [WIDTH - 1 : 0] mux_out;
    wire [WIDTH - 1 : 0] out_reg;

    adder_rca #(
        .WIDTH(WIDTH)
    ) increment (
        .x(in),
        .y({{(WIDTH - 2) {1'b0}}, 1'b1}),
        .carry_in(1'b0),
        .sum(sum),
        .carry_out()
    );

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign mux_out[i] = enable ? sum[i] : in[i];
        end
    endgenerate

    rgst #(
        .width(WIDTH)
    ) reg_out (
        .clk(clk),
        .reset(rst_b),
        .load_enable(enable),
        .load(1'b1),
        .data_in(mux_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(out_reg)
    );

    assign out = out_reg;

endmodule