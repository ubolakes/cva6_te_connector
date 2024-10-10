// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction
*/

module itype_detector
(
    input logic                 valid_i,
    input logic                 exception_i,
    input logic                 interrupt_i,
    input mure_pkg::fu_op       op_i,
    input logic                 branch_taken_i

    output mure_pkg::itype_e    itype_o
);
    
    // internal signals
    logic   exception;
    logic   interrupt;
    logic   eret;
    logic   nontaken_branch;
    logic   taken_branch;
    logic   updiscon;

    // assignments
    assign exception = exception_i;
    assign interrupt = interrupt_i; // no need to have an inst committed
    assign eret = ( op_i == mure_pkg::MRET || 
                    op_i == mure_pkg::SRET ||
                    op_i == mure_pkg::DRET );
    assign nontaken_branch = op_i == mure_pkg::BRANCH && ~branch_taken_i;
    assign taken_branch = op_i == mure_pkg::BRANCH && branch_taken_i;
    assign updiscon = op_i == mure_pkg::JALR;

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