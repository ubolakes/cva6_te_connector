// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* ITYPE DETECTOR */
/*
it produces the type of the instruction
*/

module itype_detector
(
    input logic                 exception_i,
    input logic                 interrupt_i,
    input mure_pkg::fu_op       op_i,
    input logic                 branch_taken_i,

    output logic [mure_pkg::ITYPE_LEN]  itype_o
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
        itype_o = '0;

        if (exception) begin // exception
            itype_o = 1;
        end else if (interrupt) begin // interrupt
            itype_o = 2;
        end else if (eret) begin // exception or interrupt return
            itype_o = 3;
        end else if (nontaken_branch) begin // nontaken branch
            itype_o = 4;
        end else if (taken_branch) begin // taken branch
            itype_o = 5;
        end else if (mure_pkg::ITYPE_LEN == 3 && updiscon) begin // uninferable discontinuity
            itype_o = 6;
        end
    end

endmodule