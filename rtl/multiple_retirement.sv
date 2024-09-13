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
    input logic [retired_instr*XLEN:0]      uops_i,
    input logic                             exception_i,
    input logic                             eret_i,
    input logic [mure_pkg::CAUSE_LEN-1:0]   ucause_i, // user cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   scause_i, // supervisor cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   vscause_i, // virtual supervisor cause
    input logic [mure_pkg::CAUSE_LEN-1:0]   mcause_i, // machine cause
    input logic [mure_pkg::XLEN-1:2]        tvec_i, // tvec_q, contains trap handler address
    input logic [mure_pkg::XLEN-1:0]        utval_i, // user tval
    input logic [mure_pkg::XLEN-1:0]        stval_i, // supervisor tval
    input logic [mure_pkg::XLEN-1:0]        vstval_i, // virtual supervisor tval
    input logic [mure_pkg::XLEN-1:0]        mtval_i, // machine tval
    input logic [mure_pkg::PRIV_LEN-1:0]    priv_lvl_i, // priv_lvl_q
    input logic [mure_pkg::XLEN-1:0]        pc_i,
    input logic /*[]*/                      ptbr_i,

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

endmodule