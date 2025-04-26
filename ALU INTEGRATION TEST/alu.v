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
        .pushAregister(pushAregister),
        .pushQregister(pushQregister),
        .select_sum_or_dif(select_sum_or_dif),
        .selectAandMsum(selectAandMsum),
        .select2Msum(select2Msum),
        .selectQprimcorrection(selectQprimcorrection),
        .selectQandQprimdif(selectQandQprimdif),
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

    rgst reg_A (
        .clk  (clk),
        .reset(reset | initAregisterto0),
        .load (loadAregister_from_INBUS | loadAregisterfromADDER),
        .data (data_in_A),
        .out  (A)
    );

    rgst reg_Q (
        .clk  (clk),
        .reset(reset | initQandQprimregisters),
        .load (loadQregister_from_INBUS | loadQregisterfromADDER),
        .data (data_in_Q),
        .out  (Q)
    );

    rgst reg_Qprim (
        .clk  (clk),
        .reset(reset | initQandQprimregisters),
        .load (loadQprimregisterfromADDER),
        .data (data_in_Qprim),
        .out  (Qprim)
    );

    rgst reg_M (
        .clk  (clk),
        .reset(reset | initQandQprimregisters),
        .load (loadMregister_from_INBUS),
        .data (data_in_M),
        .out  (M)
    );

    //=========================================
    // MUX FOR REGISTER INPUT
    //==========================================



endmodule
