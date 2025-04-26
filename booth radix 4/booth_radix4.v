module booth_radix4 #(
    parameter W = 8
) (
    input  wire                  clk,
    input  wire                  rst_n,  // active-low reset
    input  wire                  start,  // pulse to begin
    input  wire signed [  W-1:0] M,      // multiplicand
    input  wire signed [  W-1:0] Q_in,   // multiplier
    output reg                   ready,  // goes high when P is valid
    output reg signed  [2*W-1:0] P       // product
);

    parameter IDLE = 2'd0, EXEC = 2'd1, DONE = 2'd2;

    // Internal regs
    reg signed  [  W:0] A;  // W+1 bits for accumulator
    reg signed  [W-1:0] Q;
    reg                 Qm1;
    reg         [  2:0] cnt;  // 4 iterations
    // Precompute multiples
    wire signed [  W:0] M1 = {M[W-1], M};
    wire signed [  W:0] M2 = M1 <<< 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ready <= 1'b0;
            A     <= {W + 1{1'b0}};
            Q     <= {W{1'b0}};
            Qm1   <= 1'b0;
            cnt   <= 3'd0;
            P     <= {2 * W{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        // load inputs
                        A    <= 0;
                        Q    <= Q_in;
                        Qm1  <= 1'b0;
                        cnt  <= (W/2);  // 4 for W=8
                        state<= EXEC;
                    end
                end

                EXEC: begin
                    // --- use blocking to compute new A, then shift ---
                    reg signed [  W:0] sA;
                    reg signed [2*W:0] comb;
                    sA = A;
                    // decode Booth bits
                    case ({
                        Q[1], Q[0], Qm1
                    })
                        3'b001, 3'b010: sA = sA + M1;
                        3'b011:         sA = sA + M2;
                        3'b101, 3'b110: sA = sA - M1;
                        3'b100:         sA = sA - M2;
                        default:        sA = sA;
                    endcase
                    // pack and arithmetic shift right 2
                    comb = $signed({sA, Q, Qm1}) >>> 2;
                    // now register the new values
                    A   <= comb[2*W:2*W-W];  // top W+1 bits
                    Q   <= comb[W:1];  // next W bits
                    Qm1 <= comb[0];  // LSB
                    cnt <= cnt - 1;
                    if (cnt == 1) state <= DONE;
                end

                DONE: begin
                    P     <= {A[W-1:0], Q};
                    ready <= 1'b1;
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end
endmodule
