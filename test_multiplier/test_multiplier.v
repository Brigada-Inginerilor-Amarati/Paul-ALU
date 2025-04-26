// 2 rgst 9 bit
// 1 rgst 8 bit
// 1 flip flop
// double arithmetic shifter

// precompute
// M, 2M, -M, -2M

// 9 input signals c0 -> c8
// output, 3 control bits

// internal 2 bit counter -> to 3
// output to outbus

module adder #(
    parameter WIDTH = 9
) (
    input wire signed [WIDTH-1:0] a,
    input wire signed [WIDTH-1:0] b,
    input wire                    carry_in,
    output wire signed [WIDTH-1:0] sum
);

    assign sum = a + b + carry_in;

endmodule


module counter #(
    parameter WIDTH = 2
) (
    input  wire               clk,
    input  wire               rst_b,
    input  wire               enable,
    output reg  [WIDTH-1:0]   cnt
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) cnt <= {WIDTH{1'b0}};
        else if (enable) cnt <= cnt + 1'b1;
    end

endmodule


module register #(
    parameter WIDTH = 8
) (
    input  wire               clk,
    input  wire               rst_b,
    input  wire               enable,
    input  wire [WIDTH-1:0]   in,
    output reg  [WIDTH-1:0]   out
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= in;
    end

endmodule


module shift_slicer(
    input wire enable,
    input wire [17:0] full_slice,
    output wire [8:0] a_slice,
    output wire [7:0] b_slice,
    output wire c_slice
);

assign a_slice = enable ? full_slice[17:9] : a_slice;
assign b_slice = enable ? full_slice[8:1] : b_slice;
assign c_slice = enable ? full_slice[0] : c_slice;

endmodule


module select_multiplicand (
  input  wire c3,
  input  wire c4,
  input  wire signed [8:0] pre_M0,
  input  wire signed [8:0] pre_M1,
  input  wire signed [8:0] pre_M2,
  input  wire signed [8:0] pre_M3,
  output reg  signed [8:0] M
);
  always @* begin
    case ({c4,c3})
      2'b00: M = pre_M0;
      2'b01: M = pre_M1;
      2'b10: M = pre_M2;
      2'b11: M = pre_M3;
    endcase
  end
endmodule


module counter_check(
    input wire [1:0] cnt,
    output wire cnt3
);

    assign cnt3 = cnt[1] & cnt[0];

endmodule

module right_shifter #(
  parameter WIDTH = 18
)(
  input  wire               enable,
  input  wire signed [WIDTH-1:0] in,
  output wire signed [WIDTH-1:0] out
);
  // >>> on a signed operand does an arithmetic shift
  assign out = enable ? (in >>> 2) : in;
endmodule

// C0 -> init A = 0, Cnt = 0, Qm1 = 0, M = inbus
// C1 -> Q = inbus
// C2 -> add M
// C2 * C3 -> add 2M
// C2 * C4 -> add -M
// C2 * C3 * C4 -> add -2M
// no C2 -> C5
// C5 -> arithmetic right shift * 2 for 18 bits
// Count3 == 1
// No -> send signal to CU
// C6 -> count up, move to check bits
// Yes -> C7
// C7 -> outbus A
// C8 -> outbus B

module booth_radix4_multiplier (
    input  wire               clk,
    input  wire               rst_b,
    input  wire signed [ 7:0] inbus,
    input  wire        [ 8:0] c,
    output wire               count3,       // counter reached end
    output wire        [ 2:0] ctrl_bits,  // {Q[1],Q[0],Qm1}
    output wire signed [15:0] outbus,

    // new debug ports
    output [8:0] A_out,
    output [7:0] Q_out,
    output       Qm1_out,
    output [1:0] cnt_out,
    // expose adder and next-A signals
    output wire signed [8:0] debug_sumA,
    output wire signed [8:0] debug_addM,
    output wire             debug_ldA,
    output wire signed [8:0] debug_nextA
);

    wire signed [8:0] A, M;
    wire signed [7:0] Q;
    wire              Qm1;
    wire        [1:0] cnt;
    wire signed [8:0] precomputed_M [0:3];

    assign A_out = A;
    assign Q_out = Q;
    assign Qm1_out = Qm1;
    assign cnt_out = cnt;

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 0) Set registers and Input Bus M
    //––––––––––––––––––––––––––––––––––––––––––––––––
    
    register #(9) inbus_rgst_M (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[0]),
        .in({inbus[7], inbus}),
        .out(M)
    );


    // register for Qm1, initialize to 0 on c0 (updated below after shifter)
    // register for counter, initialize to 0 on c0
    register #(2) regCnt (
      .clk    (clk),
      .rst_b  (rst_b),
      .enable (c[0]),
      .in     (2'b0),
      .out    (cnt)
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 1) Input bus Q, precompute M, set ctrl_bits
    //––––––––––––––––––––––––––––––––––––––––––––––––
    // Q register: combined load, see below after shifter

    // Precompute signed multiples of M for Booth:
    assign precomputed_M[0] = M;             // +1·M
    assign precomputed_M[1] = M <<< 1;       // +2·M
    assign precomputed_M[2] = -M;            // ~1·M
    assign precomputed_M[3] = -(M <<< 1);    // ~2·M

    assign ctrl_bits = { Q[1], Q[0], Qm1 };

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 2) Select which multiple under c2,c3,c4
    //––––––––––––––––––––––––––––––––––––––––––––––––
    wire [8:0] additionM;
    select_multiplicand sel_u (
        .c3      (c[3]),
        .c4      (c[4]),
        .pre_M0(precomputed_M[0]),
        .pre_M1(precomputed_M[1]),
        .pre_M2(precomputed_M[2]),
        .pre_M3(precomputed_M[3]),
        .M(additionM)
    );
    // 4→1 mux for chosen multiple

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 3) Adder: A = A + M if c2 = 1
    //––––––––––––––––––––––––––––––––––––––––––––––––
    wire signed [8:0] sumA;
    adder adder_inst (
    .a       (A),
    .b       (additionM),
    .carry_in(1'b0),
    .sum     (sumA)
    );

    // Expose sumA and additionM for debug
    assign debug_sumA  = sumA;
    assign debug_addM  = additionM;

    // Next-A logic: combinational logic for nextA and ldA
    wire ldA;
    wire signed [8:0] nextA;
    assign ldA = c[2];
    assign nextA = sumA;


    // Expose ldA and nextA for debug
    assign debug_ldA     = ldA;
    assign debug_nextA   = nextA;
    
    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 4) Shift–register for {A,Q,Qm1}
    //––––––––––––––––––––––––––––––––––––––––––––––––

    wire signed [17:0] full_slice = {A, Q, Qm1};
    wire signed [17:0] shifted_slice;
    
    right_shifter #(18) arithmetic_r_sh(
        .enable(c[5]),
        .in(full_slice),
        .out(shifted_slice)
    );

    // after shifting
    wire [7:0]  Q_shifted   = shifted_slice[8:1];
    wire        Qm1_shifted = shifted_slice[0];

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 5) Slice “shift_out” into A, Q, Qm1
    //––––––––––––––––––––––––––––––––––––––––––––––––

    // Q register: loads inbus on c1, shifted Q on c5
    register #(.WIDTH(8)) regQ (
      .clk    (clk),
      .rst_b  (rst_b),
      .enable (c[1] | c[5]),
      .in     (c[1] ? inbus : Q_shifted),
      .out    (Q)
    );

    // Qm1 register: loads 0 on c0, shifted Qm1 on c5
    register #(.WIDTH(1)) regQm1 (
      .clk    (clk),
      .rst_b  (rst_b),
      .enable (c[0] | c[5]),
      .in     (c[0] ? 1'b0 : Qm1_shifted),
      .out    (Qm1)
    );

    // Separate register for A: loads on c0, c2, c5 using nextA as before
    wire signed [8:0] regA_in;
    assign regA_in = c[0] ? 9'sd0 : (c[2] ? nextA : shifted_slice[17:9]);
    register #(.WIDTH(9)) regA (
      .clk    (clk),
      .rst_b  (rst_b),
      .enable (c[0] | c[2] | c[5]),
      .in     (regA_in),
      .out    (A)
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 6) Instantiate Counter and Compute CNT3
    //––––––––––––––––––––––––––––––––––––––––––––––––

    counter #(2) cnt_inst (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[6]),
        .cnt(cnt)
    );

    counter_check cnt_check(
        .cnt(cnt),
        .cnt3(count3)
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 7) Send to outbus
    //––––––––––––––––––––––––––––––––––––––––––––––––

    register #(8) outbus_1 (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[7]),
        .in(A[7:0]),
        .out(outbus[15:8])
    );

    register #(8) outbus_2 (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[8]),
        .in(Q[7:0]),
        .out(outbus[7:0])
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    //
    //––––––––––––––––––––––––––––––––––––––––––––––––
    
