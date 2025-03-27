`timescale 1ns / 1ns

module rgst #(
    parameter width = 8
) (
    input wire clk,
    reset,
    input wire load_enable,
    load,
    input wire [width-1:0] data_in,
    input wire left_shift_enable,
    left_shift_value,
    input wire right_shift_enable,
    right_shift_value,
    output wire [width-1:0] data_out
);  // e nevoie de MUX pentru data_in pe registrul A ( iesire adder, inbus )

    wire [1 : 0] selector_mux;  //00-01 for keep/data_in, 10 for right_shift, 11 for left_shift
    assign selector_mux[1] = ~load_enable & (left_shift_enable | right_shift_enable); // enable shift
    assign selector_mux[0] = load_enable | left_shift_enable; // pentru a activa doar pentru load_enable sau left shift

    genvar i;

    generate

        for (i = 0; i < width; i = i + 1) begin

            wire [width - 1 : 0] data_interm;

            if (0 < i && i < width - 1) begin
                mux mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({data_out[i-1], data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else if (i == 0) begin
                mux mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({left_shift_value, data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else begin
                mux mux_inst (  // left, right, sum/inbus, keep // right_shift_value == data_out[i] pentru arithmetic shift
                    .data_in ({data_out[i-1], right_shift_value, data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end

            dff dff_inst (
                .clk(clk),
                .reset(reset),
                .load_enable(load_enable | right_shift_enable | left_shift_enable),
                .data_in(data_interm[i]),
                .data_out(data_out[i])
            );
        end

    endgenerate

    /*
// load
always @ (posedge clk, negedge reset) begin
	if(!reset)
		data_out <= 0;
	else if(load_enable)
		data_out <= data_in;
end

// shift logic
always @ (posedge clk, negedge reset) begin
	if(!reset)
		data_out <= 0;
	else if(left_shift_enable ^ right_shift_enable) begin
		if(left_shift_enable) begin
			data_out <= {data_out[width-2:0], 1'b0};
		end
		else if(right_shift_enable) begin
			if(arithmetic_shift)
				data_out <= {data_out[width-1], data_out[width-1:1]};
			else
				data_out <= {1'b0, data_out[width-1:1]};
		end
	end
end
*/
endmodule



// simple d flip flop
// reset active on low

module dff (
    input  wire clk,
    reset,
    load_enable,
    data_in,
    output reg  data_out
);

    always @(posedge clk, negedge reset) begin
        if (!reset) data_out <= 0;
        else if (load_enable) data_out <= data_in;
    end

endmodule



// 1 bit output MUX

module mux #(
    parameter selection_width = 2
) (
    input wire [( 1 << selection_width ) - 1 : 0] data_in,
    input wire [selection_width - 1 : 0] select,
    output wire data_out
);

    assign data_out = data_in[select];

endmodule


module rgst_tb;

    localparam width = 8;

    reg clk, reset;
    reg load_enable, load;
    reg [width - 1 : 0] data_in;
    reg left_shift_enable, left_shift_value;
    reg right_shift_enable, right_shift_value;
    wire [width-1:0] data_out;

    rgst #(
        .width(width)
    ) dut (
        .clk(clk),
        .reset(reset),
        .load_enable(load_enable),
        .load(load),
        .data_in(data_in),
        .left_shift_enable(left_shift_enable),
        .left_shift_value(left_shift_value),
        .right_shift_enable(right_shift_enable),
        .right_shift_value(right_shift_value),
        .data_out(data_out)
    );

    localparam CLK_PERIOD = 100, RUNNING_CYCLES = 4;
    initial begin
        clk = 0;
        repeat (2 * RUNNING_CYCLES) #(CLK_PERIOD / 2) clk = ~clk;
    end

    localparam RST_DURATION = 25;
    initial begin
        reset = 0;
        #RST_DURATION reset = ~reset;
    end

    // Test stimulus
    initial begin
        // Initialize all inputs
        load_enable        = 0;
        load               = 0;
        data_in            = 8'b0;
        left_shift_enable  = 0;
        left_shift_value   = 0;
        right_shift_enable = 0;
        right_shift_value  = 0;

        // Wait for reset to be deasserted
        @(posedge reset);
        #10;

        // --- Test 1: Parallel Load ---
        // Load the value 8'hA5 into the register.
        $display("Time %t: Parallel Load test; loading 8'hA5", $time);
        load_enable = 1;
        load = 1;
        data_in = 8'hA5;
        #CLK_PERIOD;

        $display("Time %t: Load test", $time);
        $display("Value after load: %b", data_out);

        // Disable load signals
        load_enable = 0;
        load = 0;
        #CLK_PERIOD;

        // --- Test 2: Left Shift ---
        // Enable left shift: the register shifts left by one bit each clock,
        // with left_shift_value inserted into the LSB.
        $display("Time %t: Left Shift test", $time);
        left_shift_enable  = 1;
        left_shift_value   = 0;  // insert 0 at the LSB during left shift
        right_shift_enable = 0;  // ensure right shift is off
        #CLK_PERIOD;  // first left shift cycle
        // #CLK_PERIOD;  // second left shift cycle
        left_shift_enable = 0;  // disable shifting
        #CLK_PERIOD;

        $display("Value after left shift: %b", data_out);

        // --- Test 3: Right Shift ---
        // Enable right shift: the register shifts right by one bit each clock,
        // with right_shift_value inserted into the MSB.
        $display("Time %t: Right Shift test", $time);
        right_shift_enable = 1;
        right_shift_value = 1; // insert 1 at the MSB during right shift (simulating sign extension)
        left_shift_enable = 0;  // ensure left shift is off
        #CLK_PERIOD;  // first right shift cycle
        #CLK_PERIOD;  // second right shift cycle
        right_shift_enable = 0;  // disable shifting
        #CLK_PERIOD;

        $display("Value after right shift: %b", data_out);

        $display("Time %t: End of Simulation", $time);
        $finish;
    end

endmodule
