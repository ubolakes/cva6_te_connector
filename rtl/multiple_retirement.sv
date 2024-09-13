// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retire #(
    parameter int unsigned retired_instr = 2 // placeholder value
)
(
    input logic clk_i,
    input logic rst_ni,

    /* data from the CPU */
    /*
    - number of valid instructions
    - instr opcode
    - if there was an interrupt or exception
    - if there was the return from exception
    - cause of the exception/interrupt
    - associated trap value
    - program counter
    - predicted instruction (?)
    */
    // inputs
    input logic [retired_instr-1:0]         valids_i,
    input logic [retired_instr*mure_pkg::XLEN:0]      uops_i, // instructions opcodes
    input logic                             exception_i,
    input logic                             eret_i,
    input logic [mure_pkg::CAUSE_LEN-1:0]   ucause_i, // user cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   scause_i, // supervisor cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   vscause_i, // virtual supervisor cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   mcause_i, // machine cause
    input logic [mure_pkg::XLEN-1:0]        utval_i, // user tval
    input logic [mure_pkg::XLEN-1:0]        stval_i, // supervisor tval
    input logic [mure_pkg::XLEN-1:0]        vstval_i, // virtual supervisor tval
    input logic [mure_pkg::XLEN-1:0]        mtval_i, // machine tval
    input logic [mure_pkg::PRIV_LEN-1:0]    priv_lvl_i, // priv_lvl_q
    input logic [mure_pkg::XLEN-1:0]        pc_i,
    //input logic /*[]*/                      ptbr_i,

    // outputs
    /* the output of the module goes directly into the trace_encoder module*/
    output logic                            inst_valid_o,
    output logic                            iretired_o, 
    output logic                            exception_o,
    output logic                            interrupt_o, // used to discriminate interrupt
    output logic [mure_pkg::INST_LEN-1:0]   inst_data_o,
    //output logic                            compressed_o, // to discriminate compressed instrs
    output logic [mure_pkg::XLEN-1:0]       pc_o, // instruction address
    output logic [mure_pkg::XLEN-1:0]       epc_o
);


// TODO: make a switch to select the correct cause according to priv_lvl
// TODO: do the same for the TVAL

/* MANAGING PC, CC, NC SIGNALS */
/*
TODO: use a shift register for cleaner code
To manage pc, cc, nc signals I decided to use two 
serially connected FFs.
        ___________                    ___________              
sig0_d--| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q
    nc    |         |    cc              |         |    pc
        |   FF0   |                    |   FF1   |
        |_________|                    |_________|

For input signals I need another FF to sample them:
        ___________                    ___________                    ___________
sig_i --| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q == sig2_d--| D     Q |--sig2_q
input   |         |    nc              |         |    cc              |         |    pc
        |   FF0   |                    |   FF1   |                    |   FF2   |
        |_________|                    |_________|                    |_________|
examples of this are: exception_i

Nonetheless all inputs must be sampled and the output of the FF is considered nc.
*/

/* signals for FFs */
logic [retired_instr-1:0]           valids0_d, valids0_q;
logic [retired_instr-1:0]           valids1_d, valids1_q;
logic [retired_instr-1:0]           valids2_d, valids2_q;
logic [retired_instr*mure_pkg::XLEN:0]  uops0_d, uops0_q;
logic [retired_instr*mure_pkg::XLEN:0]  uops1_d, uops1_q;
logic [retired_instr*mure_pkg::XLEN:0]  uops2_d, uops2_q;
logic                               exception0_d, exception0_q;
logic                               exception1_d, exception1_q;
logic                               exception2_d, exception2_q;
logic                               eret0_d, eret0_q;
logic                               eret1_d, eret1_q;
logic                               eret2_d, eret2_q;
logic [mure_pkg::CAUSE_LEN-1:0]     cause0_d, cause0_q;
logic [mure_pkg::CAUSE_LEN-1:0]     cause1_d, cause1_q;
logic [mure_pkg::CAUSE_LEN-1:0]     cause2_d, cause2_q;
logic [mure_pkg::XLEN-1:0]          tval0_d, tval0_q;
logic [mure_pkg::XLEN-1:0]          tval1_d, tval1_q;
logic [mure_pkg::XLEN-1:0]          tval2_d, tval2_q;
logic [mure_pkg::XLEN-1:0]          pc0_d, pc0_q;
logic [mure_pkg::XLEN-1:0]          pc1_d, pc1_q;
logic [mure_pkg::XLEN-1:0]          pc2_d, pc2_q;




endmodule