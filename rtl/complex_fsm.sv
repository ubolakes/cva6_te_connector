// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FSM */
/*
it determines the iaddr, ilastsize, iretire for N blocks
and outputs them in the same cycle
*/

module complex_fsm #(
    localparam NRET = 2, // number of inst retired in one cycle
    localparam N = 1 // number of blocks to output in the same cycle
)
(
    input logic                                     clk_i,
    input logic                                     rst_ni,

    input mure_pkg::uop_entry_s [NRET-1:0]          uop_entry_i,
    input logic [NRET-1:0][mure_pkg::CAUSE_LEN-1:0] cause_i,
    input logic [NRET-1:0][mure_pkg::XLEN-1:0]      tval_i,

    output logic                                    valid_o,
    output logic [N-1:0][mure_pkg::IRETIRE_LEN-1:0] iretire_o,
    output logic [N-1:0]                            ilastsize_o,
    output logic [N-1:0][mure_pkg::ITYPE_LEN-1:0]   itype_o,
    output logic [N-1:0][mure_pkg::CAUSE_LEN-1:0]   cause_o,
    output logic [N-1:0][mure_pkg::XLEN-1:0]        tval_o,
    output logic [N-1:0][mure_pkg::PRIV_LEN-1:0]    priv_o,
    output logic [N-1:0][mure_pkg::XLEN-1:0]        iaddr_o
);

// internal signals
logic [$clog2(N)-1:0]       n_port;
logic                       non_zero_found[NRET];
// tells if the last inst of prev cycle was a disc
// determines if I need to save the first pc as iaddr
logic                       lc_last_inst_disc;
logic                       save_iaddr_d, save_iaddr_q;

// combinatorial logic
always_comb begin
    // init
    valid_o = '0;
    n_port = '0;
    lc_last_inst_disc = '0;
    for (int i = 0; i < NRET; i++) begin
        iretire_o[i] = '0;
        ilastsize_o[i] = '0;
        itype_o[i] = '0;
        cause_o[i] = '0;
        tval_o[i] = '0;
        priv_o[i] = '0;
        iaddr_o[i] = '0;
    end
    
    // finding the non zero indices and storing them
    for (int i = 0; i < NRET; i++) begin
        if (uop_entry_i[i].itype != 0) begin
            non_zero_found[i] = 1'b1;
        end else begin
            non_zero_found[i] = '0;
        end
    end

    // creating blocks
    for (int i = 0; i < NRET; i++) begin
        if (non_zero_found[i]) begin // itype != 0
            iretire_o[n_port] += uop_entry_i[i].compressed ? 1 : 2;
            ilastsize_o[n_port] = ~uop_entry_i[i].compressed;
            itype_o[n_port] = uop_entry_i[i].itype;
            cause_o[n_port] = cause_i[i];
            tval_o[n_port] = tval_i[i];
            priv_o[n_port] = uop_entry_i[i].priv;
            
            if (save_iaddr_q || (i > 0 && non_zero_found[i-1])) begin
                iaddr_o[n_port] = uop_entry_i[i].pc;
            end
            // determines when it needs to store iaddr
            if (i == NRET-1) begin
                lc_last_inst_disc = 1;
            end
            
            // switching to next port
            n_port += 1;

        end else begin // itype == 0
            iretire_o[n_port] += uop_entry_i[i].compressed ? 1 : 2;
            if (save_iaddr_q || (i > 0 && non_zero_found[i-1])) begin
                iaddr_o[n_port] = uop_entry_i[i].pc;
            end
        end
    end
    
    // setting output ready to read
    valid_o = '1;
end

always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
        save_iaddr_q <= '0;

    end else begin
        if (lc_last_inst_disc) begin
            save_iaddr_q <= save_iaddr_d;
        end
    end
end

endmodule