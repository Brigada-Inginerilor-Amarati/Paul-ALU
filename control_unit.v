// ALU Control Unit FSM
// Handles start signals for ADD/SUB, MUL, DIV and FSM states

module control_unit (
    input wire       clk,
    input wire       reset,
    input wire       begin_op,
    input wire [1:0] opcode,         // 00: ADD/SUB, 01: MUL, 10: DIV, 11: SHIFT
    input wire [2:0] ctrl,           // micro-control signals
    input wire       done_addsub,
    input wire       done_mul,
    input wire       done_div,
    input wire       dividend_ready,

    output reg start_addsub,
    output reg start_mul,
    output reg start_div,
    output reg shift_left,
    output reg shift_right,
    output reg end_op
);

    typedef enum logic [2:0] {
        IDLE      = 3'b000,
        LOAD_WAIT = 3'b001,
        START_OP  = 3'b010,
        RUN_OP    = 3'b011,
        FINISH    = 3'b100
    } state_t;

    state_t state, next_state;

    // FSM state update
    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    // Control outputs and FSM next-state logic
    always @(*) begin
        // Default outputs
        start_addsub = 0;
        start_mul = 0;
        start_div = 0;
        shift_left = 0;
        shift_right = 0;
        end_op = 0;
        next_state = state;

        case (state)
            IDLE: begin
                if (begin_op)
                    next_state = (opcode == 2'b10 && !dividend_ready) ? LOAD_WAIT : START_OP;
            end

            LOAD_WAIT: begin
                if (dividend_ready) next_state = START_OP;
            end

            START_OP: begin
                case (opcode)
                    2'b00: start_addsub = 1;
                    2'b01: start_mul = 1;
                    2'b10: start_div = 1;
                    2'b11: begin
                        // SHIFT ops based on ctrl[1:0]
                        if (ctrl[1:0] == 2'b01) shift_left = 1;
                        if (ctrl[1:0] == 2'b10) shift_right = 1;
                    end
                endcase
                next_state = RUN_OP;
            end

            RUN_OP: begin
                case (opcode)
                    2'b00: if (done_addsub) next_state = FINISH;
                    2'b01: if (done_mul) next_state = FINISH;
                    2'b10: if (done_div) next_state = FINISH;
                    2'b11: next_state = FINISH;  // SHIFT is 1 cycle
                endcase
            end

            FINISH: begin
                end_op = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule


/*
module control_unit (
    input wire       clk,
    input wire       reset,
    input wire       begin_op,
    input wire [1:0] opcode,         // 00: ADD/SUB, 01: MUL, 10: DIV, 11: SHIFT
    input wire [2:0] ctrl,           // micro-control signals
    input wire       done_addsub,
    input wire       done_mul,
    input wire       done_div,
    input wire       dividend_ready,

    output reg start_addsub,
    output reg start_mul,
    output reg start_div,
    output reg shift_left,
    output reg shift_right,
    output reg end_op
);

    reg  [2:0] state;  // Current state
    wire [2:0] next_state;  // Next state wires

    wire       S2 = state[2];
    wire       S1 = state[1];
    wire       S0 = state[0];

    // Structural next-state logic
    assign next_state[2] = (S2 & ~S1 & ~S0) |
                           (~S2 &  S1 &  S0 & (
                               (opcode == 2'b00 && done_addsub) ||
                               (opcode == 2'b01 && done_mul)    ||
                               (opcode == 2'b10 && done_div)
                           ));

    assign next_state[1] =
        (~S2 & ~S1 & ~S0 & begin_op & ~(opcode == 2'b10 & ~dividend_ready)) |
        (~S2 &  S1 & ~S0) |
        (~S2 &  S1 &  S0);

    assign next_state[0] =
        (~S2 & ~S1 & ~S0 & begin_op & (opcode == 2'b10 & ~dividend_ready)) |
        (~S2 &  S1 & ~S0) |
        (~S2 &  S1 &  S0 & ~(
            (opcode == 2'b00 && done_addsub) ||
            (opcode == 2'b01 && done_mul)    ||
            (opcode == 2'b10 && done_div)
        ));

    // State register
    always @(posedge clk or posedge reset) begin
        if (reset) state <= 3'b000;
        else state <= next_state;
    end

    // Output control signals
    always @(*) begin
        // Default outputs
        start_addsub = 0;
        start_mul    = 0;
        start_div    = 0;
        shift_left   = 0;
        shift_right  = 0;
        end_op       = 0;

        case (state)
            3'b010: begin  // START_OP
                case (opcode)
                    2'b00: start_addsub = 1;
                    2'b01: start_mul = 1;
                    2'b10: start_div = 1;
                    2'b11: begin
                        if (ctrl[1:0] == 2'b01) shift_left = 1;
                        if (ctrl[1:0] == 2'b10) shift_right = 1;
                    end
                endcase
            end
            3'b100: begin  // FINISH
                end_op = 1;
            end
        endcase
    end

endmodule
*/
