module alu (
    input wire clk,
    reset,
    BEGIN,
    input wire [1:0] op_code,
    input wire [7:0] inbus,
    output wire [7:0] outbus,
    output wire END
);

    wire [2:0] bits_of_Q;
    wire [2:0] bits_of_A;
    wire sgn_bit_of_M;
    wire countSRT2full;
    wire countRadix4full;
    wire countLeading0sempty;
    wire loadAregister_from_INBUS;
    wire loadQregister_from_INBUS;
    wire loadMregister_from_INBUS;
    wire initAregisterto0;
    wire initQandQprimregisters;
    wire initCounters;
    wire increment_Leading0s, decrement_Leading0s;
    wire loadAregisterfromADDER;
    wire loadQprimregisterfromADDER;
    wire loadQregisterfromADDER;
    wire increment_Radix4Counter;
    wire increment_SRT2Counter;
    wire pushAregister;
    wire pushQregister;
    wire select_sum_or_dif;
    wire selectAandMsum;
    wire select2Msum;
    wire selectQprimcorrection;
    wire selectQandQprimdif;
    wire RSHIFT_signal;
    wire LSHIFT_signal;
    wire write_to_Qs_enable;
    wire Q_value;
    wire Qprim_value;

    //=========================================
    // COUNTERS
    //==========================================

    wire [2:0] op_counter_bits;
    wire [2:0] leading_zeros_counter_bits;

    control_unit_one_hot cu (
        .clk(clk),
        .reset(reset),
        .BEGIN(BEGIN),
        .op_code(op_code),
        .bits_of_Q(bits_of_Q),
        .bits_of_A(bits_of_A),
        .sgn_bit_of_M(sgn_bit_of_M),
        .countSRT2full(countSRT2full),
        .countRadix4full(countRadix4full),
        .countLeading0sempty(countLeading0sempty),
        .loadAregister_from_INBUS(loadAregister_from_INBUS),
        .loadQregister_from_INBUS(loadQregister_from_INBUS),
        .loadMregister_from_INBUS(loadMregister_from_INBUS),
        .initAregisterto0(initAregisterto0),
        .initQandQprimregisters(initQandQprimregisters),
        .initCounters(initCounters),
        .increment_Leading0s(increment_Leading0s),
        .loadAregisterfromADDER(loadAregisterfromADDER),
        .loadQprimregisterfromADDER(loadQprimregisterfromADDER),
        .loadQregisterfromADDER(loadQregisterfromADDER),
        .increment_Radix4Counter(increment_Radix4Counter),
        .increment_SRT2Counter(increment_SRT2Counter),
        .RSHIFT_signal(RSHIFT_signal),
        .LSHIFT_signal(LSHIFT_signal),
        .pushAregister(pushAregister),
        .pushQregister(pushQregister),
        .select_sum_or_dif(select_sum_or_dif),
        .selectAandMsum(selectAandMsum),
        .select2Msum(select2Msum),
        .selectQprimcorrection(selectQprimcorrection),
        .selectQandQprimdif(selectQandQprimdif),
        .write_to_Qs_enable(write_to_Qs_enable),
        .Q_value(Q_value),
        .Qprim_value(Qprim_value),
        .END(END)
    );

    counter op_counter (
        .clk(clk),
        .reset(reset | initCounters),
        .count_up(increment_Radix4Counter | increment_SRT2Counter),
        .count_down(1'b0),
        .cnt(op_counter_bits)
    );

    counter leading_zeros_counter (
        .clk(clk),
        .reset(reset | initCounters),
        .count_up(increment_Leading0s),
        .count_down(decrement_Leading0s),
        .cnt(leading_zeros_counter_bits)
    );

    //=========================================
    // REGISTERS
    //==========================================

    wire [8:0] A, Q, Qprim, M;
    wire [8:0] data_in_A, data_in_Q, data_in_Qprim, data_in_M;
    wire left_shift_enable, left_shift_value, right_shift_enable, right_shift_value;

    rgst reg_A (
        .clk(clk),
        .reset(reset | initAregisterto0),
        .load_enable(loadAregister_from_INBUS | loadAregisterfromADDER),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(left_shift_value),
        .right_shift_enable(RSHIFT_signal),
        .right_shift_value(right_shift_value),
        .data_in(data_in_A),
        .data_out(A)
    );

    rgst reg_Q (
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(loadQregister_from_INBUS | loadQregisterfromADDER | write_to_Qs_enable),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(Q_value),
        .right_shift_enable(RSHIFT_signal),
        .right_shift_value(right_shift_value),
        .data_in(data_in_Q),
        .data_out(Q)
    );

    rgst reg_Qprim (
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(loadQprimregisterfromADDER | write_to_Qs_enable),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(Qprim_value),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_in(data_in_Qprim),
        .data_out(Qprim)
    );

    rgst reg_M (
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(loadMregister_from_INBUS),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(left_shift_value),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_in(data_in_M),
        .data_out(M)
    );

    /*
    rgst reg_inbus(
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(load_inbus_register_from_INBUS),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(left_shift_value),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .data_in(inbus),
        .data_out()
    );
    */

    //=========================================
    // MUX FOR REGISTER INPUT
    //==========================================


    //=========================================
    // RCA ADDER
    //==========================================

    wire [8:0] operand_A, operand_B, adder_SUM;
    wire adder_carry_in, adder_carry_out;

    assign adder_carry_in = select_sum_or_dif;

    adder_rca #(9) adder (
        .x(operand_A),
        .y(operand_B),
        .carry_in(adder_carry_in),
        .carry_out(adder_carry_out),
        .sum(adder_SUM)
    );

endmodule
