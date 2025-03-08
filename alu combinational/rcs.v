module fsc(
  input a,
  input b,
  input bin,
  output res,
  output bout
);
           
  assign res = a ^ b ^ bin;
  assign bout = (~a & b) | (~(a ^ b) & bin);
  // assign overflow = (a[n-1] == b[n-1]) && (res[n-1] != a[n-1]);
           
endmodule

module rcs #(
  parameter n = 32 // default 32
)(
  input [n-1 : 0]a,
  input [n-1 : 0]b,
  input bin,
  output [n-1 : 0]res,
  output bout,
  output overflow
);

wire [n : 0]borrow; // vector de borrow
assign borrow[0] = bin;

generate 
  genvar i;
  for(i = 0; i < n; i = i + 1) begin: vect
    fsc fsc_inst( 
      .a(a[i]), 
      .b(b[i]), 
      .bin(borrow[i]),
      .res(res[i]), 
      .bout(borrow[i + 1])
      );
  end
endgenerate

assign bout = borrow[n];
assign overflow = borrow[n] ^ borrow[n - 1]; // sau (a[n-1] == b[n-1]) && (res[n-1] != a[n-1])

endmodule