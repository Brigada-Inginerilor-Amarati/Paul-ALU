`timescale 1ns / 1ns

module alu_tb;

    // variables
    reg           clk;
    reg           reset;
    reg           BEGIN;
    reg  [   1:0] op_code;
    reg  [   7:0] inbus;
    wire [   7:0] outbus;
    wire          END;

    reg  [  15:0] opA;  // holds the first operand
    reg  [   7:0] expectedResult;  // holds the expected result
    reg  [  15:0] expectedProduct;
    reg  [ 7 : 0] expectedQuotient;
    reg  [ 7 : 0] expectedRemainder;

    wire [16 : 0] act_state_debug;
    wire [16 : 0] next_state_debug;
    wire [ 8 : 0] A_reg_debug;
    wire [ 8 : 0] Q_reg_debug;
    wire [ 8 : 0] M_reg_debug;
    wire [ 8 : 0] Qprim_reg_debug;
    wire [ 2 : 0] SRT2counter_debug;


    alu dut (
        .clk(clk),
        .reset(reset),
        .BEGIN(BEGIN),
        .op_code(op_code),
        .inbus(inbus),
        .outbus(outbus),
        .END(END),
        .act_state_debug(act_state_debug),
        .next_state_debug(next_state_debug),
        .A_reg_debug(A_reg_debug),
        .Q_reg_debug(Q_reg_debug),
        .M_reg_debug(M_reg_debug),
        .Qprim_reg_debug(Qprim_reg_debug),
        .SRT2counter_debug(SRT2counter_debug)
    );

    // clock generation

    initial begin
        clk = 1'b0;

        // #1000 $stop;  // timeout
    end
    always #5 clk = ~clk;

    /*
    // reset generation
    initial begin
        reset = 1'b1;
        #10 reset = 1'b0;
    end
    */

    /*
    // set timeout
    initial begin
        #100 $stop;
        $display("Timeout reached");
    end
    */

    // monitor values
    initial begin
        $monitor(
            "clk: %b, reset: %b, BEGIN: %b, op_code: %b\n inbus: %b, outbus: %b, END: %b\n act_state: %h, next_state: %h",
            clk, reset, BEGIN, op_code, inbus, outbus, END, act_state_debug, next_state_debug);
    end

    // testbench

    initial begin
        // Reset already handled...
        $display("Starting ALU Testbench");

        BEGIN = 1'b0;

        // Addition test
        reset = 1'b1;
        #10;
        BEGIN   = 1'b1;
        op_code = 2'b00;
        reset   = ~reset;
        inbus   = $random & 8'hFF;
        opA     = inbus;
        #10 BEGIN = 1'b0;

        // second random 8-bit operand
        inbus          = $random & 8'hFF;
        expectedResult = opA + inbus;
        wait (END);
        #10;

        // Subtraction test
        reset = 1'b1;
        #10;
        BEGIN   = 1'b1;
        op_code = 2'b01;
        reset   = ~reset;
        inbus   = $random & 8'hFF;
        opA     = inbus;
        #10 BEGIN = 1'b0;

        // second random 8-bit operand
        inbus          = $random & 8'hFF;
        expectedResult = opA - inbus;
        wait (END);
        #10;

        // Multiplication test
        reset = 1'b1;
        #10;
        BEGIN   = 1'b1;
        op_code = 2'b10;
        reset   = ~reset;
        inbus   = $urandom & 8'hFF;
        opA     = inbus;
        #10 BEGIN = 1'b0;

        // second random 8-bit operand
        inbus           = $urandom & 8'hFF;
        expectedProduct = opA * inbus;
        wait (END);
        #10;

        // Division test


        // Division by zero test

        reset = 1'b1;
        #10;
        BEGIN   = 1'b1;
        op_code = 2'b11;
        reset   = ~reset;
        inbus   = $urandom & 8'hFF;
        opA     = inbus;
        #10 BEGIN = 1'b0;

        // second random 8-bit operand
        inbus = $urandom & 8'hFF;
        opA   = (opA << 8) + inbus;
        #10 inbus = 8'h0;
        expectedQuotient  = opA / inbus;
        expectedRemainder = opA - (inbus * expectedQuotient);
        wait (END);
        #10;

        // Random number generation test

        reset = 1'b1;
        #10;
        BEGIN   = 1'b1;
        op_code = 2'b11;
        reset   = ~reset;
        inbus   = $urandom & 8'hFF;
        opA     = inbus;
        #10 BEGIN = 1'b0;

        // second random 8-bit operand
        inbus = $urandom & 8'hFF;
        opA   = (opA << 8) + inbus;
        #10 inbus = $urandom & 8'hFF;
        expectedQuotient  = opA / inbus;
        expectedRemainder = opA - (inbus * expectedQuotient);
        wait (END);
        #10;

        #10 $stop;

        // $display("All tests done.");
        // $finish;
    end


endmodule
