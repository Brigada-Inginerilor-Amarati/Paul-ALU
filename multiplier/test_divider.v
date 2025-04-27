// begin
// c[0] -> init A = 0, Q_star = 0, cnt1 = 0, cnt2 = 0, Q = inbus
// c[1] -> M = inbus
// c[2] -> shifting ALL k pos to the left, k - no of leading zeros in M, cnt1++
// c[3] -> A[8:6] = 0, shifting 1 pos to the left, Q_star[0] = 0, Q[0] = 0
// c[4] * c[3] -> A[8:6] = 1, -||-, Q_star[0] = 0, Q[0] = 1
// c[5] * c[3] -> A[8:6] = -1, -||-, Q_star[0] = 1, Q[0] = 0
// c[6] -> A+M
// c[6] * c[7] -> A-M
// no c[6] -> verificare cnt2 == 7
// cnt2 nu e 7 -> verif primii 3 biti again
// cnt2 == 7 -> verificare a[8] == 1
// a[8] -> c[6] * c[9] -> a + m, q_star + 1 (correction step)
// else c[6] * c[7] * c[10] -> q = q - q_star
// cnt1 == 0 -> c[12] -> out Q
// c[13] -> out A
// end

module adder #(
    parameter WIDTH = 9
) (
    input wire [WIDTH-1:0] a,
    input  wire             enable,
    input  wire [WIDTH-1:0] b,
    input  wire             carry_in,
    output wire [WIDTH - 1 : 0] result
);
    assign result = enable ? (a + b + carry_in) : a;

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

module incrementer #(
    parameter WIDTH = 2
) (
    input  wire             clk,
    input  wire             rst_b,
    input  wire             enable,
    output reg  [WIDTH-1:0] var
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) var <= {WIDTH{1'b0}};
        else if (enable) var <= var + 1'b1;
    end

endmodule

module decrementer #(
    parameter WIDTH = 2
) (
    input  wire             clk,
    input  wire             rst_b,
    input  wire             enable,
    output reg  [WIDTH-1:0] var
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) var <= {WIDTH{1'b0}};
        else if (enable) var <= var - 1'b1;
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

module single_left_shifter #(
    parameter WIDTH = 17
) (
    input wire clk,
    input wire rst_b,
    input wire enable,
    input wire load,
    input wire [WIDTH - 1 : 0] in,
    output reg [WIDTH - 1 : 0] out
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= {out[WIDTH - 2 : 0], 1'b0};
        else if (load) out <= in;
    end

endmodule

module parametrized_left_shifter #(
    parameter WIDTH = 17
) (
    input wire clk,
    input wire rst_b,
    input wire enable,
    input wire load,
    input wire [3 : 0] shift_pos,
    input wire [WIDTH - 1 : 0] in,
    output reg [WIDTH - 1 : 0] out
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (enable) out <= in << shift_pos;
        else if (load) out <= in;
    end

endmodule

module parametrized_right_shifter #(
    parameter WIDTH = 17
) (
    input wire clk,
    input wire rst_b,
    input wire enable,
    input wire load,
    input wire [3 : 0] shift_pos,
    input wire [WIDTH - 1 : 0] in,
    output reg [WIDTH - 1 : 0] out
);

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) out <= {WIDTH{1'b0}};
        else if (load) out <= in;
        else if (enable) out <= in >> shift_pos;
    end

endmodule

module shift_slicer(
    input wire enable,
    input wire [24 : 0] full_slice,
    output wire [8 : 0] a_slice,
    output wire [7 : 0] b_slice,
    output wire [7 : 0] c_slice
);

assign a_slice = enable ? full_slice[24 : 16] : a_slice;
assign b_slice = enable ? full_slice[15 : 8] : b_slice;
assign c_slice = enable ? full_slice[7 : 0] : c_slice;

endmodule

module select_term (
  input  wire c6,
  input  wire c7,
  input  wire signed [8:0] pre_M0,
  input  wire signed [8:0] pre_M1,
  output reg  signed [8:0] M
);

  always @* begin
    case ({c6,c7})
      2'b10: M = pre_M0;
      2'b11: M = pre_M1;
    endcase
  end
endmodule

module counter_check(
    input wire [2:0] cnt,
    output wire cnt2
);

    assign cnt2 = cnt[2] & cnt[1] & cnt[0];

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

module count_leading_zeros #(
  parameter WIDTH = 8
)(
    input enable,
    input [WIDTH - 1 : 0] in,
    output reg [3 : 0] out
);

    integer i;
    reg found;
    always @(*) begin
        out = 0;

        if (enable) begin
            for (i = WIDTH - 1; i >= 0; i = i - 1) begin
                if (!found && in[i]) begin
                    out = WIDTH - 1 - i;
                    found = 1;
                end
            end
        end
    end

endmodule

module srt2_divider(
    input wire clk,
    input wire rst_b,
    input wire signed [7 : 0] inbus,
    input wire [13 : 0]c,
    output reg cnt1,
    output wire [2 : 0] cnt2,
    output wire signed [7 : 0] outbus
);

//-------------------------------
// VARIABLES
//-------------------------------
wire [8 : 0] A;
wire [7 : 0] Q, Q_star, M;
wire counter1;
wire [2 : 0] counter2;
wire [8 : 0] M_selected;
wire [8 : 0] M_0;
wire [8 : 0] M_1;
wire [3 : 0] lz;
wire [24 : 0] shift_out;
wire [2 : 0] ctrl_bits;
wire [7 : 0] Q_shifted;
wire Q0_ctrl;
wire [7 : 0] Q_new;
wire [7 : 0] Q_star_shifted;
wire Q0_star_ctrl;
wire [7 : 0] Q_star_new;
wire [8 : 0] A_out;
wire [7 : 0] Q_star_neg;
wire [7 : 0] Q_final;

//-------------------------------
// LOAD1 & LOAD2
//-------------------------------
register #(9) inbus_rgst_A(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[0]),
    .in(9'b0),
    .out(A)
);

register #(8) inbus_rgst_Q(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[0]),
    .in(inbus),
    .out(Q)
);

register #(8) inbus_rgst_Q_star(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[0]),
    .in(8'b0),
    .out(Q_star)
);

assign counter1 = 0;
register #(3) inbus_rgst_CNT2(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[0]),
    .in(cnt2),
    .out(counter2)
);

register #(8) inbus_rgst_M(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[1]),
    .in(inbus),
    .out(M)
);

