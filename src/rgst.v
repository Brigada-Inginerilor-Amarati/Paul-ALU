module rgst #(
    parameter width = 9
) (
    input wire clk,
    reset,
    input wire load_enable,
    input wire [width-1:0] data_in,
    input wire left_shift_enable,
    left_shift_value,
    input wire right_shift_enable,
    right_shift_value,
    input wire jump_LSb, // wire to know if LSb is supposed to be jumped in LSHIFT // in SRT-2 normal LSHIFT
    output wire [width-1:0] data_out
);  // e nevoie de MUX pentru data_in pe registrul A ( iesire adder, inbus )

    wire [1 : 0] selector_mux;  //00-01 for keep/data_in, 10 for right_shift, 11 for left_shift
    assign selector_mux[1] = ~load_enable & (left_shift_enable | right_shift_enable);
    assign selector_mux[0] = load_enable | left_shift_enable;

    genvar i;

    generate
        wire [width - 1 : 0] data_interm;
        for (i = 0; i < width; i = i + 1) begin  

            if (0 < i && i < width - 1) begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({data_out[i-1], data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else if (i == 0) begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep
                    .data_in ({left_shift_value, data_out[i+1], data_in[i], data_out[i]}),
                    .select  (selector_mux),
                    .data_out(data_interm[i])
                );
            end else if (i == 1) begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep
                    .data_in({
                        (left_shift_value & jump_LSb) | (data_out[i-1] & ~jump_LSb),
                        data_out[i+1],
                        data_in[i],
                        data_out[i]
                    }),
                    .select(selector_mux),
                    .data_out(data_interm[i])
                );
            end else begin
                mux_4_to_1 mux_inst (  // left, right, sum/inbus, keep // right_shift_value == data_out[i] pentru arithmetic shift
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

    // problema la testarea right shift era ca RUNNING_CYCLES era prea mic => operatiile de right shift nu mai aveau loc
    localparam CLK_PERIOD = 100, RUNNING_CYCLES = 10;
    initial begin
        clk = 0;
        repeat (RUNNING_CYCLES << 1) #(CLK_PERIOD >> 1) clk = ~clk;
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

        // written to be used in simulation interface, data seen as wave

        // Enable load signals
        data_in = 8'b10110010;
        load_enable = 1;
        load = 1;
        #CLK_PERIOD;

        // Disable load signals
        load_enable = 0;
        load = 0;
        #CLK_PERIOD;

        // --- Test 2: Left Shift ---
        // Enable left shift: the register shifts left by one bit each clock,
        // with left_shift_value inserted into the LSB.
        left_shift_enable  = 1;
        left_shift_value   = 0;  // insert 0 at the LSB during left shift
        right_shift_enable = 0;  // ensure right shift is off
        #CLK_PERIOD;  // first left shift cycle

        left_shift_value = 1;  // insert 1 at the LSB during left shift
        #CLK_PERIOD;  // second left shift cycle

        left_shift_enable = 0;  // disable shifting
        // #CLK_PERIOD; // disabled to stress test module

        // --- Test 3: Right Shift ---
        // Enable right shift: the register shifts right by one bit each clock,
        // with right_shift_value inserted into the MSB.
        right_shift_enable = 1;
        right_shift_value = 1; // insert 1 at the MSB during right shift (simulating sign extension)
        left_shift_enable = 0;  // ensure left shift is off
        #CLK_PERIOD;  // first right shift cycle

        right_shift_value = 0; // insert 0 at the MSB during right shift (simulating sign extension)
        #CLK_PERIOD;  // second right shift cycle
        right_shift_enable = 0;  // disable shifting
        // #CLK_PERIOD;

        // $finish;


    end

endmodule
