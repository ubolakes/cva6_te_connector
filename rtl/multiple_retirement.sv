// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retirement
(
    input logic clk_i,
    input logic rst_ni,

    /* data from the CPU */
    // inputs
    input logic [mure_pkg::NRET-1:0]                            valid_i,
    input logic [mure_pkg::NRET-1:0][mure_pkg::XLEN-1:0]        pc_i,
    input logic [mure_pkg::NRET-1:0][mure_pkg::INST_LEN-1:0]    inst_data_i,
    input logic [mure_pkg::NRET-1:0]                            compressed_i,
    input logic exception_i,
    input logic interrupt_i,
    input logic eret_i,
    //input logic [mure_pkg::CTX_LEN-1:0]                         context_i, // non mandatory
    //input logic [mure_pkg::TIME_LEN-1:0]                        time_i, // non mandatory
    //input logic [mure_pkg::CTYPE_LEN-1:0]                       ctype_i, // non mandatory
    //input logic [mure_pkg::NRET-1:0][mure_pkg::SIJ_LEN-1]       sijump_i // non mandatory

    // outputs
    /* the output of the module goes directly into the trace_encoder module */
    output logic                                                valid_o,
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
mure_pkg::fifo_entry_s              fifo_entr_i[mure_pkg::NRET-1:0], fifo_entry_o[mure_pkg::NRET-1:0];
// FIFOs management
logic                               pop; // signal to pop FIFOs
logic                               empty[mure_pkg::NRET]; // signal used to enable counter
logic                               full[mure_pkg::NRET];
logic                               push_enable;
// counter management
logic [$clog2(mure_pkg::NRET)-1:0]  cnt_val;
logic                               clear_counter;
logic                               enable_counter;

// assignments
assign pop = cnt_val == mure_pkg::NRET-1;
assign push_enable = |iretire_i && !full[0];
assign clear_counter = cnt_val == mure_pkg::NRET-1;
assign enable_counter = !empty[0]; // the counter goes on if FIFOs are not empty

/* FIFOs */
/* commit ports FIFOs */
for (genvar i = 0; i < mure_pkg::NRET; i++) begin
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
        .data_i(fifo_entry_i[i]),
        .push_i(push_enable),
        .data_o(fifo_entry_o[i]),
        .pop_i(pop)
    );
end

// counter instantation - from common_cells
counter #(
    .WIDTH($clog2(mure_pkg::NRET)),
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
    // populating uop FIFO entry
    for (int i = 0; i < mure_pkg::NRET; i++) begin
        fifo_entry_i[i].valid = valid_i;
        fifo_entry_i[i].pc = pc_i;
        fifo_entry_i[i].inst_data = inst_data_i;
        fifo_entry_i[i].itype = '0; // init, defined in itype_detector
        fifo_entry_i[i].compressed = compressed_i;
        fifo_entry_i[i].exception = exception_i;
        fifo_entry_i[i].interrupt = interrupt_i;
        fifo_entry_i[i].eret = eret_i;
        fifo_entry_i[i].cause = cause_i;
        fifo_entry_i[i].tval = tval_i;
        fifo_entry_i[i].priv = priv_i;
    end
end

endmodule