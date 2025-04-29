// rework on FSM, one-hot style

module control_unit_one_hot (
    input wire reset_input,  // sets state to IDLE // active on 1 // inside module active on 0 // check reset wire
    clk,
    BEGIN,  // upper-case because of syntax
    input wire [1 : 0] op_code,  // operation code // 00 - add, 01- sub, 10 - mul, 11 - div
    input wire [2 : 0] bits_of_Q,  // LS bits of Q register
    input wire [2 : 0] bits_of_A,  // MS bits of A register
    input wire sgn_bit_of_M,  // MSb of M
    input wire countSRT2full,  // wire if Counter for SRT-2 is full // value is 7
    input wire countRadix4full,  // similar wire, for Radix-4 // value is 3
    input wire countLeading0sempty,  // similar wire, for SRT-2 Leading0s // value is 0
    output wire loadAregister_from_INBUS,
    loadQregister_from_INBUS,
    loadMregister_from_INBUS,  // load A/Q/M register from INBUS
    output wire initAregisterto0,  // init A register to 0 for mul operation
    output wire initQandQprimregisters, // initialise with 0 Qprim and Q[-1] registers // Q[-1] mathematically
    output wire initCounters, // initialise with 0 Qprim and Q[-1] registers // Q[-1] mathematically
    output wire increment_Leading0s,
    decrement_Leading0s,  // in/decrement Leading0s counter // specific SRT-2
    output wire loadAregisterfromADDER,  // load adder result to A register
    output wire loadQprimregisterfromADDER, // load adder result to Q prim register // specific for correction in SRT-2
    output wire loadQregisterfromADDER, // load adder result to Q register // when formating SRT-2 result
    output wire increment_Radix4Counter,  // increment Radix-4 counter
    output wire RSHIFT_signal,  // RSHIFT registers
    output wire LSHIFT_signal,  // LSHIFT registers
    output wire increment_SRT2Counter,  // increment SRT-2 normal counter
    output wire pushAregister,  // push A register to OUTBUS
    output wire pushQregister,  // push Q register to OUTBUS
    output wire select_sum_or_dif,  // 0 if adder calculates a sum of operands; 1 if difference
    output wire selectAandMsum,  // 1 if A and M sum is selected; 0 if not
    output wire select2Msum,  // 0 if sum is with +-1M; 1 if +-2M
    output wire selectQprimcorrection,  // 1 if adds 1 to Q prim // SRT-2 correction
    output wire selectQandQprimdif,  // 1 if Q and Q prim dif is used // SRT-2 specific
    output wire write_to_Qs_enable,  // 1 if CU needs to write value to LSb of Q and Qprim registers
    output wire Q_value,  // value to be written in LSb of Q // for SRT-2
    output wire Qprim_value,  // value to be written in LSb of Qprim // for SRT-2
    output wire END,  // upper-case because of syntax
    output wire [16 : 0] act_state_debug,
    output wire [16 : 0] next_state_debug
);

    wire reset;  // due to big mishaps // acts like active on 0
    assign reset = ~reset_input;

    // localparam to easily acces number of states

    localparam number_of_states = 17;

    // prin localparam sunt definiti indecsii pe care ii ocupa starile in registrul de stare // ca reprezentare pe biti

    localparam IDLE = 0;  // starea de idle

    // starile de load registers
    localparam LOADA = IDLE + 1;
    localparam LOADQ = LOADA + 1;  // aici se face si init pe Q[-1], Q'
    localparam LOADM = LOADQ + 1;  // aici se face si init contoare

    // starile care folosesc sumatorul // in timpul lor se incarca registrii cu rezultatul // <=> semnalele care determina tipul de suma sunt setate dinainte
    localparam ADDMtoA = LOADM + 1;  // valabil pentru +- {1;2}
    localparam ADDMtoACORRECTION = ADDMtoA + 1;  // valabil doar pentru corectie
    localparam ADD1toQprim = ADDMtoACORRECTION + 1;  // pentru corectie
    localparam ADDminQprimtoQ = ADD1toQprim + 1;  // pentru final SRT-2 ( Q := Q - Q' )

    // starile de output
    localparam PUSHA = ADDminQprimtoQ + 1;
    localparam PUSHQ = PUSHA + 1;

    // stari RSHIFT // specifice Radix-4
    localparam RSHIFT = PUSHQ + 1;
    localparam RSHIFT_DOUBLE = RSHIFT + 1;
    localparam COUNTRSHIFTs = RSHIFT_DOUBLE + 1;  // incrementare counter Radix-4

    // stari LSHIFT // specifice SRT-2
    localparam LSHIFT = COUNTRSHIFTs + 1;
    localparam COUNTLSHIFTs = LSHIFT + 1;  // incrementare counter SRT-2

    // stari SRT-2 care tin cont de leading 0s for divisor
    // starile de corectie sunt reprezentate prin a tine cont de operatie si un registru suplimentar ca flag
    localparam LSHIFTfor0 = COUNTLSHIFTs + 1;  // eliminare leading 0s from divisor
    localparam RSHIFTfor0 = LSHIFTfor0 + 1;  // corectie in functie de leading 0s from divisor

    // wires for actual and next state
    wire [number_of_states - 1 : 0] act_state;
    wire [number_of_states - 1 : 0] next_state;

    assign act_state_debug  = act_state;
    assign next_state_debug = next_state;

    // decisional data

    wire decision_on_bits_of_Q;
    wire decision_on_flag_bits_of_A; // skips ADDMtoA
    wire decision_based_on_correction;
    wire decision_based_on_correction_other;
    wire decision_based_on_Radix4_counter;
    wire decision_based_on_Leading0s_counter;
    wire decision_based_on_MSb_of_M_related_to_leading0s;
    wire decision_based_on_SRT2_counter;

    // value for decisional flag

    // intermediate wire, for ease of writing
    wire interm_decision_on_flag_bits_of_A; // skips ADDMtoA
    assign interm_decision_on_flag_bits_of_A = ( act_state[LSHIFT] & decision_on_flag_bits_of_A ) // to ensure flag is taken right before LSHIFT and kept over its duration
                                             | (
                                               ( act_state[COUNTLSHIFTs] | act_state[LSHIFTfor0] | ( act_state[LOADM] & op_code[1] & op_code[0] ) ) // select when to set value
                                               & (
                                                  ~(
                                                      ( bits_of_A[2] & bits_of_A[1] & bits_of_A[0] )
                                                      | ( ~bits_of_A[2] & ~bits_of_A[1] & ~bits_of_A[0] )
                                                  )
                                               ) // to know flag is needed to be set
        );

    dff dff_inst (
        .clk(clk),
        .reset(reset),
        .load_enable( 1'b1 ),
        .data_in ( interm_decision_on_flag_bits_of_A & sgn_bit_of_M ), // sgn_bit_of_M just to be sure // shouldn't be needed
        .data_out(decision_on_flag_bits_of_A)
    );

    // values for other decisional wires

    assign decision_on_bits_of_Q = ~( ( bits_of_Q[2] & bits_of_Q[1] & bits_of_Q[0] ) | ( ~bits_of_Q[2] & ~bits_of_Q[1] & ~bits_of_Q[0] ) ); // do ADDMtoA // without ~(...) it would be skip ADDMtoA
    assign decision_based_on_correction = countSRT2full & bits_of_A[2];
    assign decision_based_on_correction_other = countSRT2full & ~bits_of_A[2];
    assign decision_based_on_Radix4_counter = countRadix4full;
    assign decision_based_on_Leading0s_counter = countLeading0sempty;
    assign decision_based_on_MSb_of_M_related_to_leading0s = sgn_bit_of_M;
    assign decision_based_on_SRT2_counter = ~countSRT2full;

    // generate the state register

    genvar i;

    generate

        for (i = 0; i < number_of_states; i = i + 1) begin

            if (i == IDLE)  // flip flop-ul specific IDLE primeste un jumpstart
                dff_rst_to_1 dff_rst_to_1_inst (
                    .clk(clk),
                    .reset(~reset),
                    .load_enable(1'b1),
                    .data_in(next_state[i]),
                    .data_out(act_state[i])
                );
            else  // flip flop pentru fiecare stare
                dff dff_inst (
                    .clk(clk),
                    .reset(~reset),
                    .load_enable(1'b1),
                    .data_in(next_state[i]),
                    .data_out(act_state[i])
                );

        end

    endgenerate

    wire left_in_neutral_state;
    // assign left_in_neutral_state = ( act_state == 0 );
    assign left_in_neutral_state = 1'b0;

    // assigning all next states

    // can be optimised and factorised, right now written for clarity from FSM "schmematic"

    // endings are considered graceful endings here
    assign next_state[IDLE] = left_in_neutral_state | ~reset  // when HW is reset
        | (act_state[IDLE] & ~BEGIN)  // waiting for BEGIN signal
        | (~op_code[1] & act_state[PUSHA])  // for add and sub operations ending
        | (op_code[1] & ~op_code[0] & act_state[PUSHQ])  // for mul operation ending
        | (op_code[1] & op_code[0] & act_state[PUSHA]);  // for div operation ending

    // loading input states
    assign next_state[LOADA] = reset & act_state[IDLE] & BEGIN & ( ( ~op_code[1] ) | ( op_code[1] & op_code[0] ) ); // for add, sub, div
    assign next_state[LOADQ] = reset & ((BEGIN & act_state[IDLE] & (op_code[1] & ~op_code[0]))  // for mul
        | (act_state[LOADA] & op_code[1] & op_code[0]));  // for div
    assign next_state[LOADM] = reset & ((act_state[LOADA] & ~op_code[1])  // for add, sub
        | act_state[LOADQ]);  // for for mul, div

    // following states expressions need to be completed depending on signals, flag, decisions
    // decision_based_on_correction needs to be split between decision_based_on_SRT2_counter and decision_based_on_MSb_of_A
    // decision_based_on_correction_other needs to be split between decision_based_on_SRT2_counter and ~decision_based_on_MSb_of_A

    // states using the adder
    assign next_state[ADDMtoA] = ~BEGIN & reset & ((act_state[LOADM] & ~op_code[1])  // for add, sub
        | (act_state[LOADM] & op_code[1] & ~op_code[0] & decision_on_bits_of_Q)  // for mul
        | (act_state[COUNTRSHIFTs] & decision_on_bits_of_Q)
        // for div // only from LSHIFT state with decision on ( flag ) leading bits of A
        | (act_state[LSHIFT] & ~decision_on_flag_bits_of_A));
    assign next_state[ADDMtoACORRECTION] = ~BEGIN & reset
                                         & (
                                              ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_correction ) // only for div correction // correction needs to be decided on SRT-2 counter and MSb of A
                                              | ( act_state[LSHIFT] & decision_on_flag_bits_of_A & decision_based_on_correction ) // skip ADDMtoA from LSHIFT
                                            );
    assign next_state[ADD1toQprim] = ~BEGIN & reset & ( ( act_state[ADDMtoACORRECTION] ) ); // to complete SRT-2 correction
    assign next_state[ADDminQprimtoQ] = ~BEGIN & reset
                                      & (
                                          ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_correction_other ) // to find real value of Q register in SRT-2 algorithm
                                          | ( act_state[LSHIFT] & decision_based_on_correction_other & decision_on_flag_bits_of_A )
                                          | ( act_state[ADD1toQprim] )
                                        ); // if correction was applied

    // states for OUTBUS loading
    assign next_state[PUSHA] = ~BEGIN & reset & ((act_state[ADDMtoA] & ~op_code[1])  // for add, sub
        | (act_state[RSHIFT_DOUBLE] & decision_based_on_Radix4_counter)  // for mul
        | (act_state[PUSHQ] & op_code[1] & op_code[0]));  // for div
    assign next_state[PUSHQ] = ~BEGIN & reset
                             & (
                                  ( act_state[PUSHA] & op_code[1] & ~op_code[0] )  // for mul
                                  | ( act_state[ADDminQprimtoQ] & decision_based_on_Leading0s_counter )  // for div
                                  | ( act_state[RSHIFTfor0] & decision_based_on_Leading0s_counter )
                               );

    // states for Radix-4 right shifting // specific only for mul
    assign next_state[RSHIFT] = ~BEGIN & reset
                              &
                                (
                                  (act_state[ADDMtoA] & op_code[1] & ~op_code[0]) // if ADDMtoA done
        | (act_state[LOADM] & op_code[1] & ~op_code[0] & ~decision_on_bits_of_Q) // if first right shift after loadM
        | (act_state[COUNTRSHIFTs] & ~decision_on_bits_of_Q) // if ADDMtoA not done after incrementing Radix-4 counter
        );
    assign next_state[RSHIFT_DOUBLE] = ~BEGIN & reset & (act_state[RSHIFT]);
    assign next_state[COUNTRSHIFTs] = ~BEGIN & reset & ( (act_state[RSHIFT_DOUBLE] & ~decision_based_on_Radix4_counter) );

    // states for SRT-2 left shifting // result calculation Lshifts // general-case
    assign next_state[LSHIFT] = ~BEGIN & reset &
                              ( 
                                ( act_state[LOADM] & op_code[1] & op_code[0] & decision_based_on_MSb_of_M_related_to_leading0s ) // also need to update the flags for ADDMtoA next_next_state
                                | ( act_state[LSHIFTfor0] & decision_based_on_MSb_of_M_related_to_leading0s )
                                | ( act_state[COUNTLSHIFTs] )
                              );
    assign next_state[COUNTLSHIFTs] = ~BEGIN & reset &
                                    (
                                      ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_SRT2_counter )
                                      | ( act_state[LSHIFT] & decision_on_flag_bits_of_A & decision_based_on_SRT2_counter )
                                    );

    // states for SRT-2 operand formatting
    assign next_state[LSHIFTfor0] = ~BEGIN & reset
                                  & (
                                      ( act_state[LOADM] & op_code[1] & op_code[0] & ~decision_based_on_MSb_of_M_related_to_leading0s )
                                      | ( act_state[LSHIFTfor0] & ~decision_based_on_MSb_of_M_related_to_leading0s )
                                    );
    assign next_state[RSHIFTfor0] = ~BEGIN & reset
                                  & (
                                      ( act_state[ADDminQprimtoQ] & ~decision_based_on_Leading0s_counter )
                                      | ( act_state[RSHIFTfor0] & ~decision_based_on_Leading0s_counter )
                                    );

    // assigning all output signals // control signals for HW architecture

    // external signal
    assign END = next_state[IDLE] & ~act_state[IDLE] & reset; // when changing state to IDLE and program was not already in IDLE and HW was not reset

    // load registers from INBUS
    assign loadAregister_from_INBUS = next_state[LOADA];
    assign loadQregister_from_INBUS = next_state[LOADQ];
    assign loadMregister_from_INBUS = next_state[LOADM];

    // init registers
    assign initAregisterto0 = next_state[LOADQ] & op_code[1] & ~op_code[0];
    // assign initQandQprimregisters = next_state[LOADM];
    assign initQandQprimregisters = reset_input;
    assign initCounters = next_state[LOADM];

    // control leading 0s
    assign increment_Leading0s = next_state[LSHIFTfor0] & ~sgn_bit_of_M;
    assign decrement_Leading0s = next_state[RSHIFTfor0];

    //increment normal counters
    assign increment_Radix4Counter = next_state[COUNTRSHIFTs];
    assign increment_SRT2Counter = next_state[COUNTLSHIFTs];

    // shift registers
    assign RSHIFT_signal = next_state[RSHIFT] | next_state[RSHIFT_DOUBLE];
    assign LSHIFT_signal = next_state[LSHIFT];

    // sum control signals
    assign loadAregisterfromADDER = next_state[ADDMtoA] | next_state[ADDMtoACORRECTION];
    assign loadQprimregisterfromADDER = next_state[ADD1toQprim];
    assign loadQregisterfromADDER = next_state[ADDminQprimtoQ];

    // OUTBUS loading signals
    assign pushAregister = next_state[PUSHA];
    assign pushQregister = next_state[PUSHQ];

    // adder operand control signals
    assign selectAandMsum = next_state[ADDMtoA] | next_state[ADDMtoACORRECTION];
    assign select2Msum = next_state[ADDMtoA] & op_code[1] & ~op_code[0]
                       & (
                            ( ~bits_of_Q[2] & bits_of_Q[1] & bits_of_Q[0] )
                            | ( bits_of_Q[2] & ~bits_of_Q[1] & ~bits_of_Q[0] )
                         );
    assign selectQprimcorrection = next_state[ADD1toQprim];
    assign selectQandQprimdif = next_state[ADDminQprimtoQ];
    assign select_sum_or_dif = selectQandQprimdif
                             | ( selectAandMsum
                               & (
                                    ( ~op_code[1] & op_code[0] ) // for dif
        | (op_code[1] & ~op_code[0] & bits_of_Q[2])  // for mul
        | (op_code[1] & op_code[0] & ~bits_of_A[2])  // for div
        ));

    // values to be written in SRT-2 Q and Qprim registers
    assign write_to_Qs_enable = next_state[LSHIFT];
    assign Q_value = ~decision_on_flag_bits_of_A & ~bits_of_A[2];
    assign Qprim_value = ~decision_on_flag_bits_of_A & bits_of_A[2];

endmodule
