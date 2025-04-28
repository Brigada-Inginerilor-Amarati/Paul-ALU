/*
`include "adder_rca.v"
`include "alu.v"
`include "control_unit.v"
`include "counter.v"
`include "dff.v"
`include "mux.v"
`include "rgst.v"
*/
`timescale 1ns / 1ns

module alu_tb;

    // variables
    reg        clk;
    reg        reset;
    reg        BEGIN;
    reg  [1:0] op_code;
    reg  [7:0] inbus;
    wire [7:0] outbus;
    wire       END;

    reg  [7:0] opA;  // holds the first operand
    reg  [7:0] expected;  // holds the expected result
    
    wire [16 : 0] act_state_debug;
    wire [16 : 0] next_state_debug;
    wire [7 : 0] A_reg_debug;
    wire [7 : 0] Q_reg_debug;
    wire [7 : 0] M_reg_debug;
    

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
        .M_reg_debug(M_reg_debug)
    );

    // clock generation

    initial begin
        clk = 1'b0;
    end
    always #5 clk = ~clk;

    // reset generation
    initial begin
        reset = 1'b1;
        #10 reset = 1'b0;
    end

    // set timeout
    initial begin
        #100 $stop;
        $display("Timeout reached");
    end

    // monitor values
    initial begin
        $monitor("clk: %b, reset: %b, BEGIN: %b, op_code: %b\n inbus: %b, outbus: %b, END: %b\n act_state: %h, next_state: %h",
                 clk, reset, BEGIN, op_code, inbus, outbus, END, act_state_debug, next_state_debug);
    end

    // testbench

    initial begin
        // Reset already handled...
        $display("Starting ALU Testbench");

        // Addition test
        BEGIN   = 1'b1;
        op_code = 2'b00;
        #10 inbus = 8'd0;
        opA = inbus;
        #10 BEGIN = 1'b0;
        inbus = 8'd0;
        expected = opA + inbus;
        wait (END);
        if (outbus != expected)
            $error("ADD FAIL: %0d + %0d => %0d, exp %0d", opA, inbus, outbus, expected);
        else $display("ADD OK: %0d + %0d = %0d", opA, inbus, outbus);

        /*
        // Multiplication test
        BEGIN   = 1'b1;
        op_code = 2'b10;
        #10 inbus = 8'd7;
        opA = inbus;
        #10 BEGIN = 1'b0;
        #10 inbus = 8'd3;
        expected = opA * inbus;
        wait (END);
        if (outbus !== expected)
            $error("MUL FAIL: %0d * %0d => %0d, exp %0d", opA, inbus, outbus, expected);
        else $display("MUL OK: %0d * %0d = %0d", opA, inbus, outbus);
        */

        $display("All tests done.");
        // $stop;
        // $finish;
    end


endmodule
