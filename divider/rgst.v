`timescale 1ns / 1ps

module rgst #(
    parameter width = 8
) (
    input wire clk,
    reset,
    input wire load_enable,
    load,
    input wire [width-1:0] data_in,
    input wire left_shift_enable,
    left_shift_value,
    input wire right_shift_enable,
    right_shift_value,
    output wire [width-1:0] data_out
);  // e nevoie de MUX pentru data_in pe registrul A ( iesire adder, inbus )

    wire [1 : 0] selector_mux;  //00-01 for keep/data_in, 10 for right_shift, 11 for left_shift
    assign selector_mux[1] = ~load_enable & (left_shift_enable | right_shift_enable);
    assign selector_mux[0] = load_enable | left_shift_enable;

    genvar i;

    generate
        wire [width - 1 : 0] data_interm;
        for (i = 0; i < width; i = i + 1) begin

            if (0 < i && i < width - 1) begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({data_out[i-1], data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else if (i == 0) begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({left_shift_value, data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep // right_shift_value == data_out[i] pentru arithmetic shift
                    .data_in ({data_out[i-1], right_shift_value, data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end

            dff dff_inst (
                .clk(clk),
                .reset(reset),
                .load_enable(load_enable | right_shift_enable | left_shift_enable),
                .data_in(data_interm[i]),
                .data_out(data_out[i])
            );
        end

    endgenerate

endmodule