endmodule

/*

c0 -> enable INPUT1 register M, init A, init cnt, init Qm1
c1 -> enable INPUT2 register Q
c2 -> enable ADDER
c3 -> enable DOUBLE
c4 -> enable NEGATE
c5 -> enable SHIFTER
c6 -> enable COUNTER
c7 -> enable OUTPUT1
c8 -> enable OUTPUT2

*/

module control_unit (
    input wire clk,
    rst_b,
    begin_op,
    input wire [1:0] op_code,
    input wire [2:0] ctrl_bits,
    input wire count3,
    output reg [8:0] ctrl_sig,
    output reg end_op
);

    localparam IDLE = 4'b0000;
    localparam LOAD1 = 4'b0001;  // sends c0, next is LOAD2
    localparam LOAD2 = 4'b0010;  // sends c1, next is check
    localparam CHECK_CTRL_BITS = 4'b0011;  // checks control bits, next sends c2, c3 or c4 or nothing
    localparam ADD_MULTIPLICAND = 4'b0100;  // adds multiplicand depending on control bits
    localparam SHIFT_RIGHT = 4'b0101;  // shifts right 2 bits, next is count3 verifiy, sends c5
    localparam COUNT3_VERIFY = 4'b0110;  // counts 3, verifies result, if yes, sends c7, if not, sends c6
    localparam COUNT_UP = 4'b0111;  // counts up, moves to CHECK_CTRL_BITS
    localparam OUT1 = 4'b1000;  // sends c8, next is OUT2
    localparam OUT2 = 4'b1001;  // sends end_op, next is IDLE

    reg [3:0] state, next_state;

    // fsm logic

    always @(*) begin
        case (state)
            IDLE: begin
                ctrl_sig = 9'b0;
                end_op   = 0;

                if (begin_op) begin
                    ctrl_sig[0] = 1;
                    next_state  = LOAD1;

                end else begin
                    next_state = IDLE;
                end
            end
            LOAD1: begin
                ctrl_sig = 9'b0;
                next_state = LOAD2;
                ctrl_sig[1] = 1;
            end
            LOAD2: begin
                ctrl_sig   = 9'b0;
                next_state = CHECK_CTRL_BITS;

            end
            CHECK_CTRL_BITS: begin
                ctrl_sig = 9'b0;
                if (ctrl_bits == 3'b000 | ctrl_bits == 3'b111) begin
                    
                    ctrl_sig[5] = 1;
                    next_state  = SHIFT_RIGHT;
                end

                else begin

                ctrl_sig[2] = 1;
                ctrl_sig[3] = (~ctrl_bits[2] & ctrl_bits[1] & ctrl_bits[0]) | (ctrl_bits[2] & ~ctrl_bits[1] & ~ctrl_bits[0]);
                ctrl_sig[4] = (ctrl_bits[2] & ~ctrl_bits[0]) | (ctrl_bits[2] & ~ctrl_bits[1]);

                next_state = ADD_MULTIPLICAND;

                end
            end
            ADD_MULTIPLICAND: begin
                ctrl_sig = 9'b0;
                next_state = SHIFT_RIGHT;
                ctrl_sig[5] = 1;
            end
            SHIFT_RIGHT: begin
                ctrl_sig   = 9'b0;
                next_state = COUNT3_VERIFY;
            end
            COUNT3_VERIFY: begin
                ctrl_sig = 9'b0;
                if (count3) begin
                    next_state  = OUT1;
                    ctrl_sig[7] = 1;
                end else begin
                    next_state  = COUNT_UP;
                    ctrl_sig[6] = 1;
                end
            end
            COUNT_UP: begin
                ctrl_sig   = 9'b0;
                next_state = CHECK_CTRL_BITS;
            end
            OUT1: begin
                ctrl_sig = 9'b0;
                next_state = OUT2;
                ctrl_sig[8] = 1;
            end
            OUT2: begin
                ctrl_sig = 9'b0;
                next_state = IDLE;
                end_op = 1;
            end
        endcase
    end

    // fsm logic
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

