`timescale 1ns / 1ps

module shift_slicer (
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