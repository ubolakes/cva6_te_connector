// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retire #(
    parameter int unsigned NrRetiredInstr = 2 // placeholder value
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
    input logic [NrRetiredInstr-1:0]         valids_i,
    input logic [NrRetiredInstr*mure_pkg::XLEN-1:0]      uops_i, // instructions opcodes
    input logic                             exception_i,
    input logic                             interrupt_i,
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

logic [mure_pkg::CAUSE_LEN-1:0] cause;
logic [mure_pkg::XLEN-1:0]      tval;

// combinatorial network to assign cause and tval according to the priv_lvl
    always_comb begin
        case(priv_lvl_i)
        2'b11: begin
            cause = mcause_i;
            tval = mtval_i;
        end
        2'b10: begin
            cause = vscause_i;
            tval = vstval_i;
        end
        2'b01: begin
            cause = scause_i;
            tval = stval_i;
        end
        2'b00: begin
            cause = ucause_i;
            tval = utval_i;
        end
        endcase
    end

/* MANAGING PC, CC, NC SIGNALS */
/*
TODO: use a shift register for cleaner code
To manage pc, cc, nc signals I decided to use two 
serially connected FFs.
        ___________                    ___________              
sig0_d--| D     Q |--sig0_q == sig1_d--| D     Q |--sig1_q
    nc  |         |    cc              |         |    pc
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
logic [NrRetiredInstr-1:0]           valids0_d, valids0_q;
logic [NrRetiredInstr-1:0]           valids1_d, valids1_q;
logic [NrRetiredInstr-1:0]           valids2_d, valids2_q;
logic [NrRetiredInstr*mure_pkg::XLEN-1:0] uops0_d, uops0_q;
logic [NrRetiredInstr*mure_pkg::XLEN-1:0] uops1_d, uops1_q;
logic [NrRetiredInstr*mure_pkg::XLEN-1:0] uops2_d, uops2_q;
logic                               exception0_d, exception0_q;
logic                               exception1_d, exception1_q;
logic                               exception2_d, exception2_q;
logic                               interrupt0_d, interrupt0_q;
logic                               interrupt1_d, interrupt1_q;
logic                               interrupt2_d, interrupt2_q;
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

/* other signals */
logic [NrRetiredInstr*mure_pkg::ITYPE_LEN-1:0]    itypes;

/* ASSIGNMENT */
/* FFs inputs */
assign valids0_d = valids_i;
assign uops0_d = uops_i;
assign exception0_d = exception_i;
assign interrupt0_d = interrupt_i;
assign eret0_d = eret_i;
assign cause0_d = cause;
assign tval0_d = tval;
assign pc0_d = pc_i;

/* between FFs assigments */
assign valids1_d = valids0_q;
assign valids2_d = valids1_q;
assign uops1_d = uops0_q;
assign uops2_d = uops1_q;
assign exception1_d = exception0_q;
assign exception2_d = exception1_q;
assign interrupt1_d = interrupt0_q;
assign interrupt2_d = interrupt1_q;
assign eret1_d = eret0_q;
assign eret2_d = eret1_q;
assign cause1_d = cause0_q;
assign cause2_d = cause1_q;
assign tval1_d = tval0_q;
assign tval2_d = tval1_q;
assign pc1_d = pc0_q;
assign pc2_d = pc1_q;


// access to chunk in vector:
// [(NrRetiredInstr-i)*CHUNK_LEN-1 : (NrRetiredInstr-i-1)*CHUNK_LEN]

