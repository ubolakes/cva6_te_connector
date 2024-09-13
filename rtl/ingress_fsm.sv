// Author:  Umberto Laghi
// Contact: umberto.laghi@studio.unibo.it
// Github:  @ubolakes

/* FSM */

module ingress_fsm (
    input logic clk_i,
    input logic rst_ni,

);

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


    endcase

end

// sequential logic
always_ff @(posedge clk_i, negedge rst_ni) begin
    if (!rst_ni) begin
        current_state <= WAIT_A;
    end else begin
        current_state <= next_state;
    end
end


endmodule