//-------------------------------
// CHECK_LEADING_ZEROS & SHIFT_LEFT & SLICEING_BACK
//-------------------------------
count_leading_zeros #(8) count_lz (
    .enable(c[1]),
    .in(M[7 : 0]),
    .out(lz)
);

parametrized_left_shifter #(25) left_shift_lz (
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

//-------------------------------
// PRECOMPUTING_M & INCREMENTING_CNT1
//-------------------------------
register #(9) inbus_rgst_M0(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[1]),
    .in({M[7], M}),
    .out(M_0)
);

xor_gate #(9) xor_gate_M1 (
    .enable(c[1]),
    .in(M_0),
    .out(M_1)
);

register #(1) inbus_rgst_CNT1(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[2]),
    .in(cnt1),
    .out(counter1)
);

counter #(1) increment_cnt1 (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[2]),
    .cnt(counter1)
);

//-------------------------------
// COMPUTING_RESULT
//-------------------------------
assign ctrl_bits = A[8 : 6];

select_term select_M(
  .c6(c[6]),
  .c7(c[7]),
  .pre_M0(M_0),
  .pre_M1(M_1),
  .M(M_selected)
);

adder #(9) adder_A_M(
    .a(A),
    .enable(c[6]),
    .b(M_selected),
    .carry_in(),
    .result(A_out)
);

//-------------------------------
// COMPUTING_Q & Q_STAR & INCREMENT
//-------------------------------
assign Q_shifted = {Q[6 : 0], 1'b0};
assign Q0_ctrl = (c[3] & c[4]) ? 1'b1 : 1'b0;
assign Q_new = {Q_shifted[7 : 1], Q0_ctrl};

assign Q_star_shifted = {Q[6 : 0], 1'b0};
assign Q0_star_ctrl = (c[3] & c[5]) ? 1'b1 : 1'b0;
assign Q_star_new = {Q_star_shifted[7 : 1], Q0_star_ctrl};

register #(8) reg_Q_shifted (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[3]),
    .in(Q_new),
    .out(Q)
);

register #(8) reg_Q_star_shifted (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[3]),
    .in(Q_star_new),
    .out(Q_star)
);

