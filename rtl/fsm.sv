// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FSM */
/*
it determines the iaddr, ilastsize, iretire
*/

module fsm (
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

/* internal signals */
mure_pkg::state_e current_state, next_state;
logic [mure_pkg::XLEN-1:0]      iaddr_d, iaddr_q;
logic [mure_pkg::XLEN-1:0]      iretire_d, iretire_q;
logic                           ilastsize_d, ilastsize_q;
logic [mure_pkg::ITYPE_LEN-1:0] itype_d, itype_q;
logic [mure_pkg::CAUSE_LEN-1:0] cause_d, cause_q;
logic [mure_pkg::XLEN-1:0]      tval_d, tval_q;
logic [mure_pkg::PRIV_LEN-1:0]  priv_d, priv_q;
logic                           exception;
logic                           special_inst;
logic                           valid_d, valid_q;
logic                           rst_sync_d, rst_sync_q;

/* assignments */
assign exception = fifo_entry_i.itype == 1;
assign special_inst = fifo_entry_i.itype > 1 && fifo_entry_i.valid || exception;
assign iretire_o = iretire_q;
assign ilastsize_o = ilastsize_q;
assign itype_o = itype_q;
assign cause_o = cause_q;
assign tval_o = tval_q;
assign priv_o = priv_q;
assign iaddr_o = iaddr_q;
assign valid_o = valid_q;
assign rst_sync_d = valid_q;

// combinatorial logic for state transition
always_comb begin
    // next_state default value
    next_state = current_state;
    // init
    valid_d = '0;
    iretire_d = '0;
    ilastsize_d = '0;
    itype_d = '0;
    cause_d = '0;
    tval_d = '0;
    priv_d = '0;

    case (current_state)
    mure_pkg::IDLE: begin
        if (fifo_entry_i.itype == 0 && fifo_entry_i.valid) begin // standard instr and valid
            // sets iaddr, increases iretire
            iaddr_d = fifo_entry_i.pc;
            iretire_d = fifo_entry_i.compressed ? iretire_q + 1 : iretire_q + 2;
            // goes to COUNT
            next_state = mure_pkg::COUNT;
        end else if (special_inst) begin // special inst as first inst
            // set all params for output
            iaddr_d = fifo_entry_i.pc;
            iretire_d = fifo_entry_i.compressed ? 1 : 2;
            ilastsize_d = !fifo_entry_i.compressed;
            itype_d = fifo_entry_i.itype;
            cause_d = fifo_entry_i.cause;
            tval_d = fifo_entry_i.tval;
            priv_d = fifo_entry_i.priv;
            // output readable
            valid_d = '1;
            // remains here
            next_state = mure_pkg::IDLE;
        end else begin
            next_state = mure_pkg::IDLE;
        end
    end

    mure_pkg::COUNT: begin
        if (fifo_entry_i.itype == 0 && fifo_entry_i.valid) begin // standard inst
            // increases iretire
            iretire_d = fifo_entry_i.compressed ? iretire_q + 1 : iretire_q + 2;
            // remains here
            next_state = mure_pkg::COUNT;
        end else if (special_inst) begin
            // increases iretire
            iretire_d = fifo_entry_i.compressed ? iretire_q + 1 : iretire_q + 2;
            // sets ilastsize
            ilastsize_d = !fifo_entry_i.compressed;
            // sets all params for output
            itype_d = fifo_entry_i.itype;
            cause_d = fifo_entry_i.cause;
            tval_d = fifo_entry_i.tval;
            priv_d = fifo_entry_i.priv;
            // output readable
            valid_d = '1;
            // goes to IDLE
            next_state = mure_pkg::IDLE;
        end else begin
            next_state = mure_pkg::COUNT;
        end
    end

    endcase
end

// sequential logic
always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
        current_state <= mure_pkg::IDLE;
        iaddr_q <= '0;
        iretire_q <= '0;
        ilastsize_q <= '0;
        itype_q <= '0;
        cause_q <= '0;
        tval_q <= '0;
        priv_q <= '0;
        valid_q <= '0;
        rst_sync_q <= '0;
    end else if (rst_sync_q) begin
        current_state <= next_state;
        iaddr_q <= '0;
        iretire_q <= '0;
        ilastsize_q <= '0;
        itype_q <= '0;
        cause_q <= '0;
        tval_q <= '0;
        priv_q <= '0;
        valid_q <= valid_d;
    end else begin
        current_state <= next_state;
        iaddr_q <= iaddr_d;
        iretire_q <= iretire_d;
        ilastsize_q <= ilastsize_d;
        itype_q <= itype_d;
        cause_q <= cause_d;
        tval_q <= tval_d;
        priv_q <= priv_d;
        valid_q <= valid_d;
        rst_sync_q <= rst_sync_d;
    end
end


endmodule

