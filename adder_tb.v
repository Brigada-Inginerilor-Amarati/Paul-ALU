module adder_tb;
    
    parameter width = 8;
    reg [width-1:0] x;
    reg [width-1:0] y;
    reg carry_in;
    wire [width-1:0] sum;
    
    // Instantierea modulului de testat
    adder #(width) uut (
        .x(x),
        .y(y),
        .carry_in(carry_in),
        .sum(sum)
    );
    
    initial begin
        $monitor("x = %d, y = %d, carry_in = %b, sum = %d", x, y, carry_in, sum);
        
        // Test 1: 5 + 3
        x = 9'b000000101; 
        y = 9'b000000011; 
        carry_in = 0;
        #10;
        
        // Test 2: 5 - 3
        x = 9'b000000101; 
        y = 9'b000000011; 
        carry_in = 1;
        #10;
        
        // Test 3: 127 + 1 (overflow)
        x = 9'b001111111; 
        y = 9'b000000001; 
        carry_in = 0;
        #10;
        
        // Test 4: 127 - 1
        x = 9'b001111111; 
        y = 9'b000000001; 
        carry_in = 1;
        #10;
        
        // Test 5: 0 - 1 (underflow)
        x = 9'b000000000; 
        y = 9'b000000001; 
        carry_in = 1;
        #10;
    end
endmodule
