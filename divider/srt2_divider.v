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
    output wire m7,
    output wire [2 : 0] ctrl_bits
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
    rgst #(
        .width(3)
    ) assign_ctrl_bits (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[2]),
        .load(1'b1),
        .data_in(A[8 : 6]),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(ctrl_bits)
    );

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
    
    rgst #(
        .width(9)
    ) putA_back1 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[3]),
        .load(1'b1),
        .data_in(A_computed),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(A)
    );
    
    rgst #(
        .width(8)
    ) putQ_back1 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[3]),
        .load(1'b1),
        .data_in(Q_computed),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q)
    );
    
    rgst #(
        .width(8)
    ) putQ_star_back1 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[3]),
        .load(1'b1),
        .data_in(Q_star_computed),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q_star)
    );

    wire [8 : 0] M_extended;
    assign M_extended[7 : 0] = M[7 : 0];
    assign M_extended[8] = 1'b0;

    adder_rca #(
        .WIDTH(9)
    ) increment (
        .x(A),
        .y(M_extended),
        .carry_in(c[5]),  // 0 - add, 1 - substract
        .sum(A_computed),
        .carry_out()
    );
    
    rgst #(
        .width(9)
    ) putA_back2 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[5]),
        .load(1'b1),
        .data_in(A_computed),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(A)
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
    
    rgst #(
        .width(3)
    ) putCNT2_back1 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[8]),
        .load(1'b1),
        .data_in(counter2_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(counter2)
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
    
    rgst #(
        .width(9)
    ) putA_back3 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[6] & c[9]),
        .load(1'b1),
        .data_in(A_corrected),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(A)
    );

    adder_rca #(
        .WIDTH(8)
    ) correct_Q_star (
        .x(Q_star),
        .y(8'b00000001),
        .carry_in(~(c[6] & c[9])),  // ca sa fie +
        .sum(Q_star_corrected),
        .carry_out()
    );

    rgst #(
        .width(8)
    ) putQ_star_back2 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[6] & c[9]),
        .load(1'b1),
        .data_in(Q_star_corrected),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q_star)
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
        .x(Q),
        .y(Q_star),
        .carry_in(c[6] & c[7] & c[10]),  // ca sa fie -
        .sum(Q_out),
        .carry_out()
    );
    
    rgst #(
        .width(8)
    ) putQ_back3 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[6] & c[7] & c[10]),
        .load(1'b1),
        .data_in(Q_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(Q)
    );

    parametrized_right_shifter #(
        .WIDTH(9)
    ) right_shifting (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[11]),
        .load(1'b1),
        .shift_pos(lz),
        .in(A),
        .out(A_out)
    );
    
    rgst #(
        .width(9)
    ) putA_back4 (
        .clk(clk),
        .reset(rst_b),
        .load_enable(c[6] & c[7] & c[10]),
        .load(1'b1),
        .data_in(A_out),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(A)
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
        .data_in(Q),
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
        .data_in(A[7 : 0]),
        .left_shift_enable(1'b0),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_out(outbus2)
    );

endmodule