xor_gate #(8) xor_gate_Qstar (
    .enable(c[1]),
    .in(Q_star),
    .out(Q_star_neg)
);

adder #(8) adder_Q_Qstar (
    .a(Q),
    .enable(c[6] & c[7] & c[10]),
    .b(Q_star_neg),
    .carry_in(),
    .result(Q_final)
);

register #(8) reg_Q_computed(
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[6] & c[7] & c[10]),
    .in(Q_final),
    .out(Q)
);

counter #(3) increment_cnt2 (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[6]),
    .cnt(counter2)
);

//-------------------------------
// CORRECTION_STEP
//-------------------------------
register #(9) reg_A_correction (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[6] & c[9]),
    .in(A_out),
    .out(A)
);

incrementer #(8) incrementer_Qstar (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[6] & c[9]),
    .var(Q_star)
);

//-------------------------------
// COMPUTE_RESULT & OUTPUT
//-------------------------------
assign A[7 : 0] = A[8 : 1];
assign A[8] = 0;

decrementer #(1) decrementer_cnt1 (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[11]),
    .var(counter1)
);

register #(8) outbus_Q (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[12]),
    .in(Q[7 : 0]),
    .out(outbus[7 : 0])
);

register #(8) outbus_A (
    .clk(clk),
    .rst_b(rst_b),
    .enable(c[13]),
    .in(A[7 : 0]),
    .out(outbus[7 : 0])
);

endmodule

module control_unit (
    input wire clk,
    rst_b,
    begin_op,
    input wire [1:0] op_code,
    input wire [2:0] ctrl_bits,
    input wire count1,
    input wire [2:0] count2,
    input wire m7,
    output reg [13:0] ctrl_sig,
    output reg end_op
);

localparam IDLE                = 5'b00000;
localparam LOAD1               = 5'b00001;
localparam LOAD2               = 5'b00010;
localparam CHECK_LEADING_ZEROS = 5'b00011;
localparam SHIFT_LEFT          = 5'b00100;
localparam CHECK_CTRL_BITS     = 5'b00101;
localparam ADD_TERM            = 5'b00110;
localparam SUBSTRACT_TERM      = 5'b00111;
localparam CHECK_CNT2          = 5'b01000;
localparam COUNT_UP            = 5'b01001;
localparam CHECK_MSB           = 5'b01010;
localparam CORRECTION_STEP     = 5'b01011;
localparam COMPUTE_Q           = 5'b01100;
localparam CHECK_CNT1          = 5'b01101;
localparam RIGHT_SHIFT         = 5'b01110;
localparam OUT1                = 5'b01111;
localparam OUT2                = 5'b10000;

reg [4:0] state, next_state;

