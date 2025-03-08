module and_module #(
  parameter n = 32 // numarul de biti, default 32
)(
  input [n-1 : 0]a, // operandul a
  input [n-1 : 0]b, // operandul b
  output [n-1 : 0]res // rezultatul
);

  assign res = a & b;
  
endmodule