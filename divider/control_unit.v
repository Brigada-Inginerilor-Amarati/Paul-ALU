`timescale 1ns / 1ps

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