always @(*) begin
    ctrl_sig = 14'b0;
    end_op = 0;

    case (state)
        IDLE: begin
            end_op = 0;
            if (begin_op) begin
                next_state = LOAD1;
                ctrl_sig[0] = 1;
            end else begin
                next_state = IDLE;
            end
        end

        LOAD1: begin
            next_state = LOAD2;
            ctrl_sig[1] = 1;
        end

        LOAD2: begin
            next_state = CHECK_LEADING_ZEROS;
            ctrl_sig[1] = 1;
        end

        CHECK_LEADING_ZEROS: begin
            if (m7) begin
                next_state = CHECK_CTRL_BITS;
            end else begin
                next_state = SHIFT_LEFT;
                ctrl_sig[2] = 1;
            end
        end

        SHIFT_LEFT: begin
            next_state = CHECK_CTRL_BITS;
        end

        CHECK_CTRL_BITS: begin
            if ((ctrl_bits[2] == ctrl_bits[1]) && (ctrl_bits[1] == ctrl_bits[0])) begin
                ctrl_sig[3] = 1;

                if ((~ctrl_bits[2] & ctrl_bits[1]) | (~ctrl_bits[2] & ctrl_bits[0])) begin
                    next_state = ADD_TERM;
                    ctrl_sig[4] = 1;
                end else if ((~ctrl_bits[1] & ctrl_bits[2]) | (~ctrl_bits[0] & ctrl_bits[2])) begin
                    next_state = SUBSTRACT_TERM;
                    ctrl_sig[5] = 1;
                end else begin
                    next_state = CHECK_CNT2;
                end
            end else begin
                next_state = CHECK_CNT2;
            end
        end

        ADD_TERM: begin
            next_state = CHECK_CNT2;
            ctrl_sig[6] = 1;
        end

        SUBSTRACT_TERM: begin
            next_state = CHECK_CNT2;
            ctrl_sig[6] = 1;
            ctrl_sig[7] = 1;
        end

        CHECK_CNT2: begin
            if (count2 == 3'd7) begin
                next_state = CHECK_MSB;
            end else begin
                next_state = COUNT_UP;
                ctrl_sig[8] = 1;
            end
        end

        COUNT_UP: begin
            next_state = CHECK_CTRL_BITS;
        end

        CHECK_MSB: begin
            if (ctrl_bits[2]) begin
                next_state = CORRECTION_STEP;
                ctrl_sig[6] = 1;
                ctrl_sig[9] = 1;
            end else begin
                next_state = COMPUTE_Q;
                ctrl_sig[6] = 1;
                ctrl_sig[7] = 1;
                ctrl_sig[10] = 1;
            end
        end

        CORRECTION_STEP: begin
            next_state = COMPUTE_Q;
        end

        COMPUTE_Q: begin
            next_state = CHECK_CNT1;
        end

        CHECK_CNT1: begin
            if (count1) begin
                next_state = OUT1;
                ctrl_sig[12] = 1;
            end else begin
                next_state = RIGHT_SHIFT;
                ctrl_sig[11] = 1;
            end
        end

        RIGHT_SHIFT: begin
            next_state = CHECK_CNT1;
        end

        OUT1: begin
            next_state = OUT2;
            ctrl_sig[13] = 1;
        end

        OUT2: begin
            next_state = IDLE;
            end_op = 1;
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

always @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

endmodule

module srt2_divider_tb;

  // Declaram semnalele testbench
  reg clk;
  reg rst_b;
  reg begin_op;              // Semnal pentru a incepe operatia
  reg signed [7:0] inbus;    // Intrarea pentru divizare
  reg [1:0] op_code;         // Codul operației (nu este folosit, dar poate fi extins)
  wire [13:0] ctrl_sig;      // Semnalele de control
  wire cnt1;
  wire [2:0] cnt2;
  wire signed [7:0] outbus;

  // Instanțiem unitatea de control (control unit)
  control_unit control (
    .clk(clk),
    .rst_b(rst_b),
    .begin_op(begin_op),
    .op_code(op_code),
    .ctrl_sig(ctrl_sig)  // Semnalele de control generate de unitatea de control
  );

  // Instanțiem modulul srt2_divider
  srt2_divider uut (
    .clk(clk),
    .rst_b(rst_b),
    .inbus(inbus),
    .c(ctrl_sig),   // Semnalele de control sunt transmise de control_unit
    .cnt1(cnt1),
    .cnt2(cnt2),
    .outbus(outbus)
  );

  // Generare ceas
  always begin
    #5 clk = ~clk; // Toggle ceasul la fiecare 5 ns
  end

  // Proces de stimulare
  initial begin
    // Inițializăm semnalele
    clk = 0;
    rst_b = 0;
    inbus = 8'b00001000;  // Introducem 8 (binar 00001000)
    begin_op = 0;         // Nu începem încă operația
    op_code = 2'b00;      // Codul operației pentru divizare
    #10;  // Așteptăm 10 ns înainte de a da reset-ul

    // Aplicați reset
    rst_b = 1;
    #10;
    rst_b = 0;  // Dezactivăm reset-ul
    #10;
    rst_b = 1;

    // Aplicați semnalul de început pentru operație
    begin_op = 1; // Semnal de început pentru operația de divizare
    #10;
    begin_op = 0; // Dezactivăm semnalul de început după un ciclu

    // Așteptăm să se finalizeze operația de împărțire
    #100;  // Așteptăm suficient timp pentru ca împărțirea să fie completă

    // Verificăm rezultatele
    $display("Rezultatul împărțirii: outbus = %d, cnt1 = %b, cnt2 = %b", outbus, cnt1, cnt2);

    // Încheiem simularea
    $finish;
  end

  // Monitorizăm ieșirile
  initial begin
    $monitor("Timp: %t, inbus: %b, begin_op: %b, cnt1: %b, cnt2: %b, outbus: %b, ctrl_sig: %b",
              $time, inbus, begin_op, cnt1, cnt2, outbus, ctrl_sig);
  end

endmodule
