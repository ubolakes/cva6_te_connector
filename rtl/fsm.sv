// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FSM */
/*
it determines the iaddr, ilastsize, iretire
*/

module ingress_fsm (
    input logic                                 clk_i,
    input logic                                 rst_ni,

    input mure_pkg::fifo_entry_s                fifo_entry_i,

    output logic                                valid_o,
    output logic [mure_pkg::IRETIRE_LEN-1:0]    iretire_o,
    output logic                                ilastsize_o,
    output logic [mure_pkg::ITYPE_LEN-1:0]      itype_o,
    output logic [mure_pkg::CAUSE_LEN-1:0]      cause_o,
    output logic [mure_pkg::XLEN-1:0]           tval_o,
    output logic [mure_pkg::PRIV_LEN-1:0]       priv_o,
    output logic [mure_pkg::XLEN-1:0]           iaddr_o
);


endmodule