/* itype_detectors */
for (genvar i = 0; i < NrRetiredInstr; i++) begin
    itype_detector i_itype_detector (
        .clk_i          (clk_i),
        .rst_ni         (rst_ni),
        .pc_valid_i     (valids2_q[NrRetiredInstr-i]),
        .cc_valid_i     (valids1_q[NrRetiredInstr-i]),
        .nc_valid_i     (valids0_q[NrRetiredInstr-i]),
        .pc_iaddr_i     (pc2_q[(NrRetiredInstr-i)*mure_pkg::XLEN-1 : (NrRetiredInstr-i-1)*mure_pkg::XLEN]),
        .cc_iaddr_i     (pc1_q[(NrRetiredInstr-i)*mure_pkg::XLEN-1 : (NrRetiredInstr-i-1)*mure_pkg::XLEN]),
        .nc_iaddr_i     (pc0_q[(NrRetiredInstr-i)*mure_pkg::XLEN-1 : (NrRetiredInstr-i-1)*mure_pkg::XLEN]),
        .cc_inst_data_i (uops1_q[(NrRetiredInstr-i)*mure_pkg::INST_LEN-1 : (NrRetiredInstr-i-1)*mure_pkg::INST_LEN]),
        .cc_compressed_i('0),
        .cc_exception_i (exception1_q),
        .cc_interrupt_i (interrupt1_q),
        .cc_eret_i      (eret1_q),
        .itype_o        (itypes[(NrRetiredInstr-i)*mure_pkg::ITYPE_LEN-1 : (NrRetiredInstr-i-1)*mure_pkg::ITYPE_LEN])
    );
end

/* FIFOs */
// TODO: check if it's correct
/* uops FIFOs */
for (genvar i = 0; i < NrRetiredInstr; i++) begin
    fifo_v3 #(
        .DEPTH(16),
        .dtype(mure_pkg::uop_entry_s)
    ) ingressFIFO_uop (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .flush_i('0),
        .testmode_i('0),
        .full_o(),
        .empty_o(),
        .usage_o(),
        .data_i(),
        .push_i(),
        .data_o(),
        .pop_i()
    );
end

/* common FIFO */
fifo_v3 #(
    .DEPTH(16),
    .dtype(mure_pkg::common_entry_s)
) ingressFIFO_cmn (
    .clk_i  (clk_i),
    .rst_ni (rst_ni),
    .flush_i(),
    .testmode_i(),
    .full_o(),
    .empty_o(),
    .usage_o(),
    .data_i(),
    .push_i(),
    .data_o(),
    .pop_i()
);


/* REGISTERS MANAGEMENT */
always_ff @( posedge clk_i, negedge rst_ni ) begin
    if(~rst_ni) begin
        valids0_q <= '0;
        valids1_q <= '0;
        valids2_q <= '0;
        uops0_q <= '0;
        uops1_q <= '0;
        uops2_q <= '0;
        exception0_q <= '0;
        exception1_q <= '0;
        exception2_q <= '0;
        interrupt0_q <= '0;
        interrupt1_q <= '0;
        interrupt2_q <= '0;
        eret0_q <= '0;
        eret1_q <= '0;
        eret2_q <= '0;
        cause0_q <= '0;
        cause1_q <= '0;
        cause2_q <= '0;
        tval0_q <= '0;
        tval1_q <= '0;
        tval2_q <= '0;
        pc0_q <= '0;
        pc1_q <= '0;
        pc2_q <= '0;
    end else begin
        valids0_q <= valids0_d;
        valids1_q <= valids1_d;
        valids2_q <= valids2_d;
        uops0_q <= uops0_d;
        uops1_q <= uops1_d;
        uops2_q <= uops2_d;
        exception0_q <= exception0_d;
        exception1_q <= exception1_d;
        exception2_q <= exception2_d;
        interrupt0_q <= interrupt0_d;
        interrupt1_q <= interrupt1_d;
        interrupt2_q <= interrupt2_d;
        eret0_q <= eret0_d;
        eret1_q <= eret1_d;
        eret2_q <= eret2_d;
        cause0_q <= cause0_d;
        cause1_q <= cause1_d;
        cause2_q <= cause2_d;
        tval0_q <= tval0_d;
        tval1_q <= tval1_d;
        tval2_q <= tval2_d;
        pc0_q <= pc0_d;
        pc1_q <= pc1_d;
        pc2_q <= pc2_d;
    end
end




endmodule