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
  parameter w = 9
)(
  input [w - 1 : 0] x,
  input [w - 1 : 0] y,
  input carry_in, // 0 addition, 1 substraction
  output [w - 1 : 0] sum,
  output reg carry_out
);

  wire [w : 0] carry;
  wire [w - 1 : 0 ] y_xor;
  assign carry[0] = carry_in;
  assign y_xor = y ^ {w{carry_in}};
  
  genvar i;
  generate 
    for(i = 0; i < w; i = i + 1) begin: vect
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
    carry_out = carry[w];
  end

endmodule