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
    input wire [16:0] full_slice,
    output wire [8:0] a_slice,
    output wire [7:0] b_slice
);

assign a_slice = enable ? full_slice[16:8] : a_slice;
assign b_slice = enable ? full_slice[7:0] : b_slice;

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
    output wire cnt2,
    output wire signed [7 : 0] outbus1,
    output wire signed [7 : 0] outbus2
);

//-------------------------------
// VARIABLES
//-------------------------------
wire [8 : 0] A;
wire [7 : 0], Q, Q_star, M;
wire counter1;
wire [2 : 0] counter2;
wire [8 : 0] M_selected;

//-------------------------------
// LOAD1 & LOAD2
//-------------------------------


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
