// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* TOP LEVEL MODULE */

module multiple_retirement #(
    localparam NRET = 2,
    localparam N = 1, // max number of special inst in a cycle
    localparam ONLY_BRANCH = 1 // at most N branches, if 0 means at most N special inst
)
(
    input logic clk_i,
    input logic rst_ni,

    /* data from the CPU */
    // inputs
    input mure_pkg::scoreboard_entry_t [NRET-1:0]   commit_instr_i,
    input mure_pkg::bp_resolve_t                    resolved_branch_i,
    input mure_pkg::exception_t                     exception_i,
    input logic                                     interrupt_i, // only connected to port 0
    input logic [mure_pkg::PRIV_LEN-1:0]            priv_lvl_i,
    //input logic [mure_pkg::CTX_LEN-1:0]             context_i, // non mandatory
    //input logic [mure_pkg::TIME_LEN-1:0]            time_i, // non mandatory
    //input logic [mure_pkg::CTYPE_LEN-1:0]           ctype_i, // non mandatory
    //input logic [NRET-1:0][mure_pkg::SIJ_LEN-1]     sijump_i // non mandatory

    // outputs
    /* the output of the module goes directly into the trace_encoder module */
    output logic [N-1:0]                            valid_o,
    output logic [N-1:0][mure_pkg::IRETIRE_LEN-1:0] iretire_o,
    output logic [N-1:0]                            ilastsize_o,
    output logic [N-1:0][mure_pkg::ITYPE_LEN-1:0]   itype_o,
    output logic [N-1:0][mure_pkg::CAUSE_LEN-1:0]   cause_o,
    output logic [N-1:0][mure_pkg::XLEN-1:0]        tval_o,
    output logic [N-1:0][mure_pkg::PRIV_LEN-1:0]    priv_o,
    output logic [N-1:0][mure_pkg::XLEN-1:0]        iaddr_o
    //output logic [mure_pkg::CTX_LEN-1:0]            context_o, // non mandatory
    //output logic [mure_pkg::TIME_LEN-1:0]           time_o, // non mandatory
    //output logic [mure_pkg::CTYPE_LEN-1:0]          ctype_o, // non mandatory
    //output logic [mure_pkg::SIJ_LEN-1]              sijump_o // non mandatory
);

// entries for the FIFOs
mure_pkg::uop_entry_s       uop_entry_i[NRET-1:0], uop_entry_o[NRET-1:0];
mure_pkg::uop_entry_s       uop_entry_mux;
mure_pkg::itype_e           itype[NRET];
// FIFOs management
logic                       pop; // signal to pop FIFOs
logic                       empty[NRET]; // signal used to enable counter
logic                       full[NRET];
logic                       push_enable;
logic                       at_least_one_valid;
// mux arbiter management
logic [$clog2(NRET)-1:0]    mux_arb_val;
logic                       clear_mux_arb;
logic                       enable_mux_arb;
// demux arbiter management
logic [$clog2(N)-1:0]       demux_arb_val;
logic                       clear_demux_arb;
logic                       enable_demux_arb;
// itype_detector
logic                       is_taken_d, is_taken_q;
// exception info
logic [mure_pkg::CAUSE_LEN-1:0] cause_d, cause_q;
logic [mure_pkg::XLEN-1:0]      tval_d, tval_q;
// block counter management
logic                           n_blocks_full;
logic                           n_blocks_empty;
logic [$clog2(N):0]             n_blocks_i, n_blocks_o;
logic                           n_blocks_push;
logic                           n_blocks_pop;
// signals to store blocks
logic                                    valid_fsm;
logic [N-1:0][mure_pkg::IRETIRE_LEN-1:0] iretire_q;
logic [N-1:0]                            ilastsize_q;
logic [N-1:0][mure_pkg::ITYPE_LEN-1:0]   itype_q;
logic [N-1:0][mure_pkg::CAUSE_LEN-1:0]   cause_q;
logic [N-1:0][mure_pkg::XLEN-1:0]        tval_q;
logic [N-1:0][mure_pkg::PRIV_LEN-1:0]    priv_q;
logic [N-1:0][mure_pkg::XLEN-1:0]        iaddr_q;

logic [mure_pkg::IRETIRE_LEN-1:0] iretire_d;
logic                             ilastsize_d;
logic [mure_pkg::ITYPE_LEN-1:0]   itype_d;
logic [mure_pkg::CAUSE_LEN-1:0]   cause_d;
logic [mure_pkg::XLEN-1:0]        tval_d;
logic [mure_pkg::PRIV_LEN-1:0]    priv_d;
logic [mure_pkg::XLEN-1:0]        iaddr_d;

// assignments
assign pop = mux_arb_val == NRET-1;
assign push_enable = !full[0] && at_least_one_valid;
assign clear_mux_arb =  mux_arb_val == NRET-1 ||
                        itype[0] == mure_pkg::EXC ||
                        itype[0] == mure_pkg::INT;
assign enable_mux_arb = !empty[0]; // the counter goes on if FIFOs are not empty
assign is_taken_d = resolved_branch_i.is_taken;
assign cause_d = exception_i.cause;
assign tval_d = exception_i.tval;
assign n_blocks_push = !n_blocks_full;
assign clear_demux_arb = demux_arb_val == n_blocks_o;
assign enable_demux_arb = valid_fsm;

/* itype_detectors */
for (genvar i = 0; i < NRET; i++) begin
    itype_detector i_itype_detector (
        .valid_i       (commit_instr_i[i].valid),
        .exception_i   (exception_i.valid),
        .interrupt_i   (interrupt_i),
        .op_i          (commit_instr_i[i].op),
        .branch_taken_i(is_taken_q),
        .itype_o       (itype[i])
    );
