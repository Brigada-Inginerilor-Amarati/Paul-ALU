module adder #(
    parameter width = 9
) (
    input [width-1:0] x,
    input [width-1:0] y,
    input carry_in,  // 0 for addition, 1 for subtraction
    output [width-1:0] sum
);

    wire [width-1:0] carry_out;
    wire [width-1:0] carry_in_next;
    wire [width-1:0] y_modified;

    //Xor pentru scadere
    assign y_modified = y ^ {width{carry_in}};

    //adunarea
    assign {carry_out, sum} = x + y_modified + carry_in;

endmodule
