`timescale 1ns / 1ps

module counter_check (
    input  wire [2 : 0] cnt,
    output wire [2 : 0] cnt2
);

    and_gate #(
        .WIDTH(3)
    ) inst_and_gate (
        .enable(1'b1),
        .in(cnt),
        .out(cnt2)
    );

endmodule