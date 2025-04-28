module adder_rca_tb;
  parameter w = 9;
  reg [w-1:0] x, y;
  reg carry_in;
  wire [w-1:0] sum;
  wire carry_out;
  
  adder_rca #(w) uut (
    .x(x),
    .y(y),
    .carry_in(carry_in),
    .sum(sum),
    .carry_out(carry_out)
  );
  
    initial begin
    $monitor("x = %d, y = %d, carry_in = %d => sum = %d, carry_out = %d", x, y, carry_in, sum, carry_out);
    
    // Test addition
    x = 9'b000000011; y = 9'b000000010; carry_in = 0; #10;
    x = 9'b000000001; y = 9'b000000001; carry_in = 0; #10;
    x = 9'b000000101; y = 9'b000000011; carry_in = 0; #10;
    x = 9'b111111111; y = 9'b000000001; carry_in = 0; #10;
    x = 9'b101010101; y = 9'b010101010; carry_in = 0; #10;
    
    // Test subtraction
    x = 9'b000000101; y = 9'b000000011; carry_in = 1; #10; // 5 - 3
    x = 9'b111111111; y = 9'b000000001; carry_in = 1; #10; // -1 - 1
    x = 9'b101010101; y = 9'b010101010; carry_in = 1; #10; // Mixed bits subtraction
    x = 9'b000000000; y = 9'b000000001; carry_in = 1; #10; // 0 - 1
    
  end
endmodule
