`timescale 1ns / 1ps

module srt2_divider (
    input wire clk,
    input wire rst_b,
    input wire signed [7 : 0] inbus1,
    input wire signed [7 : 0] inbus2,
    input wire [13 : 0] c,
    output wire cnt1,
    output wire [2 : 0] cnt2,
    output wire signed [7 : 0] outbus1,
    output wire signed [7 : 0] outbus2,
    output wire m7
);

    //-------------------------------
    // VARIABLES(some)
    //-------------------------------
    wire [8 : 0] A;
    wire [7 : 0] Q, Q_star, M;
    wire counter1;
    wire [2 : 0] counter2;

    //-------------------------------
    // LOAD1 & LOAD2
    //-------------------------------
    rgst #(
        .width(9)
    ) inbus_rgst_A (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[0]),
        .load(1'b1),
        .data_in(9'b0),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(A)
    );

    rgst #(
        .width(8)
    ) inbus_rgst_Q (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[0]),
        .load(1'b1),
        .data_in(inbus1),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q)
    );

    rgst #(
        .width(8)
    ) inbus_rgst_Q_star (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[0]),
        .load(1'b1),
        .data_in(8'b0),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q_star)
    );

    assign counter1 = 0;
    rgst #(
        .width(3)
    ) inbus_rgst_CNT2 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[0]),
        .load(1'b1),
        .data_in(3'b0),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(counter2)
    );

    rgst #(
        .width(8)
    ) inbus_rgst_M (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[1]),
        .load(1'b1),
        .data_in(inbus2),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(M)
    );

    assign m7 = M[7];

    //-------------------------------
    // CHECK_LEADING_ZEROS & SHIFT_LEFT & SLICING_BACK
    //-------------------------------
    wire [ 2 : 0] lz;
    wire [24 : 0] shift_out;

    count_leading_zeros #(
        .WIDTH(8)
    ) cnt_lz (
        .enable(c[1]),
        .in(M[7 : 0]),
        .out(lz)
    );

    parametrized_left_shifter #(
        .WIDTH(25)
    ) left_shifting (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[2]),
        .load(1'b1),
        .shift_pos(lz),
        .in({A, Q, M}),
        .out(shift_out)
    );

    shift_slicer slicer_init (
        .enable(c[2]),
        .full_slice(shift_out),
        .a_slice(A),
        .b_slice(Q),
        .c_slice(M)
    );

    counter #(
        .WIDTH(1)
    ) increment_CNT1 (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[2]),
        .in(cnt1),
        .out(counter1)
    );

    //-------------------------------
    // CHECKING CTRL BITS & COMPUTING RESULT
    //-------------------------------
    wire [2 : 0] ctrl_bits;
    assign ctrl_bits = A[8 : 6];

    wire [8 : 0] A_computed;
    wire [7 : 0] Q_computed;
    wire [7 : 0] Q_star_computed;

    // computed shifted q
    compute_shifted_Q compute (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[5 : 3]),
        .A(A),
        .Q(Q),
        .Q_star(Q_star),
        .A_out(A_computed),
        .Q_out(Q_computed),
        .Q_star_out(Q_star_computed)
    );

    wire [8 : 0] M_extended;
    assign M_extended[7 : 0] = M[7 : 0];
    assign M_extended[8] = 1'b0;

    adder_rca #(
        .WIDTH(9)
    ) increment (
        .x(A_computed),
        .y(M_extended),
        .carry_in(c[5]),  // 0 - add, 1 - substract
        .sum(A),
        .carry_out()
    );

    //-------------------------------
    // CHECK CNT2
    //-------------------------------
    wire [2 : 0] counter2_out;
    wire [2 : 0] check_cnt2;

    counter_check check_CNT2 (
        .cnt (counter2),
        .cnt2(check_cnt2)
    );

    counter #(
        .WIDTH(3)
    ) count_up (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[8]),  // idk daca ar trebui mai degraba !cnt2 & c[8]
        .in(counter2),
        .out(counter2_out)
    );


    //-------------------------------
    // CORRECTION_STEP
    //-------------------------------
    wire [8 : 0] A_corrected;
    wire [7 : 0] Q_star_corrected;

    adder_rca #(
        .WIDTH(9)
    ) correct_A (
        .x(A),
        .y(M_extended),
        .carry_in(~(c[6] & c[9])),  // ca sa fie +
        .sum(A_corrected),
        .carry_out()
    );

    adder_rca #(
        .WIDTH(8)
    ) correct_Q_star (
        .x(Q_star_computed),
        .y(8'b00000001),
        .carry_in(~(c[6] & c[9])),  // ca sa fie +
        .sum(Q_star_corrected),
        .carry_out()
    );

    rgst #(
        .width(8)
    ) update_Q_star (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[6] & c[9]),
        .load(1'b1),
        .data_in(Q_star_corrected),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q_star_computed)
    );

    //-------------------------------
    // COMPUTE_RESULT & OUTPUT
    //-------------------------------
    wire [8 : 0] A_out;
    wire [7 : 0] Q_out;
    wire [7 : 0] Q_star_out;

    wire counter1_out;

    adder_rca #(
        .WIDTH(8)
    ) compute_Q_Q_star (
        .x(Q_computed),
        .y(Q_star_computed),
        .carry_in(c[6] & c[7] & c[10]),  // ca sa fie -
        .sum(Q_out),
        .carry_out()
    );

    parametrized_right_shifter #(
        .WIDTH(9)
    ) right_shifting (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[11]),
        .load(1'b1),
        .shift_pos(lz),
        .in(A_computed),
        .out(A_out)
    );

    decrementer #(
        .WIDTH(1)
    ) decrementing_cnt1 (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[11]),
        .in(counter1),
        .out(counter1_out)
    );

    rgst #(
        .width(1)
    ) output_CNT1 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[11]),
        .load(1'b1),
        .data_in(counter1_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(cnt1)
    );

    rgst #(
        .width(3)
    ) output_CNT2 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[11]),
        .load(1'b1),
        .data_in(counter2_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(cnt2)
    );

    rgst #(
        .width(8)
    ) output_Q (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[12]),
        .load(1'b1),
        .data_in(Q_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(outbus1)
    );

    rgst #(
        .width(8)
    ) output_A (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[13]),
        .load(1'b1),
        .data_in(A_out[7 : 0]),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(outbus2)
    );

endmodule

    //-------------------------------
    // TESTBENCH
    //-------------------------------
    
module tb_srt2_divider;

    reg clk;
    reg rst_b;
    reg signed [7:0] inbus1;
    reg signed [7:0] inbus2;
    reg [13:0] c;
    wire cnt1;
    wire [2:0] cnt2;
    wire signed [7:0] outbus1;
    wire signed [7:0] outbus2;
    wire m7;

    // Instantiere DUT
    srt2_divider uut (
        .clk(clk),
        .rst_b(rst_b),
        .inbus1(inbus1),
        .inbus2(inbus2),
        .c(c),
        .cnt1(cnt1),
        .cnt2(cnt2),
        .outbus1(outbus1),
        .outbus2(outbus2),
        .m7(m7)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 10ns clock period
    end

    // Test sequence
    initial begin
        // Resetare initiala
        rst_b  = 0;
        inbus1 = 8'd0;  // Q initial = 0
        inbus2 = 8'd0;  // M initial = 0
        c      = 14'b0;  // Control bits ini?ializate

        #20;
        rst_b  = 1;  // Scoatem reset

        // Seteaz? Q ?i M
        inbus1 = 8'd23;  // Q = 23
        inbus2 = 8'd11;  // M = 11

        #10;
        c[0] = 1'b1;  // Activeaz? load pentru Q ?i M
        #10;
        c[1] = 1'b1;  // Activeaz? load pentru M
        #10;
        c = 14'b0;  // Dezactiveaz? load-ul

        #20;

        // Scoatem valorile din registrele Q ?i M
        c[12] = 1'b1;  // Activeaz? output pentru Q (outbus1)
        c[13] = 1'b1;  // Activeaz? output pentru Rest (outbus2)
        #20;
        c = 14'b0;  // Dezactiveaz? output-ul

        // Afisam rezultatele
        $display("Rezultate:");
        $display("outbus1 (Q final) = %d", outbus1);
        $display("outbus2 (Rest final) = %d", outbus2);

        $finish;
    end

endmodule
