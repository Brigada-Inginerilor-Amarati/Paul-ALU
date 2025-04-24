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
    inout wire [WIDTH-1:0] a,
    input  wire             enable,
    input  wire [WIDTH-1:0] b,
    input  wire             carry_in
);
    wire [WIDTH-1:0] sum = a + b + carry_in;
    assign a = enable ? sum : a;

endmodule


module counter #(
    parameter WIDTH = 2
) (
    input  wire             clk,
    input  wire             rst_b,
    input  wire             enable,
    output reg  [WIDTH-1:0] cnt
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) cnt <= {WIDTH{1'b0}};
        else if (enable) cnt <= cnt + 1'b1;
    end

endmodule


module register #(
    parameter WIDTH = 8
) (
    input wire clk,
    rst_b,
    enable,
    input wire [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= in;
    end

endmodule

module single_right_shifter #(
    parameter WIDTH = 9
) (
    input wire clk,
    rst_b,
    enable,
    load,
    input wire [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= {out[WIDTH-1], out[WIDTH-2:0]};
        else if (load) out <= in;
    end
endmodule


module double_right_shifter #(
    parameter WIDTH = 18
) (
    input wire clk,
    rst_b,
    enable,
    load,
    input wire [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= {out[WIDTH-1], out[WIDTH-1], out[WIDTH-2:0]};
        else if (load) out <= in;
    end
endmodule


module xor_gate #(
    parameter WIDTH = 9
) (
    input wire enable,
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    assign out = enable ? in ^ {WIDTH{1'b1}} : {WIDTH{1'b0}};
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
    input  wire               rst_n,
    input  wire signed [ 7:0] inbus,
    input  wire        [ 8:0] c,
    output wire               count3,       // counter reached end
    output wire        [ 2:0] ctrl_bits,  // {Q[1],Q[0],Qm1}
    output wire signed [15:0] outbus
);

    wire signed [8:0] A = 0, M = 0;
    wire signed [7:0] Q = 0;
    wire Qm1 = 0;
    wire [1:0] cnt = 0;
    wire signed [8:0] precomputed_M [0:3];

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 0) Input bus M
    //––––––––––––––––––––––––––––––––––––––––––––––––
    register #(8) inbus_rgst_M (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[0]),
        .in(inbus),
        .out(Q)
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 1) Input bus Q, precompute M
    //––––––––––––––––––––––––––––––––––––––––––––––––
    register #(8) inbus_rgst_Q (
        .clk(clk),
        .rst_b(rst_b),
        .enable(c[1]),
        .in(inbus),
        .out(Q)
    );

    single_right_shifter #(9) shifterM1 (
        .clk(clk),
        .rst_b(rst_b),
        .load(1'b1),
        .enable(c[1]),
        .in(M),
        .out(precomputed_M[1])
    );

    single_right_shifter #(9) shifterM3 (
        .clk(clk),
        .rst_b(rst_b),
        .load(1'b1),
        .enable(c[1]),
        .in(M),
        .out(precomputed_M[3])
    );

    xor_gate #(9) xor_gateM2 (
        .enable(c[1]),
        .in(M),
        .out(precomputed_M[2])
    );

    xor_gate #(9) xor_gateM3 (
        .enable(c[1]),
        .in(M),
        .out(precomputed_M[3])
    );

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
    // 3) Adder: A = A + M if c2 = 0
    //––––––––––––––––––––––––––––––––––––––––––––––––
    adder #(9) adder_inst (
        .a       (A),
        .b       (additionM),
        .carry_in(c[4]),
        .enable  (c[2])
    );
    
    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 4) Shift–register for {A,Q,Qm1}
    //––––––––––––––––––––––––––––––––––––––––––––––––
    wire [17:0] shift_out;
    double_right_shifter #(18) shifter (
        .clk   (clk),
        .rst_b (rst_b),
        .load  (1'b1),
        .enable(c[5]),
        .in ({A, Q, Qm1}),
        .out(shift_out)
    );

    //––––––––––––––––––––––––––––––––––––––––––––––––
    // 5) Slice “shift_out” into A, Q, Qm1
    //––––––––––––––––––––––––––––––––––––––––––––––––

    shift_slicer slicer(
        .enable(c[5]),
        .full_slice(shift_out),
        .a_slice(A),
        .b_slice(Q),
        .c_slice(Qm1)
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
    input wire [3:0] ctrl_bits,
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
                    next_state  = LOAD1;
                    ctrl_sig[0] = 1;
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
                if (ctrl_bits[2] == ctrl_bits[1] == ctrl_bits[0]) begin
                    next_state  = SHIFT_RIGHT;
                    ctrl_sig[5] = 1;
                end

                ctrl_sig[2] = 1;
                ctrl_sig[3] = (~ctrl_bits[2] & ctrl_bits[1] & ctrl_bits[0]) | (ctrl_bits[2] & ~ctrl_bits[1] & ~ctrl_bits[0]);
                ctrl_sig[4] = (ctrl_bits[2] & ~ctrl_bits[0]) | (ctrl_bits[2] & ~ctrl_bits[1]);

                next_state = ADD_MULTIPLICAND;
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
                if (count3 == 3) begin
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
