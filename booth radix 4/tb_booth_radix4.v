`timescale 1ns / 1ps
module tb_booth_radix4;
    reg clk, rst_n, start;
    reg signed [7:0] M, Q;
    wire               ready;
    wire signed [15:0] P;

    // DUT
    booth_radix4 dut (
        .clk  (clk),
        .rst_n(rst_n),
        .start(start),
        .M    (M),
        .Q_in (Q),
        .ready(ready),
        .P    (P)
    );

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    // test vectors
    reg signed [7:0] Ms[0:4] = '{7, -5, 10, -7, 15};
    reg signed [7:0] Qs[0:4] = '{3, 4, -2, -7, 15};
    integer i;
    initial begin
        rst_n = 0;
        start = 0;
        #20;
        rst_n = 1;
        #10;

        for (i = 0; i < 5; i = i + 1) begin
            M = Ms[i];
            Q = Qs[i];
            // pulse start
            @(posedge clk);
            start = 1;
            @(posedge clk);
            start = 0;
            // wait ready
            wait (ready);
            #1;
            $display("M=%0d, Q=%0d => P=%0d (exp %0d)", M, Q, P, M * Q);
            if (P !== M * Q) $error("  FAIL");
            // wait for ready to clear
            wait (!ready);
            #1;
        end
        $display("ALL DONE");
        $finish;
    end
endmodule