endmodule


`timescale 1ns/1ps

module tb_booth_radix4;

  // clocks and control
  reg         clk;
  reg         rst_b;
  reg         start;
  reg  signed [7:0] inbus;
  
  // wires between CU <-> DUT
  wire [8:0]  c;
  wire [2:0]  ctrl_bits;
  wire        count3;
  wire        end_op;
  wire signed [15:0] outbus;

  // debug
  wire [8:0] A_out;
  wire [7:0] Q_out;
  wire Qm1_out;
  wire [1:0] cnt_out;
  // adder/nextA debug signals
  wire signed [8:0] debug_sumA_tb, debug_addM_tb, debug_nextA_tb;
  wire              debug_ldA_tb;

  // DUT: Booth multiplier datapath
  booth_radix4_multiplier dut (
    .clk      (clk),
    .rst_b    (rst_b),
    .inbus    (inbus),
    .c        (c),
    .count3   (count3),
    .ctrl_bits(ctrl_bits),
    .outbus   (outbus),

    .A_out(A_out),
    .Q_out(Q_out),
    .Qm1_out(Qm1_out),
    .cnt_out(cnt_out),
    // connect debug ports
    .debug_sumA (debug_sumA_tb),
    .debug_addM (debug_addM_tb),
    .debug_ldA  (debug_ldA_tb),
    .debug_nextA(debug_nextA_tb)
  );

  // CU: control‐signal generator
  // pad the 3‐bit ctrl_bits up to 4 bits with a leading 0
  control_unit cu (
    .clk       (clk),
    .rst_b     (rst_b),
    .begin_op  (start),
    .op_code   (2'b10),
    .ctrl_bits (ctrl_bits),
    .count3    (count3),
    .ctrl_sig  (c),
    .end_op    (end_op)
  );

  // clock gen: 10 ns period
  initial clk = 0;
    always #5 clk = ~clk;
  // Instrumentation: print intermediate values each clock
  integer cycle;
  integer timeout;
  initial begin 
    cycle = 0;
    $monitor(
      "cycle=%0d | c=%b | ctrl_bits=%b | count3=%b | outbus=%h\nA=%d | Q=%d | Qm1=%b |  ldA=%b | sumA=%d | addM=%d | nextA=%d ",
    cycle,
      c, ctrl_bits, count3, outbus, A_out, Q_out, Qm1_out, debug_ldA_tb, debug_sumA_tb, debug_addM_tb, debug_nextA_tb
    );
  end

  always @(posedge clk) begin
    cycle = cycle + 1;
  end

  initial begin
    // 1) reset
    rst_b  = 0;
    start  = 0;
    inbus  = 0;
    #20;       // hold reset for two cycles
    rst_b  = 1;
    #10;

    // drive M, pulse begin_op exactly on a rising‐edge
    inbus = 8'sd7;
    @(posedge clk);      // wait for a clean edge
    start = 1;
    @(posedge clk);      // hold start through this rising edge
    start = 0;

    // drive Q on the next edge
    inbus = 8'sd3;
    @(posedge clk);      // Q load edge

    // 3) wait for end_op (c8) from the CU, but time out after 50 cycles
    timeout = 0;
    while (!end_op && timeout < 50) begin
      @(posedge clk);
      timeout = timeout + 1;
    end
    if (!end_op) begin
      $error("TIMEOUT: end_op not asserted after %0d cycles", timeout);
      $finish;
    end
    #10;

    // 4) check result
    $display("DUT produced %0d, expected %0d", outbus, 7*3);
    if (outbus !== 7*3)
      $error("❌ TEST FAILED: 7×3 ≠ %0d", outbus);
    else
      $display ("✅ TEST PASSED");

    $finish;
  end

endmodule


/*
module fac (
    input  a,
    input  b,
    input  carry_in,
    output carry_out,
    output sum
);

    assign sum = a ^ b ^ carry_in;
    assign carry_out = (a & b) | (a & carry_in) | (b & carry_in);

endmodule


module adder #(
    parameter WIDTH = 9
) (
    input enable,
    input [WIDTH-1 : 0] a,
    input [WIDTH-1 : 0] b,
    input carry_in,  // 0 addition, 1 substraction
    output [WIDTH-1 : 0] sum
);

    wire [WIDTH - 1 : 0] carry;
    assign carry[0] = carry_in;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : vect
            fac fac_inst (
                .a(a[i]),
                .b(b[i]),
                .carry_in(carry[i]),
                .sum(sum[i]),
                .carry_out(carry[i+1])
            );
        end
    endgenerate

endmodule
*/


/*
module single_right_shifter #(
    parameter WIDTH = 9
) (
    input  wire               clk,
    input  wire               rst_b,
    input  wire               enable,
    input  wire               load,
    input  wire [WIDTH-1:0]   in,
    output reg  [WIDTH-1:0]   out
);
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (load) out <= in;
        else if (enable) out <= {out[WIDTH-1], out[WIDTH-1:1]};
    end
endmodule


module double_right_shifter #(
    parameter WIDTH = 18
) (
    input  wire               clk,
    input  wire               rst_b,
    input  wire               enable,
    input  wire               load,
    input  wire [WIDTH-1:0]   in,
    output reg  [WIDTH-1:0]   out
);
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (load) out <= in;
        else if (enable) out <= {out[WIDTH-1], out[WIDTH-1], out[WIDTH-1:2]};
    end
endmodule


module xor_gate #(
    parameter WIDTH = 9
) (
    input  wire               enable,
    input  wire [WIDTH-1:0]   in,
    output wire [WIDTH-1:0]   out
);
    assign out = enable ? ~in : in;
endmodule
*/