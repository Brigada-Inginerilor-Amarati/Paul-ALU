module fac(
  input wire x,
  input wire y,
  input wire carry_in,
  output wire carry_out,
  output wire sum
);

  assign sum = x ^ y ^ carry_in;
  assign carry_out = (x & y) | (x & carry_in) | (y & carry_in);
  
endmodule

module adder_rca #(
  parameter w = 9
)(
  input wire [w - 1 : 0] x,
  input wire [w - 1 : 0] y,
  input wire carry_in, // 0 addition, 1 substraction
  output wire [w - 1 : 0] sum,
  output wire carry_out
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
  
  assign carry_out = carry[w];

endmodule