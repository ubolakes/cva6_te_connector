// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction
*/

module itype_detector_alt
(
    input logic                         commit_instr_valid_i,
    input logic                         commit_ex_valid_i,
    input logic                         interrupt_i,
    input logic                         eret_i,
    input mure_pkg::cf_t                resolved_branch_type_i, // TODO: set correct pkg name or define it
    input logic                         resolved_branch_taken_i,

    output mure_pkg::itype_e            itype_o
);
    
    // internal signals
    logic                       exception;
    logic                       interrupt;
    logic                       eret;
    logic                       nontaken_branch;
    logic                       taken_branch;
    logic                       updiscon;

    // assignments
    assign exception = commit_ex_valid_i;
    assign interrupt = interrupt_i;
    assign eret = eret_i && commit_instr_valid_i;
    assign nontaken_branch = resolved_branch_type_i == mure_pkg::Branch && 
                             !resolved_branch_taken_i &&
                             commit_instr_valid_i;
    assign taken_branch = resolved_branch_type_i == mure_pkg::Branch &&
                          resolved_branch_taken_i &&
                          commit_instr_valid_i;
    assign updiscon = resolved_branch_type_i == mure_pkg::JumpR &&
                      commit_instr_valid_i;
    
    // assigning the itype
    always_comb begin
        // initialization
        itype_o = mure_pkg::STD;

        if (exception) begin // exception
            itype_o = mure_pkg::EXC;
        end else if (interrupt) begin // interrupt
            itype_o = mure_pkg::INT;
        end else if (eret) begin // exception or interrupt return
            itype_o = mure_pkg::ERET;
        end else if (nontaken_branch) begin // nontaken branch
            itype_o = mure_pkg::NTB;
        end else if (taken_branch) begin // taken branch
            itype_o = mure_pkg::TB;
        end else if (mure_pkg::ITYPE_LEN == 3 && updiscon) begin // uninferable discontinuity
            itype_o = mure_pkg::UIJ;
        end
    end

endmodule