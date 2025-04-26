`timescale 1ns / 1ps

module compute_shifted_Q (
  input wire clk,
  input wire rst_b,
  input wire [2 : 0] enable,
  input wire [8 : 0] A,
  input wire [7 : 0] Q,
  input wire [7 : 0] Q_star,
  output wire [8: 0] A_out,
  output wire [7 : 0] Q_out,
  output wire [7 : 0] Q_star_out
);

    wire [24 : 0] shift_out;
    wire [8 : 0] A_shifted;
    wire [7 : 0] Q_shifted;
    wire [7 : 0] Q_star_shifted;
    
    wire Q0;
    wire Q_star0;
    
    // shift cu o pozitie la stanga
    single_left_shifter #(
      .WIDTH(25)
    ) left_shift_A_Q (
        .clk(clk),
        .rst_b(rst_b),
        .enable(enable[0]), // c[3]
        .load(1'b1),
        .in({A, Q, 8'b0}),
        .out(shift_out)
    );
    // acum avem Q[0] = 0
    
    shift_slicer slicer_after_shift (
      .enable(enable[0]),
      .full_slice(shift_out),
      .a_slice(A_shifted),
      .b_slice(Q_shifted),
      .c_slice()
    );
    
    single_left_shifter #(
      .WIDTH(8)
    ) left_shift_Q_star (
        .clk(clk),
        .rst_b(rst_b),
        .enable(enable[0]),
        .load(1'b1),
        .in(Q_star),
        .out(Q_star_shifted)
    );
    // acum avem Q_star[0] = 0
  
    // in functie de enable[0] & enable[1] -> Q[0] = 1, Q_star[0] = 0
    //               enable[0] & enable[2] -> Q[0] = 0, Q_star[0] = 1
     
    assign Q0 = enable[0] & enable[1];
    assign Q_star0 = enable[0] & enable[2];
    
    assign A_out = A_shifted;
    assign Q_out = {Q_shifted[7 : 1], Q0};
    assign Q_star_out = {Q_star_shifted[7 : 1], Q_star0};
    
endmodule