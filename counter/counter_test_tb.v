`timescale 1ns/1ns

module counter_tb;
  //----------------------------------------------------------------------  
  // Parameters & Signals
  //----------------------------------------------------------------------  
  localparam WIDTH = 4;
  reg                 clk;
  reg                 reset;
  reg                 count_up;
  reg                 count_down;
  wire [WIDTH-1:0]    cnt;

  //----------------------------------------------------------------------  
  // Instantiate DUT
  //----------------------------------------------------------------------  
  counter_struct #(
    .WIDTH(WIDTH)
  ) uut (
    .clk        (clk),
    .reset      (reset),
    .count_up   (count_up),
    .count_down (count_down),
    .cnt        (cnt)
  );

  //----------------------------------------------------------------------  
  // Clock generator: 10 ns period (100 MHz)
  //----------------------------------------------------------------------  
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //----------------------------------------------------------------------  
  // Test sequence
  //----------------------------------------------------------------------  
  initial begin
    // Monitor display
    $display(" time | reset | up | down | cnt");
    $monitor("%4dns |   %b    | %b  |   %b   | %0d",
              $time, reset, count_up, count_down, cnt);

    // Initial reset
    reset      = 1;
    count_up   = 0;
    count_down = 0;
    #12;

    // Release reset, start counting up
    reset      = 0;
    #10;
    count_up   = 1;
    #50;
    count_up   = 0;

    // Now count down
    #10;
    count_down = 1;
    #50;
    count_down = 0;

    // Do another up-count burst
    #10;
    count_up   = 1;
    #30;
    count_up   = 0;

    // Finish simulation
    #20;
    // $finish;
    $stop;
  end

endmodule