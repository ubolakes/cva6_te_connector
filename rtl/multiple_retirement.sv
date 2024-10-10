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
// counter management
logic [$clog2(NRET)-1:0]    cnt_val;
logic                       clear_counter;
logic                       enable_counter;
// itype_detector
logic                       is_taken_d, is_taken_q;
// exception info
logic [mure_pkg::CAUSE_LEN-1:0] cause_d, cause_q;
logic [mure_pkg::XLEN-1:0]      tval_d, tval_q;

// assignments
assign pop = cnt_val == NRET-1;
assign push_enable = !full[0] && at_least_one_valid;
assign clear_counter =  cnt_val == NRET-1 ||
                        itype[0] == mure_pkg::EXC ||
                        itype[0] == mure_pkg::INT;
assign enable_counter = !empty[0]; // the counter goes on if FIFOs are not empty
assign is_taken_d = resolved_branch_i.is_taken;
assign cause_d = exception_i.cause;
assign tval_d = exception_i.tval;

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

// counter instantation - from common_cells
counter #(
    .WIDTH($clog2(NRET)),
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

// fsm instantiation
generate
    if (N == 1) begin
        fsm i_fsm (
            .clk_i      (clk_i),
            .rst_ni     (rst_ni),
            .uop_entry_i(uop_entry_mux),
            .cause_i    (cause_q),
            .tval_i     (tval_q),
            .valid_o    (valid_o),
            .iretire_o  (iretire_o),
            .ilastsize_o(ilastsize_o),
            .itype_o    (itype_o),
            .cause_o    (cause_o),
            .tval_o     (tval_o),
            .priv_o     (priv_o),
            .iaddr_o    (iaddr_o)
        );
    end else begin // more special inst per cycle 
        // TODO: develop more complex FSM
        /*
        this FSM can output up to N packets in the same cycle
        and it's possibile because there might be up to N updiscon
        in the same cycle and they require a specific packet
        */
    end
endgenerate

always_comb begin
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
    uop_entry_mux = uop_entry_o[cnt_val];
end

always_ff @( posedge clk_i, negedge rst_ni ) begin
    if (!rst_ni) begin
        is_taken_q <= '0;
        cause_q <= '0;
        tval_q <= '0;
    end else begin
        if (resolved_branch_i.valid) begin
            is_taken_q <= is_taken_d;
        end
        if (exception_i.valid) begin
            cause_q <= cause_d;
            tval_q <= tval_d;
        end
    end
end

endmodule