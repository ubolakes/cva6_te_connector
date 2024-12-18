// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

`timescale 1ns/1ns

import connector_pkg::*;

module tb_itype_detector_alt();

    logic clk;
    logic reset;

    // inputs
    logic               commit_instr_valid_i;
    logic               commit_ex_valid_i;
    logic               interrupt_i;
    logic               eret_i;
    cf_t                resolved_branch_type_i;
    logic               resolved_branch_taken_i;

    // outputs
    itype_e itype_o;

    // testing only outputs
    itype_e expected_itype;

    // iteration variable
    logic [31:0] i;

    // DUT instatiation
    itype_detector_alt DUT(
        .commit_instr_valid_i   (commit_instr_valid_i),
        .commit_ex_valid_i      (commit_ex_valid_i),
        .interrupt_i            (interrupt_i),
        .eret_i                 (eret_i),
        .resolved_branch_type_i (resolved_branch_type_i),
        .resolved_branch_taken_i(resolved_branch_taken_i),
        .itype_o                (itype_o)
    );

    logic [10:0] test_vector[1000:0];

    initial begin
        $readmemb("tv_itype_detector_alt", test_vector);
        i = 0;
        reset = 1;
    end

    always @(posedge clk) begin
        {
            commit_instr_valid_i,
            commit_ex_valid_i,
            interrupt_i,
            eret_i,
            resolved_branch_type_i,
            resolved_branch_taken_i,
            expected_itype
        } = test_vector[i]; #10;
    end

    always @(negedge clk) begin
        // itype_o
        if (expected_itype !== itype_o) begin
            $display("Wrong itype: %b!=%b", expected_itype, itype_o);
        end

        i = i + 1;
    end

    always begin
        clk <= 1; #5;
        clk <= 0; #5;
    end
    
endmodule