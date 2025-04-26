// simple d flip flop
// reset active on low
// priority for reset

module dff (
    input  wire clk,
    reset,
    load_enable,
    data_in,
    output reg  data_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) data_out <= 0;
        else if (load_enable) data_out <= data_in;
    end

endmodule

// d flip flop that resets to 1
// used for the IDLE state flip flop
// basically a jumpstart
// in rest, identical to the original

module dff_rst_to_1 (
    input  wire clk,
    reset,
    load_enable,
    data_in,
    output reg  data_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) data_out <= 1;
        else if (load_enable) data_out <= data_in;
    end

endmodule
