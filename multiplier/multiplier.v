// ============================================================================
// Structural Radix-4 Booth Multiplier (fixed widths)
// ============================================================================

// ---------------------------------------------------------------------------
// 8-bit synchronous-load register
// ---------------------------------------------------------------------------
module register8 (
    input            clk,
    input            rst_n,
    input            ld,
    input      [7:0] d,
    output reg [7:0] q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) q <= 8'b0;
        else if (ld) q <= d;
    end
endmodule

// ---------------------------------------------------------------------------
// 1-bit synchronous-load register
// ---------------------------------------------------------------------------
module register1 (
    input      clk,
    input      rst_n,
    input      ld,
    input      d,
    output reg q
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) q <= 1'b0;
        else if (ld) q <= d;
    end
endmodule

// ---------------------------------------------------------------------------
// 3-bit down-counter with load and decrement (max init = 4)
// ---------------------------------------------------------------------------
module counter3 (
    input            clk,
    input            rst_n,
    input            ld,
    input            dec,
    input      [2:0] init,   // expect 3'b100 for 4
    output reg [2:0] cnt
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cnt <= 3'b000;
        else if (ld) cnt <= init;
        else if (dec) cnt <= cnt - 1;
    end
endmodule

// ---------------------------------------------------------------------------
// 9-bit adder/subtractor
// ---------------------------------------------------------------------------
module adder9 (
    input  signed [8:0] a,
    input  signed [8:0] b,
    output signed [8:0] sum
);
    assign sum = a + b;
endmodule

// ---------------------------------------------------------------------------
// 17-bit arithmetic right shift by 2
// ---------------------------------------------------------------------------
module shr17 (
    input  signed [16:0] in,
    output signed [16:0] out
);
    assign out = in >>> 2;
endmodule

// ---------------------------------------------------------------------------
// 2-to-1 multiplexer for 9 bits
// ---------------------------------------------------------------------------
module mux2_9 (
    input        sel,
    input  [8:0] d0,
    input  [8:0] d1,
    output [8:0] y
);
    assign y = sel ? d1 : d0;
endmodule

// ============================================================================
// Structural Datapath (no parameters)
// ============================================================================
module booth_radix4_datapath_struct (
    input        clk,
    input        rst_n,
    // control pulses
    input        c0,
    c1,
    c2,
    c3,
    c4,
    c5,
    c7,
    c8,
    // data inputs
    input  [7:0] D_M,
    input  [7:0] D_Q,
    // status output
    output       zero_count,
    // outputs
    output [7:0] OUT_A,
    output [7:0] OUT_Q
);
    // internal regs
    wire [7:0] A_q, Q_q, M_q;
    wire              Qm1_q;
    wire        [2:0] cnt;

    // sign-extended M
    wire signed [8:0] M1 = {M_q[7], M_q};  // 1·M
    wire signed [8:0] M2 = M1 <<< 1;  // 2·M
    // select 1·M or 2·M
    wire signed [8:0] sel1;
    mux2_9 mux_mul (
        .sel(c3),
        .d0 (M1),
        .d1 (M2),
        .y  (sel1)
    );
    // apply negate
    wire signed [8:0] selM = c4 ? -sel1 : sel1;

    // adder/sub
    wire signed [8:0] adder_out;
    adder9 addu (
        .a  ({A_q[7], A_q}),
        .b  (selM),
        .sum(adder_out)
    );

    // shift
    wire signed [16:0] shr_in = {A_q, Q_q, Qm1_q};
    wire signed [16:0] shr_out;
    shr17 s17 (
        .in (shr_in),
        .out(shr_out)
    );

    // next-state values
    wire [7:0] nextA = c0 ? 8'b0 : c2 ? adder_out[7:0] : c5 ? shr_out[16:9] : A_q;
    wire [7:0] nextQ = c0 ? D_Q : c5 ? shr_out[8:1] : Q_q;
    wire       nextQm1 = c0 ? 1'b0 : c5 ? shr_out[0] : Qm1_q;

    // instantiate registers
    register8 regA (
        .clk(clk),
        .rst_n(rst_n),
        .ld(c0 | c2 | c5),
        .d(nextA),
        .q(A_q)
    );
    register8 regQ (
        .clk(clk),
        .rst_n(rst_n),
        .ld(c0 | c5),
        .d(nextQ),
        .q(Q_q)
    );
    register1 regQm1 (
        .clk(clk),
        .rst_n(rst_n),
        .ld(c0 | c5),
        .d(nextQm1),
        .q(Qm1_q)
    );
    register8 regM (
        .clk(clk),
        .rst_n(rst_n),
        .ld(c1),
        .d(D_M),
        .q(M_q)
    );
    counter3 cntR (
        .clk(clk),
        .rst_n(rst_n),
        .ld(c0),
        .dec(c5),
        .init(3'b100),
        .cnt(cnt)
    );

    assign zero_count = (cnt == 3'b000);
    assign OUT_A      = c7 ? A_q : 8'bz;
    assign OUT_Q      = c8 ? Q_q : 8'bz;
endmodule

// ============================================================================
// CU and TB: unchanged (instantiate booth_radix4_datapath_struct in your top)
// ============================================================================


// ---------------------------------------------------------------------------
// Control Unit: generates c0..c8 given start, Q[1:0], Qm1, zero_count
// ---------------------------------------------------------------------------
module booth_radix4_cu #(
    parameter W = 8
) (
    input       clk,
    input       rst_n,
    input       start,
    input [1:0] Q_sel,      // {Q[1], Q[0]}
    input       Qm1,
    input       zero_count,

    output reg c0,
    c1,
    c2,
    c3,
    c4,
    c5,
    c6,
    c7,
    c8,
    output reg done
);
    typedef enum logic [2:0] {
        IDLE   = 3'd0,
        INIT   = 3'd1,
        LOADM  = 3'd2,
        EVAL   = 3'd3,
        SHIFT  = 3'd4,
        OUT    = 3'd5,
        FINISH = 3'd6
    } state_t;

    state_t state, next;

    // state transition
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next;
    end

    // next-state + output logic
    always @* begin
        // defaults
        next = state;
        {c0, c1, c2, c3, c4, c5, c6, c7, c8, done} = 10'b0;

        case (state)
            IDLE: begin
                if (start) next = INIT;
            end

            INIT: begin
                c0   = 1;  // load Q, A=0, count
                c1   = 1;  // load M
                next = EVAL;
            end

            EVAL: begin
                // decode Q_sel/Qm1 -> generate c2,c3,c4
                case ({
                    Q_sel, Qm1
                })
                    3'b001, 3'b010: c2 = 1;  // +M
                    3'b011:         {c3, c2} = 2'b11;  // +2M
                    3'b101, 3'b110: {c4, c2} = 2'b11;  // -M
                    3'b100:         {c4, c3, c2} = 3'b111;  // -2M
                    default:        ;  // 000,111 -> no add
                endcase
                next = SHIFT;
            end

            SHIFT: begin
                c5 = 1;  // shift and dec
                if (zero_count) next = OUT;
                else next = EVAL;
            end

            OUT: begin
                c7   = 1;  // output A
                c8   = 1;  // output Q
                next = FINISH;
            end

            FINISH: begin
                done = 1;
                next = IDLE;
            end

        endcase
    end

endmodule


// ---------------------------------------------------------------------------
// Top-level: instantiates DATAPATH + CU, exposes start/done and full product
// ---------------------------------------------------------------------------
module booth_radix4_multiplier #(
    parameter W = 8
) (
    input            clk,
    input            rst_n,
    input            start,
    input  [  W-1:0] D_M,
    input  [  W-1:0] D_Q,
    output           done,
    output [2*W-1:0] P
);
    // wires
    wire c0, c1, c2, c3, c4, c5, c6, c7, c8;
    wire         zero_cnt;
    wire [W-1:0] bus;
    wire [W-1:0] A_wire, Q_wire;

    // split the shared bus
    assign A_wire = bus;
    // need another bus for Q when c8? actually the datapath overwrites on c7/c8
    wire [W-1:0] OUT_shared = bus;

    // instantiate datapath
    booth_radix4_datapath #(
        .W(W)
    ) DP (
        .clk(clk),
        .rst_n(rst_n),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7),
        .c8(c8),
        .D_M(D_M),
        .D_Q(D_Q),
        .zero_count(zero_cnt),
        .OUTBUS(bus)
    );

    // instantiate CU
    booth_radix4_cu #(
        .W(W)
    ) CU (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .Q_sel({DP.Q[1], DP.Q[0]}),
        .Qm1(DP.Qm1),
        .zero_count(zero_cnt),
        .c0(c0),
        .c1(c1),
        .c2(c2),
        .c3(c3),
        .c4(c4),
        .c5(c5),
        .c6(c6),
        .c7(c7),
        .c8(c8),
        .done(done)
    );

    // combine full product on completion
    assign P = {A_wire, DP.Q};

endmodule


// ---------------------------------------------------------------------------
// Testbench: exercises the multiplier with a basic example
// ---------------------------------------------------------------------------
module tb_booth_radix4;
    reg clk = 0;
    reg rst_n;
    reg start;
    reg [7:0] M, Q;
    wire        done;
    wire [15:0] P;

    // DUT
    booth_radix4_multiplier #(
        .W(8)
    ) DUT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .D_M(M),
        .D_Q(Q),
        .done(done),
        .P(P)
    );

    // clock
    always #5 clk = ~clk;

    initial begin
        // reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // test vector
        M = 8'd7;
        Q = 8'd3;
        start = 1;
        #10;
        start = 0;

        // wait for done
        wait (done);
        $display("Test: M=%0d, Q=%0d => P=%0d", M, Q, $signed(P));
        if ($signed(P) !== $signed(M) * $signed(Q))
            $error("Mismatch: got %0d expected %0d", $signed(P), $signed(M) * $signed(Q));
        else $display("PASS");

        #20 $finish;
    end
endmodule
