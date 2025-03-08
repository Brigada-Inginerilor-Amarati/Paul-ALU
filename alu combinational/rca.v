module fac(
  input a,
  input b,
  input cin,
  output res,
  output cout
);
           
  assign res = a ^ b ^ cin;
  assign cout = a & b | (cin & (a ^ b));
           
endmodule

module rca #(
  parameter n = 32 // default 32
)(
  input [n-1 : 0]a,
  input [n-1 : 0]b,
  input cin,
  output [n-1 : 0]res,
  output cout,
  output overflow
);

wire [n : 0]carry; // vector de carry
assign carry[0] = cin;

generate 
  genvar i;
  for(i = 0; i < n; i = i + 1) begin: vect
    fac fac_inst( 
      .a(a[i]), 
      .b(b[i]), 
      .cin(carry[i]),
      .res(res[i]), 
      .cout(carry[i + 1])
      );
  end
endgenerate

assign cout = carry[n];
assign overflow = carry[n] ^ carry[n - 1]; // sau (a[n-1] == c[n-1]) && (res[n-1] != a[n-1])

endmodule