end

/* FIFOs */
/* commit ports FIFOs */
for (genvar i = 0; i < NRET; i++) begin
    fifo_v3 #(
        .DEPTH(16),
        .dtype(mure_pkg::uop_entry_s)
    ) i_fifo_uop (
        .clk_i     (clk_i),
        .rst_ni    (rst_ni),
        .flush_i   ('0),
        .testmode_i('0),
        .full_o    (full[i]),
        .empty_o   (empty[i]),
        .usage_o   (),
        .data_i    (uop_entry_i[i]),
        .push_i    (push_enable),
        .data_o    (uop_entry_o[i]),
        .pop_i     (pop)
    );
end

// FIFO to store the n_blocks
fifo_v3 #(
    .DEPTH(16),
    .DATA_WIDTH($clog2(N))
) i_nblock_fifo (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .flush_i   ('0),
    .testmode_i('0),
    .full_o    (n_blocks_full),
    .empty_o   (n_blocks_empty),
    .usage_o   (),
    .data_i    (n_blocks_i),
    .push_i    (n_blocks_push),
    .data_o    (n_blocks_o),
    .pop_i     (n_blocks_pop)
);

// mux arbiter for serialization
counter #(
    .WIDTH($clog2(NRET)),
    .STICKY_OVERFLOW('0)
) i_mux_arbiter ( // change name?
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .clear_i   (clear_mux_arb),
    .en_i      (enable_mux_arb),
    .load_i    ('0),
    .down_i    ('0),
    .d_i       ('0),
    .q_o       (mux_arb_val),
    .overflow_o()
);

// fsm to create blocks instantiation
fsm i_fsm (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .uop_entry_i(uop_entry_mux),
    .cause_i    (cause_q),
    .tval_i     (tval_q),
    .valid_o    (valid_fsm),
    .iretire_o  (iretire_d),
    .ilastsize_o(ilastsize_d),
    .itype_o    (itype_d),
    .cause_o    (cause_d),
    .tval_o     (tval_d),
    .priv_o     (priv_d),
    .iaddr_o    (iaddr_d)
);

// demux arbiter to choose register
counter #(
    .WIDTH($clog2(N)),
    .STICKY_OVERFLOW('0)
) i_demux_arbiter (
    .clk_i     (clk_i),
    .rst_ni    (rst_ni),
    .clear_i   (clear_demux_arb),
    .en_i      (enable_demux_arb),
    .load_i    ('0),
    .down_i    ('0),
    .d_i       ('0),
    .q_o       (demux_arb_val),
    .overflow_o()
);

always_comb begin
    // init
    n_blocks_i = '0;
    n_blocks_pop = '0;

    // checking if at least one input is valid
    at_least_one_valid = 0;
    foreach(commit_instr_i[i]) begin
        if (commit_instr_i[i].valid) begin
            at_least_one_valid = 1;
            break;
        end
    end

    // populating uop FIFO entries
    for (int i = 0; i < NRET; i++) begin
        uop_entry_i[i].valid = commit_instr_i.valid;
        uop_entry_i[i].pc = commit_instr_i.pc;
        uop_entry_i[i].itype = itype[i];
        uop_entry_i[i].compressed = commit_instr_i.is_compressed;
        uop_entry_i[i].priv = priv_i;
    end
    
    // assigning mux output
    uop_entry_mux = uop_entry_o[mux_arb_val];

    // counting the blocks to emit in one cycle
    for (int i = 0; i < NRET; i++) begin
        if ((uop_entry_o[i].itype > 0 && uop_entry_o[i].valid) || 
            uop_entry_o[i].itype == 2) begin
            n_blocks_i += 1;
        end
    end

    // checking if all blocks are stored
    if (demux_arb_val == n_blocks_o && !n_blocks_empty) begin
        // setting outputs
        for (int i = 0; i < n_blocks_o) begin
            valid_o[i] = '1;
            iretire_o[i] = iretire_q[i];
            ilastsize_o[i] = ilastsize_q[i];
            itype_o[i] = itype_q[i];
            cause_o[i] = cause_q[i];
            tval_o[i] = tval_q[i];
            priv_o[i] = priv_q[i];
            iaddr_o[i] = iaddr_q[i];
        end
        // popping the nblocks FIFO
        n_blocks_pop = '1;
    end
end

always_ff @( posedge clk_i, negedge rst_ni ) begin
    if (!rst_ni) begin
        is_taken_q <= '0;
        cause_q <= '0;
        tval_q <= '0;
        for (int i = 0; i < N; i++) begin
            iretire_q[i] <= '0;
            ilastsize_q[i] <= '0;
            itype_q[i] <= '0;
            cause_q[i] <= '0;
            tval_q[i] <= '0;
            priv_q[i] <= '0;
            iaddr_q[i] <= '0;
        end
    end else begin
        if (resolved_branch_i.valid) begin
            is_taken_q <= is_taken_d;
        end
        if (exception_i.valid) begin
            cause_q <= cause_d;
            tval_q <= tval_d;
        end
        if (valid_fsm) begin
            iretire_q[demux_arb_val] <= iretire_d;
            ilastsize_q[demux_arb_val] <= ilastsize_d;
            itype_q[demux_arb_val] <= itype_d;
            cause_q[demux_arb_val] <= cause_d;
            tval_q[demux_arb_val] <= tval_d;
            priv_q[demux_arb_val] <= priv_d;
            iaddr_q[demux_arb_val] <= iaddr_d;
        end
    end


end

endmodule