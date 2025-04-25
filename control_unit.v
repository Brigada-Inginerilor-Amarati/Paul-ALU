// rework on FSM, one-hot style

module control_unit_one_hot (
  input wire reset, clk, BEGIN, // upper-case because of syntax
  input wire [1:0] op_code, // operation code // 00 - add, 01- sub, 10 - mul, 11 - div
  output wire END // upper-case because of syntax
  );
  
  // localparam to easily acces number of states
  
  localparam number_of_states = 16;
  
  // prin localparam sunt definiti indecsii pe care ii ocupa starile in registrul de stare // ca reprezentare pe biti
  
  localparam IDLE = 0; // starea de idle
  
  // starile de load registers
  localparam LOADA = 1;
  localparam LOADQ = 2; // aici se face si init pe Q[-1], Q'
  localparam LOADM = 3; // aici se face si init contoare
  
  // starile care folosesc sumatorul // in timpul lor se incarca registrii cu rezultatul // <=> semnalele care determina tipul de suma sunt setate dinainte
  localparam ADDMtoA = 4; // valabil pentru +- {1;2}
  localparam ADDMtoACORRECTION = 5; // valabil doar pentru corectie
  localparam ADD1toQprim = 6; // pentru corectie
  localparam ADDminQprimtoQ = 7; // pentru final SRT-2 ( Q := Q - Q' )
  
  // starile de output
  localparam PUSHA = 8;
  localparam PUSHQ = 9;
  
  // stari RSHIFT // specifice Radix-4
  localparam RSHIFT = 10;
  localparam COUNTRSHIFTs = 11; // incrementare counter Radix-4
  
  // stari LSHIFT // specifice SRT-2
  localparam LSHIFT = 12;
  localparam COUNTLSHIFTs = 13; // incrementare counter SRT-2
  
  // stari SRT-2 care tin cont de leading 0s for divisor
  // starile de corectie sunt reprezentate prin a tine cont de operatie si un registru suplimentar ca flag
  localparam LSHIFTfor0 = 14; // eliminare leading 0s from divisor
  localparam RSHIFTfor0 = 15; // corectie in functie de leading 0s from divisor
  
  // wires for actual and next state
  wire [number_of_states - 1 : 0] act_state;
  wire [number_of_states - 1 : 0] next_state;
  
  genvar i;
  
  // generate the state register
  
  generate
    
    for ( i = 0; i < number_of_states; i = i + 1 ) begin
      
      if ( i == IDLE ) // flip flop-ul specific IDLE primeste un jumpstart
        dff_rst_to_1 dff_rst_to_1_inst (
	     .clk ( clk ),
	     .reset ( reset ),
	     .load_enable ( 1 ),
	     .data_in ( next_state[i] ),
	     .data_out ( act_state[i] )
      );
      else // flip flop pentru fiecare stare
        dff dff_inst (
	       .clk ( clk ),
	       .reset ( reset ),
	       .load_enable ( 1 ),
	       .data_in ( next_state[i] ),
	       .data_out ( act_state[i] )
      );
      
    end
    
  endgenerate
  
  // assigning all next states
  
  // can be optimised and factorised, right now written for clarity from FSM "schmematic"
  
  // endings are considered graceful endings here
  assign next_state[IDLE] = ( act_state[IDLE] & ~BEGIN ) // waiting for BEGIN signal
                          | ( ~op_code[1] & ( act_state[PUSHA] ) ) // for add and sub operations ending
                          | ( op_code[1] & ~op_code[0] & act_state[PUSHQ] ) // for mul operation ending
                          | ( op_code[1] & op_code[0] & act_state[PUSHA] ); // for div operation ending
  
  // loading input states                         
  assign next_state[LOADA] = BEGIN & ( ( ~op_code[1] ) | ( op_code[1] & op_code[0] ) ); // for add, sub, div
  assign next_state[LOADQ] = ( BEGIN & ( op_code[1] & ~op_code[0] ) ) // for mul
                           | ( act_state[LOADA] & op_code[1] & op_code[0] ); // for div
  assign next_state[LOADM] = ( act_state[LOADA] & ~op_code[1] ) // for add, sub
                           | act_state[LOADQ]; // for for mul, div
  
  // following states expressions need to be completed depending on signals, flag, decisions
  // decision_based_on_correction needs to be split between decision_based_on_SRT2_counter and decision_based_on_MSb_of_A
  // decision_based_on_correction_other needs to be split between decision_based_on_SRT2_counter and ~decision_based_on_MSb_of_A
  
  // states using the adder
  assign next_state[ADDMtoA] = ( act_state[LOADM] & ~op_code[1] ) // for add, sub
                             | ( act_state[LOADM] & op_code[1] & ~op_code[0] & decision_on_bits_of_Q ) // for mul
                             | ( act_state[COUNTRSHIFTs] & decision_on_bits_of_Q )
                             // for div // only from LSHIFT state with decision on ( flag ) leading bits of A
                             | ( act_state[LSHIFT] & decision_on_flag_bits_of_A );
  assign next_state[ADDMtoACORRECTION] = ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_correction ) // only for div correction // correction needs to be decided on SRT-2 counter and MSb of A
                                       | ( act_state[LSHIFT] & ~decision_on_flag_bits_of_A & decision_based_on_correction ); // skip ADDMtoA from LSHIFT
  assign next_state[ADD1toQprim] = ( act_state[ADDMtoACORRECTION] ); // to complete SRT-2 correction
  assign next_state[ADDminQprimtoQ] = ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_correction_other ) // to find real value of Q register in SRT-2 algorithm
                                       | ( act_state[LSHIFT] & decision_based_on_correction_other )
                                       | ( act_state[ADD1toQprim] ); // if correction was applied
  
  // states for OUTBUS loading
  assign next_state[PUSHA] = ( act_state[ADDMtoA] & ~op_code[1] ) // for add, sub
                           | ( act_state[RSHIFT] & decision_based_on_Radix4_counter ) // for mul
                           | ( act_state[PUSHQ] & op_code[1] & op_code[0] ); // for div
  assign next_state[PUSHQ] = ( act_state[PUSHA] & op_code[1] & ~op_code[0] ) // for mul
                           | ( act_state[ADDminQprimtoQ] & decision_based_on_Leading0s_counter ) // for div
                           | ( act_state[RSHIFTfor0] & decision_based_on_Leading0s_counter );
                           
  // states for Radix-4 right shifting // specific only for mul
  assign next_state[RSHIFT] = ( act_state[ADDMtoA] & op_code[1] & ~op_code[0] );
  assign next_state[COUNTRSHIFTs] = ( act_state[RSHIFT] & ~decision_based_on_Radix4_counter );
  
  // states for SRT-2 left shifting // result calculation Lshifts // general-case
  assign next_state[LSHIFT] = ( act_state[LOADM] & op_code[1] & op_code[0] & decision_based_on_MSb_of_M_related_to_leading0s ) // also need to update the flags for ADDMtoA next_next_state
                            | ( act_state[LSHIFTfor0] & decision_based_on_MSb_of_M_related_to_leading0s );
  assign next_state[COUNTLSHIFTs] = ( act_state[ADDMtoA] & op_code[1] & op_code[0] & decision_based_on_SRT2_counter )
                                  | ( act_state[LSHIFT] & ~decision_on_flag_bits_of_A & decision_based_on_SRT2_counter );
  
  // states for SRT-2 operand formatting
  assign next_state[LSHIFTfor0] = ( act_state[LOADM] & op_code[1] & op_code[0] & decision_based_on_MSb_of_M_related_to_leading0s );
  assign next_state[RSHIFTfor0] = ( act_state[ADDminQprimtoQ] & ~decision_based_on_Leading0s_counter );
   
endmodule