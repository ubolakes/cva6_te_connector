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
    input logic [mure_pkg::XLEN-1:0]    commit_instr_pc_i,
    input logic                         commit_ex_valid_i,
    input logic                         interrupt_i,
    input logic                         eret_i,
    input pkg::cf_t                     resolved_branch_type_i, // TODO: set correct pkg name or define it
    input logic                         resolved_branch_taken_i,
    input logic [mure_pkg::XLEN-1:0]    resolved_branch_pc_i,

    output mure_pkg::itype_e            itype_o
);
    
    // internal signals
    logic                       exception;
    logic                       interrupt;
    logic                       eret;
    logic                       nontaken_branch;
    logic                       taken_branch;
    logic                       updiscon;
    logic [mure_pkg::XLEN-1:0]  taken_branch_pc_reg;
    logic [mure_pkg::XLEN-1:0]  not_taken_branch_pc_reg;
    logic [mure_pkg::XLEN-1:0]  uninferable_jump_pc_reg;

    // assignments
    assign exception = commit_instr_valid_i && commit_ex_valid_i;
    assign interrupt = interrupt_i;
    assign eret = eret_i;
    assign nontaken_branch = ((not_taken_branch_pc_reg == commit_instr_pc_i) &&
                             ~(commit_instr_pc_i == 0));
    assign taken_branch = ((taken_branch_pc_reg == commit_instr_pc_i) && 
                          ~(commit_instr_pc_i == 0));
    assign updiscon = ((uninferable_jump_pc_reg == commit_instr_pc_i) && 
                      ~(commit_instr_pc_i == 0));
    
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
        end else if (mure_pkg::ITYPE_LEN > 3) begin // reserved
            itype_o = mure_pkg::RES;
        end
    end
    
    // sequential logic
    always_ff @( posedge clk_i ) begin
        if (resolved_branch_type_i == Branch && resolved_branch_taken_i) begin
            taken_branch_pc_reg <= resolved_branch_pc_i; // branch taken
        end 
        else if (resolved_branch_type_i == Branch && !resolved_branch_i.is_taken) begin
            not_taken_branch_pc_reg <= resolved_branch_pc_i; // branch not taken
        end
        else if (resolved_branch_type_i == JumpR) begin
            uninferable_jump_pc_reg <= resolved_branch_pc_i;
        end
    end

endmodule