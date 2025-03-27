module mux # ( // 4:1 bit MUX
	parameter selection_width = 2
) (
	input wire [1 << selection_width - 1 : 0] data_in,
	input wire [selection_width - 1 : 0] select,
	output wire data_out
);

assign data_out = data_in[select];

endmodule
