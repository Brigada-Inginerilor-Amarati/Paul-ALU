module shift_as #(
  parameter n = 32 // numarul de biti, default 32
)(
  input [n-1 : 0]a, // operandul a
  output [n-1 : 0]res // rezultatul
);

  assign res = a <<< 1;
  
endmodule