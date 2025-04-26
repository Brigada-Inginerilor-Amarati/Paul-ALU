`timescale 1ns / 1ps

module counter #(
    parameter WIDTH = 2
) (
    input  wire                 clk,
    input  wire                 rst_b,
    input  wire                 enable,
    input  wire [WIDTH - 1 : 0] in,
    output wire [WIDTH - 1 : 0] out
);

    wire [WIDTH - 1 : 0] next_cnt;

    incrementer #(
        .WIDTH(WIDTH)
    ) count_up (
        .clk(clk),
        .rst_b(rst_b),
        .enable(enable),
        .in(in),
        .out(next_cnt)
    );

    assign out = next_cnt;

endmodule
