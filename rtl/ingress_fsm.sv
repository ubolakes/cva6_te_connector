// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FSM */

module ingress_fsm (
    input logic                         clk_i,
    input logic                         rst_ni,

    input logic [NrRetiredInstr-1:0]    ivalids_i,

    input mure_pkg::uop_entry_s         uop_a_i,
    input mure_pkg::uop_entry_s         uop_b_i,
    input mure_pkg::uop_entry_s         uop_c_i,
    input mure_pkg::uop_entry_s         uop_d_i,

    output logic                        valid_o,
    output mure_pkg::uop_entry_s        instLast_o

);

logic single_ret;
logic multiple_ret;
logic all_types_0;
uop_entry_s instLast_d, instLast_q;

assign single_ret = (ivalids_i != 0) && ((ivalids_i & (ivalids_i - 1)) == 0);
assign all_types_0 =    uop_a_i.itype == STD &&
                        uop_b_i.itype == STD &&
                        uop_c_i.itype == STD &&
                        uop_d_i.itype == STD;
assign multiple_ret = $countones(ivalids_i) > 1 && all_types_0;
assign instLast_o = instLast_q;

// states definition
typedef enum logic [2:0] { 
    WAIT_A = 0,
    WAIT_B = 1,
    WAIT_C = 2,
    WAIT_D = 3,
    WAIT   = 4
} state_e;

state_e current_state, next_state;

// combinatorial logic for state transition
always_comb begin
    // next_state default value
    next_state = current_state;

    case (current_state)
    WAIT_A: begin
        if (uop_a_i.itype == EXC || uop_b_i.itype == EXC || uop_c_i.itype == EXC ||
            uop_d_i.itype == EXC || uop_a_i.itype == INT || uop_b_i.itype == INT ||
            uop_c_i.itype == INT || uop_d_i.itype == INT || uop_a_i.itype == ERET ||
            uop_b_i.itype == ERET || uop_c_i.itype == ERET || uop_d_i.itype == ERET) begin
                if (instLast_o == '0) begin
                    // puts A
                    // goto WAIT_A
                end else begin
                    // puts instLast
                    // clear instLast
                    // goto WAIT
                end
            end else if (single_ret) begin // single retirement
                // clear instLast
                // puts A or B or C or D
                // goto WAIT_A
            end else (multiple_ret) begin // multiple retirement
                // puts A or B or C or D
                // update instLast
                // goto WAIT_A
            end else begin 
                if (ivalids_i[NrRetiredInstr-1] == 1) begin
                    // puts A
                    // goto WAIT_B
                end else if (ivalids_i[NrRetiredInstr-2] == 1) begin
                    // puts B
                    // goto WAIT_C
                end else if (ivalids_i[NrRetiredInstr-3] == 1) begin
                    // puts c
                    // goto WAIT_D
                end else begin
                    // goto WAIT_A
                end
            end
    end

    WAIT_B: begin
        if (ivalids_i[NrRetiredInstr-1] == 1 && ivalids_i[NrRetiredInstr-2] == 1 && 
            ivalids_i[NrRetiredInstr-3] == 0 && ivalids_i[NrRetiredInstr-4] == 0) begin
            // puts B
            // goto WAIT_A
            end else if (ivalids_i[NrRetiredInstr-1] == 1 && ivalids_i[NrRetiredInstr-2] == 1 &&
                         ivalids_i[NrRetiredInstr-3] == 1 && 
                         (uop_a_i.itype == UJ || uop_b_i.itype != STD)) begin
                            // puts B
                            // goto WAIT_C
                         end else if (  ivalids_i[NrRetiredInstr-1] == 1 && 
                                        ivalids_i[NrRetiredInstr-2] == 1 && 
                                        ivalids_i[NrRetiredInstr-3] == 1 && 
                                        ivalids_i[NrRetiredInstr-4] == 0) begin
                                            // puts C
                                            // goto WAIT_A
                                        end else if (   ivalids_i[NrRetiredInstr-1] == 1 && 
                                                        ivalids_i[NrRetiredInstr-2] == 1 && 
                                                        ivalids_i[NrRetiredInstr-3] == 1 && 
                                                        ivalids_i[NrRetiredInstr-4] == 1 &&
                                                        uop_c_i.itype != STD) begin
                                                            // puts C
                                                            // goto WAIT_D
                                                        end else begin
                                                            // puts D
                                                            // goto WAIT_A
                                                        end
    end

    WAIT_C: begin
        if (ivalids_i[NrRetiredInstr-2] == 1 && ivalids_i[NrRetiredInstr-3] == 1 &&
            ivalids_i[NrRetiredInstr-4] == 0) begin
                // puts C
                // goto WAIT_A
            end else if (   ivalids_i[NrRetiredInstr-2] == 1 && ivalids_i[NrRetiredInstr-3] == 1 &&
                            ivalids_i[NrRetiredInstr-4] == 1 && 
                            (uop_b_i.itype == UJ || uop_c_i.itype != STD)) begin
                                // puts C
                                // goto WAIT_D
                            end else begin
                                // puts D
                                // goto WAIT_A
                            end
    end

    WAIT_D: begin
        // puts D
        // goto WAIT_A
    end

    WAIT: begin
        // puts A
        // goto WAIT_A
    end

    endcase
end

// sequential logic
always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
        current_state <= WAIT_A;
        instLast_q <= '0;
    end else begin
        current_state <= next_state;
        instLast_q <= instLast_d;
    end
end


endmodule