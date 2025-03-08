module shift_ad #(
  parameter n = 32 // numarul de biti, default 32
)( 
  // am pus 'signed', pentru a stii ca este un numar cu semn, astfel ca la shiftare semnul va fi extins
  input signed [n-1 : 0]a, // operandul a
  output signed [n-1 : 0]res // rezultatul
);

  assign res = a >>> 1;
  
endmodule