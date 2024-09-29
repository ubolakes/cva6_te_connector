// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retirement #(
    parameter int unsigned NrRetiredInstr = 2 // placeholder value, CVA6
)
(
    input logic clk_i,
    input logic rst_ni,

    /* data from the CPU */
    // inputs
    input logic [NrRetiredInstr-1:0][mure_pkg::IRETIRE_LEN-1:0] iretire_i,
    input logic [NrRetiredInstr-1:0]                            ilastsize_i,
    input logic [NrRetiredInstr-1:0][mure_pkg::ITYPE_LEN-1:0]   itype_i,
    input logic [mure_pkg::CAUSE_LEN-1:0]                       cause_i,
    input logic [mure_pkg::XLEN-1:0]                            tval_i,
    input logic [mure_pkg::PRIV_LEN-1:0]                        priv_i,
    input logic [NrRetiredInstr-1:0][mure_pkg::XLEN-1:0]        iaddr_i,
    //input logic [mure_pkg::CTX_LEN-1:0]                         context_i, // non mandatory
    //input logic [mure_pkg::TIME_LEN-1:0]                        time_i, // non mandatory
    //input logic [mure_pkg::CTYPE_LEN-1:0]                       ctype_i, // non mandatory
    //input logic [NrRetiredInstr-1:0][mure_pkg::SIJ_LEN-1]       sijump_i // non mandatory

    // outputs
    /* the output of the module goes directly into the trace_encoder module */
    output logic [mure_pkg::IRETIRE_LEN-1:0]                    iretire_o,
    output logic                                                ilastsize_o,
    output logic [mure_pkg::ITYPE_LEN-1:0]                      itype_o,
    output logic [mure_pkg::CAUSE_LEN-1:0]                      cause_o,
    output logic [mure_pkg::XLEN-1:0]                           tval_o,
    output logic [mure_pkg::PRIV_LEN-1:0]                       priv_o,
    output logic [mure_pkg::XLEN-1:0]                           iaddr_o
    //output logic [mure_pkg::CTX_LEN-1:0]                        context_o, // non mandatory
    //output logic [mure_pkg::TIME_LEN-1:0]                       time_o, // non mandatory
    //output logic [mure_pkg::CTYPE_LEN-1:0]                      ctype_o, // non mandatory
    //output logic [mure_pkg::SIJ_LEN-1]                          sijump_o // non mandatory
);

// entries for the FIFOs
mure_pkg::uop_entry_s [NrRetiredInstr-1:0]  uop_entry_i, uop_entry_o;
mure_pkg::common_entry_s                    common_entry_i, common_entry_o;
// FIFOs management
logic                               pop; // signal to pop FIFOs
logic                               empty[NrRetiredInstr]; // signal used to enable counter
logic                               full[NrRetiredInstr];
logic                               push_enable;
// counter management
logic [$clog2(NrRetiredInstr)-1:0]  cnt_val;
logic                               clear_counter;
logic                               enable_counter;

// assignments
assign pop = cnt_val == NrRetiredInstr-1;
assign push_enable = |iretire_i && !full[0];
assign clear_counter = cnt_val == NrRetiredInstr-1;
assign enable_counter = !empty[0]; // the counter goes on if FIFOs are not empty

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
        .data_i(uop_entry_i[i]),
        .push_i(push_enable),
        .data_o(uop_entry_o[i]),
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
    .flush_i('0),
    .testmode_i('0),
    .full_o(),
    .empty_o(),
    .usage_o(),
    .data_i(common_entry_i),
    .push_i(push_enable),
    .data_o(common_entry_o),
    .pop_i(pop)
);

// counter instantation - from common_cells
counter #(
    .WIDTH($clog2(NrRetiredInstr)),
    .STICKY_OVERFLOW('0)
) i_mux_arbiter ( // change name?
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .clear_i   (clear_counter),
    .en_i      (enable_counter),
    .load_i    ('0),
    .down_i    ('0),
    .d_i       ('0),
    .q_o       (cnt_val),
    .overflow_o()
);

always_comb begin
    // initialization
    iretire_o = '0;
    ilastsize_o = '0;
    itype_o = '0;
    cause_o = '0;
    tval_o = '0;
    priv_o = '0;
    iaddr_o = '0;

    // populating uop FIFO entry
    for (int i = 0; i < NrRetiredInstr; i++) begin
        uop_entry_i[i].itype = itype_i[i];
        uop_entry_i[i].iaddr = iaddr_i[i];
        uop_entry_i[i].iretire = iretire_i[i];
        uop_entry_i[i].ilastsize = ilastsize_i[i];
    end
    // populating common FIFO entry
    common_entry_i.cause = cause_i;
    common_entry_i.tval = tval_i;
    common_entry_i.priv = priv_i;

    // determinating output
    iretire_o = uop_entry_o[cnt_val].iretire;
    ilastsize_o = uop_entry_o[cnt_val].ilastsize;
    itype_o = uop_entry_o[cnt_val].itype;
    iaddr_o = uop_entry_o[cnt_val].iaddr;
    cause_o = common_entry_o.cause;
    tval_o = common_entry_o.tval;
    priv_o = common_entry_o.priv;
end

endmodule