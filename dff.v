// simple d flip flop
// reset active on low

module dff(
	input wire
	clk, reset,
	load_enable, data_in,
	output reg data_out
);

always @ (posedge clk, negedge reset) begin
	if(!reset)
		data_out <= 0;
	else if(load_enable)
		data_out <= data_in;
end

endmodule
