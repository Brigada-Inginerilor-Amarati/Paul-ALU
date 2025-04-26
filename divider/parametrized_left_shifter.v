`timescale 1ns / 1ps

module parametrized_left_shifter #(
    parameter WIDTH = 17
) (
    input wire clk,
    input wire rst_b,
    input wire enable,
    input wire load,
    input wire [2 : 0] shift_pos,
    input wire [WIDTH - 1 : 0] in,
    output wire [WIDTH - 1 : 0] out
);

    wire [WIDTH - 1 : 0] shifted_out;
    wire [WIDTH - 1 : 0] mux_out;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : shifter
            assign shifted_out[i] = (i >= shift_pos) ?  // daca indexul > shift_pos
                out[i-shift_pos] :  // atuncinatribuim pe out cu shift_pos in urma
                1'b0;  // altfel, punem 0

            assign mux_out[i] = load ?  // daca putem incarca
                in[i] :  // incarcam pe in[i]
                (enable ?  // altfel,
                shifted_out[i] :  // dar enable e activ, shiftam
                out[i]);  // altfel, nu incarcam nimic

            dff inst_dff (
                .clk(clk),
                .reset(rst_b),
                .load_enable(1'b1),
                .data_in(mux_out[i]),
                .data_out(out[i])
            );
        end
    endgenerate

endmodule