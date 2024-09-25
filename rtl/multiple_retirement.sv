// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retire #(
    parameter int unsigned NrRetiredInstr = 2; // placeholder value, CVA6
)
(
    input logic clk_i,
    input logic rst_ni,

    /* data from the CPU */
    // inputs
    input logic [NrRetiredInstr-1:0]/*[?:?]*/                   iretire_i,
    input logic [NrRetiredInstr-1:0]/*[?:?]*/                   ilastsize_i,
    input logic [NrRetiredInstr-1:0][mure_pkg::ITYPE_LEN-1:0]   itype_i,
    input logic [mure_pkg::CAUSE_LEN-1:0]                       cause_i,
    input logic [mure_pkg::TVAL_LEN-1:0]                        tval_i,
    input logic [mure_pkg::PRIV_LEN-1:0]                        priv_i,
    input logic [NrRetiredInstr-1:0][mure_pkg::XLEN-1:0]        iaddr_i,
    //input logic [mure_pkg::CTX_LEN-1:0]                         context_i, // non mandatory
    //input logic [mure_pkg::TIME_LEN-1:0]                        time_i, // non mandatory
    //input logic [mure_pkg::CTYPE_LEN-1:0]                       ctype_i, // non mandatory
    //input logic [NrRetiredInstr-1:0][mure_pkg::SIJ_LEN-1]       sijump_i // non mandatory

    // outputs
    /* the output of the module goes directly into the trace_encoder module */
    output logic                                                iretire_o,
    output logic                                                ilastsize_o,
    output logic [mure_pkg::ITYPE_LEN-1:0]                      itype_o,
    output logic [mure_pkg::CAUSE_LEN-1:0]                      cause_o,
    output logic [mure_pkg::TVAL_LEN-1:0]                       tval_o,
    output logic [mure_pkg::PRIV_LEN-1:0]                       priv_o,
    output logic [mure_pkg::XLEN-1:0]                           iaddr_o
    //output logic [mure_pkg::CTX_LEN-1:0]                        context_o, // non mandatory
    //output logic [mure_pkg::TIME_LEN-1:0]                       time_o, // non mandatory
    //output logic [mure_pkg::CTYPE_LEN-1:0]                      ctype_o, // non mandatory
    //output logic [mure_pkg::SIJ_LEN-1]                          sijump_o // non mandatory
);

// entries for the FIFOs
uop_entry_s     uop_entry_i[NrRetiredInstr], uop_entry_o;
common_entry_s  common_entry_i, common_entry_o;
// FIFOs management
logic           pop; // signal to pop FIFOs
logic           empty[NrRetiredInstr]; // signal used to enable counter
logic           full[NrRetiredInstr];
logic           push_enable;


// assignments
assign pop = cnt_val == NrRetiredInstr-1;
assign push_enable = ;//TODO: FIFOs not full

// modules instantiation
/* FIFOs */
/* commit ports FIFOs */
for (genvar i = 0; i < NrRetiredInstr; i++) begin
    fifo_v3 #(
        .DEPTH(16),
        .dtype(mure_pkg::uop_entry_s)
    ) ingressFIFO_uop (
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .flush_i('0),
        .testmode_i('0),
        .full_o(full[i]),
        .empty_o(empty[i]),
        .usage_o(),
        .data_i(uop_entry[i]),
        .push_i(),
        .data_o(),
        .pop_i(pop)
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
    .data_i(common_entry),
    .push_i(),
    .data_o(),
    .pop_i()
);

// TODOs:
// counter instantation - from common_cells
// combinatorial logic to manage the MUX

/* REGISTERS MANAGEMENT */
always_ff @( posedge clk_i, negedge rst_ni ) begin
    if(~rst_ni) begin
        
    end else if (push_enable) begin
        // populating uop FIFO
        for (int i = 0; i < NrRetiredInstr; i++) begin
            uop_entry_i[i].itype = itype_i[i];
            uop_entry_i[i].iaddr = iaddr_i[i];
            uop_entry_i[i].iretire = iretire_i[i];
            uop_entry_i[i].ilastsize = ilastsize_i[i];
        end
        // populating common FIFO
        common_entry_i.cause = cause_i;
        common_entry_i.tval = tval_i;
        common_entry_i.priv = priv_i;
        //common_entry_i.context = context_i; // non mandatory
        //common_entry_i.ctype = ctype_i; // non mandatory
        //common_entry_i.time = time_i; // non mandatory
        //common_entry_i.sijump = sijump_i; // non mandatory
    end
end

endmodule