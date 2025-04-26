`timescale 1ns / 1ps

module fac(
  input x,
  input y,
  input carry_in,
  output carry_out,
  output sum
);

  assign sum = x ^ y ^ carry_in;
  assign carry_out = (x & y) | (x & carry_in) | (y & carry_in);
  
endmodule

module adder_rca #(
  parameter WIDTH = 9
)(
  input [WIDTH - 1 : 0] x,
  input [WIDTH - 1 : 0] y,
  input carry_in, // 0 addition, 1 substraction
  output [WIDTH - 1 : 0] sum,
  output reg carry_out
);

  wire [WIDTH : 0] carry;
  wire [WIDTH - 1 : 0 ] y_xor;
  assign carry[0] = carry_in;
  assign y_xor = y ^ {WIDTH{carry_in}};
  
  genvar i;
  generate 
    for(i = 0; i < WIDTH; i = i + 1) begin: vect
      fac fac_inst(
        .x(x[i]),
        .y(y_xor[i]),
        .carry_in(carry[i]),
        .sum(sum[i]),
        .carry_out(carry[i+1])
      );
    end
  endgenerate
  
  always @(*) begin
    carry_out = carry[WIDTH];
  end

endmodule