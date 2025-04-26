module counter #(
    parameter WIDTH = 3
) (
    input  wire             clk,
    input  wire             reset,
    input  wire             count_up,
    input  wire             count_down,
    output reg  [WIDTH-1:0] cnt
);

    always @(posedge clk or posedge reset) begin
        if (reset) cnt <= {WIDTH{1'b0}};
        else if (count_up) cnt <= cnt + 1'b1;
        else if (count_down) cnt <= cnt - 1'b1;
    end

endmodule
