`include "defines.v"

module alu_tb #(
  parameter n = 32,
  parameter m = 4
)(
  output reg [n-1 : 0] a, 
  output reg [n-1 : 0] b, 
  output reg [m-1 : 0] sel, 
  output reg cin, 
  output wire [n-1 : 0] res, 
  output wire cout, 
  output wire flag_neg, 
  output wire flag_overflow, 
  output wire flag_null 
);

  alu #(
    .n(n), 
    .m(m)   
  ) alu_inst (
    .a(a),
    .b(b),
    .sel(sel),
    .cin(cin),
    .res(res),
    .cout(cout),
    .flag_neg(flag_neg),
    .flag_overflow(flag_overflow),
    .flag_null(flag_null)
  );

  initial begin
    // test adunare
    a = 32'b00000000000000000000000000000001; 
    b = 32'b00000000000000000000000000000001;
    sel = `RCA; 
    cin = 0;
    #10;

    // test scadere 
    a = 32'b00000000000000000000000000000010; 
    b = 32'b00000000000000000000000000000001; 
    sel = `RCS; 
    cin = 0;
    #10;

    // test and
    a = 32'b00000000000000000000000000000101; 
    b = 32'b00000000000000000000000000000111; 
    sel = `AND; 
    #10;

    // test or
    a = 32'b00000000000000000000000000000101; 
    b = 32'b00000000000000000000000000000011; 
    sel = `OR;
    #10;

    // test xor
    a = 32'b00000000000000000000000000000101; 
    b = 32'b00000000000000000000000000000011; 
    sel = `XOR; 
    #10;

    // test shift logic la stanga
    a = 32'b10000000000000000000000000000010; 
    b = 32'b00000000000000000000000000000000; 
    sel = `SHIFT_LS; 
    #10;

    // test shift logic la dreapta
    a = 32'b10000000000000000000000000000010; 
    b = 32'b00000000000000000000000000000000; 
    sel = `SHIFT_LD; 
    #10;
    
    // test shift aritmetic la stanga
    a = 32'b10000000000000000000000000000010; 
    b = 32'b00000000000000000000000000000000; 
    sel = `SHIFT_AS; 
    #10;

    // test shift aritmetic la dreapta
    a = 32'b10000000000000000000000000000010; 
    b = 32'b00000000000000000000000000000000; 
    sel = `SHIFT_AD; 
    #10;

    $finish;
  end
// control unit
  initial begin
    $monitor("Time=%0t | a=%b, b=%b, sel=%b, cin=%b | res=%b, cout=%b, flag_neg=%b, flag_overflow=%b, flag_null=%b", 
             $time, a, b, sel, cin, res, cout, flag_neg, flag_overflow, flag_null);
  end

endmodule