`timescale 1ns / 1ps

module xor_gate #(
    parameter WIDTH = 9
) (
    input wire enable,
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    assign out = enable ? in ^ {WIDTH{1'b1}} : {WIDTH{1'b0}};
    
endmodule