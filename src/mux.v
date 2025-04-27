module mux_2_to_1 (
    input wire [1 : 0] data_in,
    input wire select,
    output wire data_out
);

    assign data_out = (select & data_in[1]) | (~select & data_in[0]);

endmodule

// implemented using basic MUX
// speed can be upgraded through single stratum MUX (implementat de la 0)
module mux_4_to_1 (
    input wire [3 : 0] data_in,
    input wire [1 : 0] select,
    output wire data_out
);

    wire [1 : 0] data_interm;

    mux_2_to_1 mux0 (  // select from bits 0 and 1 based on select[0]
        .data_in ({data_in[1], data_in[0]}),
        .select  (select[0]),
        .data_out(data_interm[0])
    );

    mux_2_to_1 mux1 (  // select from bits 2 and 3 based on select[0]
        .data_in ({data_in[3], data_in[2]}),
        .select  (select[0]),
        .data_out(data_interm[1])
    );

    mux_2_to_1 mux_final (  // select from succesful bits based on select[1]
        .data_in ({data_interm[1], data_interm[0]}),
        .select  (select[1]),
        .data_out(data_out)
    );

endmodule
