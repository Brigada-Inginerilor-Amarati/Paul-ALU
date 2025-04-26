`timescale 1ns / 1ps

module single_left_shifter #(
    parameter WIDTH = 17
) (
    input wire clk,
    input wire rst_b,
    input wire enable,
    input wire load,
    input wire [WIDTH - 1 : 0] in,
    output wire [WIDTH - 1 : 0] out
);

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : shifter_logic
            dff inst_dff (
                .clk(clk),
                .reset(rst_b),
                .load_enable(enable),
                .data_in(load ? in[i] : (i == 0 ? 1'b0 : out[i-1])),
                .data_out(out[i])
            );
        end
    endgenerate

endmodule