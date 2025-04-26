`timescale 1ns / 1ps

module count_leading_zeros #(
    parameter WIDTH = 8
) (
    input enable,
    input [WIDTH - 1 : 0] in,
    output [2 : 0] out
);

    wire [7:0] z;
    wire [2:0] count;

    assign z[7] = ~in[7];
    assign z[6] = ~in[7] & ~in[6];
    assign z[5] = ~in[7] & ~in[6] & ~in[5];
    assign z[4] = ~in[7] & ~in[6] & ~in[5] & ~in[4];
    assign z[3] = ~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3];
    assign z[2] = ~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2];
    assign z[1] = ~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1];
    assign z[0] = ~in[7] & ~in[6] & ~in[5] & ~in[4] & ~in[3] & ~in[2] & ~in[1] & ~in[0];

    assign count = z[0] ? 4'd8 :
                   z[1] ? 4'd7 :
                   z[2] ? 4'd6 :
                   z[3] ? 4'd5 :
                   z[4] ? 4'd4 :
                   z[5] ? 4'd3 :
                   z[6] ? 4'd2 :
                   z[7] ? 4'd1 :
                          4'd0;

    assign out = enable ? count : 3'd0;

endmodule