`include "defines.v"

module alu #(
  parameter n = 32, // numarul de biti pe care e ALU, default 32
  parameter m = 4 // numarul de biti pe care facem selectia(depinde de cate operatii face alu), default 4
)(
// inputs per se: a si b, pentru ele facem operatiile definite
  input [n-1 : 0]a, 
  input [n-1 : 0]b,
  input [m-1 : 0]sel, // selectam operatia
  input cin, // carry-in
  output reg [n-1 : 0] res, // rezultatul operatiei artitmetice/logice asupra variabilelor de intrare a si b
  output reg cout, // flag, carry-out
  output reg flag_neg, // flag-ul care ne spune daca avem rezultat negativ
  output reg flag_overflow, // -||- e overflow
  output reg flag_null // -||- e nul
);

// variabile intermediare pentru: rezultat, c/b out, overflow, rezultat negativ si rezultat nul
wire [n-1 : 0]add_res, sub_res, and_res, or_res, xor_res, shift_ls_res, shift_ld_res, shift_as_res, shift_ad_res;
wire add_cout, sub_bout;
wire add_neg, sub_neg;
wire add_overflow, sub_overflow;
wire add_null, sub_null;

// instantiem urmatoarele operatii: 

// modulele pentru partea ARITMETICA:
// 1. fac
rca #(
  .n(32)
)rca_inst( 
  .a(a), 
  .b(b), 
  .cin(cin), 
  .res(add_res), 
  .cout(add_cout),
  .overflow(add_overflow)
  );
// 2. fsc
rcs #(
  .n(32)
)rcs_inst( 
  .a(a), 
  .b(b), 
  .bin(cin), 
  .res(sub_res), 
  .bout(sub_bout),
  .overflow(sub_overflow)
);

// modulele pentru partea LOGICA:
// 1. and
and_module #( 
  .n(n)
)and_module_inst( 
  .a(a), 
  .b(b), 
  .res(and_res)
);

// 2. or
or_module #( 
  .n(n)
)or_module_inst( 
  .a(a), 
  .b(b), 
  .res(or_res)
);

// 3. xor
xor_module #( 
  .n(n)
)xor_module_inst( 
  .a(a), 
  .b(b), 
  .res(xor_res)
);

// 4. shiftare logica la stanga
shift_ls #( 
  .n(n)
)shift_ls_inst( 
  .a(a),  
  .res(shift_ls_res)
);

// 5. shiftare logica la dreapta
shift_ld #( 
  .n(n)
)shift_ld_inst( 
  .a(a),  
  .res(shift_ld_res)
);

// 6. shiftare aritmetica la stanga
shift_as #( 
  .n(n)
)shift_as_inst( 
  .a(a),  
  .res(shift_as_res)
);

// 7. shiftare aritmetica la dreapta
shift_ad #( 
  .n(n)
)shift_ad_inst( 
  .a(a),  
  .res(shift_ad_res)
);

always @ (*) begin
  case(sel)
    `RCA: begin
      res = add_res;
      cout = add_cout;
      flag_overflow = add_overflow;
      flag_neg = add_res[n-1]; 
      flag_null = (add_res == 0);
    end
    
    `RCS: begin
      res = sub_res;
      cout = sub_bout;
      flag_overflow = sub_overflow;
      flag_neg = sub_res[n-1]; 
      flag_null = (sub_res == 0);
    end
    
    `AND: begin
      res = and_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = and_res[n-1];
      flag_null = (and_res == 0);
    end
    
   `OR: begin
      res = or_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = or_res[n-1];
      flag_null = (or_res == 0);
    end
    
    `XOR: begin
      res = xor_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = xor_res[n-1];
      flag_null = (xor_res == 0);
    end
    
    `SHIFT_LS: begin
      res = shift_ls_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = shift_ls_res[n-1];
      flag_null = (shift_ls_res == 0);
    end
     
    `SHIFT_LD: begin
      res = shift_ld_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = shift_ld_res[n-1];
      flag_null = (shift_ld_res == 0);
    end
      
      `SHIFT_AS: begin
      res = shift_as_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = shift_as_res[n-1];
      flag_null = (shift_as_res == 0);
    end
     
    `SHIFT_AD: begin
      res = shift_ad_res;
      cout = 0;
      flag_overflow = 0; // nu avem overflow
      flag_neg = shift_ad_res[n-1];
      flag_null = (shift_ad_res == 0);
    end
  endcase
end

endmodule