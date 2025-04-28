module alu (
    input wire clk,
    reset,
    BEGIN,
    input wire [1:0] op_code,
    input wire [7:0] inbus,
    output wire [7:0] outbus,
    output wire END,
    output wire [16 : 0] act_state_debug,
    output wire [16 : 0] next_state_debug,
    output wire [8 : 0] A_reg_debug,
    output wire [8 : 0] Q_reg_debug,
    output wire [8 : 0] M_reg_debug
);

    //=========================================
    // CONTROL UNIT + SIGNALS
    //==========================================

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

    wire [2:0] op_counter_bits;
    wire [2:0] leading_zeros_counter_bits;

    control_unit_one_hot cu (
        .clk(clk),
        .reset_input(reset),
        .BEGIN(BEGIN),
        .op_code(op_code),
        .bits_of_Q(bits_of_Q),
        .bits_of_A(bits_of_A),
        .sgn_bit_of_M(sgn_bit_of_M),
        .countSRT2full(countSRT2full),
        .countRadix4full(countRadix4full),
        .countLeading0sempty(countLeading0sempty),
        .decrement_Leading0s(decrement_Leading0s),
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
        .END(END),
        .act_state_debug(act_state_debug),
        .next_state_debug(next_state_debug)
    );

    //=========================================
    // COUNTERS
    //==========================================

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

    //=========================================
    // REGISTERS + MUXs for shifting values
    //==========================================

    wire [8:0] A, Q, Qprim, M;
    wire [8:0] data_in_A, data_in_Q, data_in_Qprim, data_in_M;
    wire left_shift_enable, left_shift_value_Q, right_shift_enable, right_shift_value_A;
    
    // debug purposesr

    assign A_reg_debug = A;
    assign Q_reg_debug = Q;
    assign M_reg_debug = M;
    
    mux_2_to_1 MUX_RSHIFT_A (
      .data_in ( { 1'b0, A[8] } ),
	    .select ( decrement_Leading0s ),
	    .data_out ( right_shift_value_A )
    );

    rgst reg_A (
        .clk(clk),
        .reset(reset | initAregisterto0),
        .load_enable(loadAregister_from_INBUS | loadAregisterfromADDER),
        .left_shift_enable(LSHIFT_signal | increment_Leading0s),
        .left_shift_value(Q[8]),
        .right_shift_enable(RSHIFT_signal | decrement_Leading0s),
        .right_shift_value(right_shift_value_A),
        .jump_LSb ( 1'b0 ),
        .data_in(data_in_A),
        .data_out(A)
    );
    
    mux_2_to_1 MUX_LSHIFT_Q (
      .data_in ( { Q_value , 0 } ),
	    .select ( LSHIFT_signal ),
	    .data_out ( left_shift_value_Q )
    );

    rgst reg_Q (
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(loadQregister_from_INBUS | loadQregisterfromADDER | write_to_Qs_enable),
        .left_shift_enable(LSHIFT_signal | increment_Leading0s),
        .left_shift_value(Q_value),
        .right_shift_enable(RSHIFT_signal),
        .right_shift_value(A[0]),
        .jump_LSb ( op_code[1] & op_code[0] ),
        .data_in(data_in_Q),
        .data_out(Q)
    );
    
    assign data_in_Qprim = { adder_SUM[7 : 0], 1'b0 };

    rgst reg_Qprim (
        .clk(clk),
        .reset(reset | initQandQprimregisters),
        .load_enable(loadQprimregisterfromADDER | write_to_Qs_enable),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(Qprim_value),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .jump_LSb ( op_code[1] & op_code[0] ),
        .data_in(data_in_Qprim),
        .data_out(Qprim)
    );
    
    assign data_in_M = { inbus[7] & ~( op_code[1] & op_code[0] ), inbus };
    assign sgn_bit_of_M = M[7];

    rgst reg_M (
        .clk(clk),
        .reset(reset),
        .load_enable(loadMregister_from_INBUS),
        .left_shift_enable(LSHIFT_signal),
        .left_shift_value(1'b0),
        .right_shift_enable(1'b0),
        .right_shift_value(1'b0),
        .jump_LSb ( 1'b0 ),
        .data_in(data_in_M),
        .data_out(M)
    );

    //=========================================
    // MUXs FOR REGISTER DATA INPUTS
    //==========================================
    
    genvar i;
    
    generate
      
      for ( i = 0; i < 9; i = i + 1 ) begin
        
        // MUX for A register
        if ( i < 8 ) // avg case, normal 8-bit data
          mux_2_to_1 MUX_DATAIN_A (
            .data_in ( { adder_SUM[i], inbus[i] } ),
	          .select ( loadAregisterfromADDER ),
	          .data_out ( data_in_A[i] )
          );
        else // useful only for SRT-2 // and not even then
          mux_2_to_1 MUX_DATAIN_A (
            .data_in ( { adder_SUM[i], 1'b0 } ),
	          .select ( loadAregisterfromADDER ),
	          .data_out ( data_in_A[i] )
          );
          
        // MUX for Q register // must account for offset of 1 // mathematically, in Radix-4, there is Q[-1]
                              // problem solved with jump_LSb in rgst module interface
        if ( i == 0 ) // exceptional init case // for Radix-4
          mux_2_to_1 MUX_DATAIN_Q (
            .data_in ( { 1'b0, 1'b0 } ),
	          .select ( loadQregisterfromADDER ),
	          .data_out ( data_in_Q[i] )
          );
        else // avg case
          mux_2_to_1 MUX_DATAIN_Q (
            .data_in ( { adder_SUM[i - 1], inbus[i - 1] } ),
	          .select ( loadQregisterfromADDER ),
	          .data_out ( data_in_Q[i] )
          );
        
      end
      
    endgenerate

    //=========================================
    // MUXs FOR ADDER DATA INPUTS
    //==========================================
    
    wire [8 : 0] hileftMUX, loleftMUX, hirightMUX, lorightMUX, hiMUX, loMUX;
    assign operand_A = hiMUX;
    assign operand_B = loMUX;
    
    generate // (-1) operands taken care of by sum or dif signal
      
      for ( i = 0; i < 9; i = i + 1 ) begin
        
        // written with 2 to 1 MUXs instead of 4 to 1 MUXs
        // for ease of writing, according to signals from CU
        
        // left side == A and 1/2M; right side == 1/Q and +-Qprim
        
        // hi side
        // for OPERAND A // can be ::   A   A   A   A   1       Q
        
        // left side
        mux_2_to_1 hiMUX_A_A (
          .data_in ( { A[i], A[i] } ),
          .select ( select2Msum ),
          .data_out ( hileftMUX[i] )
        );
        
        // right side
        if ( i == 0 ) // for LSb of 1
          mux_2_to_1 hiMUX_1_Q (
            .data_in ( { 1'b1, Q[i + 1] } ), // all Qs and Qprims to be modified to account for Q[-1] anomaly
            .select ( selectQprimcorrection & ~selectQandQprimdif ),
            .data_out ( hirightMUX[i] )
          );
        else if ( i < 8 )
          mux_2_to_1 hiMUX_1_Q (
            .data_in ( { 1'b0, Q[i + 1] } ),
            .select ( selectQprimcorrection & ~selectQandQprimdif ),
            .data_out ( hirightMUX[i] )
          );
        else 
          mux_2_to_1 hiMUX_1_Q (
            .data_in ( { 1'b0, Q[i] } ),
            .select ( selectQprimcorrection & ~selectQandQprimdif ),
            .data_out ( hirightMUX[i] )
          );
          
        // final choice
        mux_2_to_1 hiMUX_final (
          .data_in ( { hileftMUX[i], hirightMUX[i] } ),
          .select ( selectAandMsum & ~selectQandQprimdif & ~selectQprimcorrection ),
          .data_out ( hiMUX[i] )
        );
        
        // lo side
        // for OPERAND B // can be :: +1M -1M +2M -2M Qprim  -Qprim
        
        // left side
        if ( i == 0 ) // for LSb of M in case of 2M
          mux_2_to_1 loMUX_1M_2M (
            .data_in ( { 1'b0, M[i] } ),
            .select ( select2Msum ),
            .data_out ( loleftMUX[i] )
          );
        else
          mux_2_to_1 loMUX_1M_2M (
            .data_in ( { M[i - 1], M[i] } ),
            .select ( select2Msum ),
            .data_out ( loleftMUX[i] )
          );
          
        // right side
        if ( i < 8 )
          mux_2_to_1 hiMUX_Qprim_Qprim (
            .data_in ( { Qprim[i + 1], Qprim[i + 1] } ),
            .select ( selectQprimcorrection & ~selectQandQprimdif ),
            .data_out ( lorightMUX[i] )
          );
        else
          mux_2_to_1 hiMUX_Qprim_Qprim (
            .data_in ( { Qprim[i], Qprim[i] } ),
            .select ( selectQprimcorrection & ~selectQandQprimdif ),
            .data_out ( lorightMUX[i] )
          );
          
        // final choice
        mux_2_to_1 loMUX_final (
          .data_in ( { loleftMUX[i], lorightMUX[i] } ),
          .select ( selectAandMsum & ~selectQandQprimdif & ~selectQprimcorrection ),
          .data_out ( loMUX[i] )
        );
        
      end
      
    endgenerate

    //=========================================
    // MUXs FOR OUTBUS
    //==========================================
    
    generate
      
      for ( i = 0; i < 8; i = i + 1 ) begin
        
        // tri-state driver output can be added for fun, right now we need to make it work
        
        
        mux_2_to_1 MUX_OUTBUS (
          .data_in ( { A[i], Q[i + 1] } ),
          .select ( pushAregister & ~pushQregister ),
          .data_out ( outbus[i] )
        );
        
      end
      
    endgenerate

endmodule

