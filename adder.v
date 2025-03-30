module adder #(
    parameter width = 8
) (
    input [width - 1 : 0] x,
    input [width - 1 : 0] y,
    input carry_in,  // 0 for addition, 1 for subtraction

    output reg [width - 1 : 0] sum
);

    wire [width - 1 : 0] carry_out;
    wire [width - 1 : 0] carry_in_next;

endmodule
