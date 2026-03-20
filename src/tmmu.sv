/*
 * Copyright (c) 2026 Yuri Honegger
 * SPDX-License-Identifier: Apache-2.0
 */

module tmmu (
    input logic clk_i,
    input logic rst_ni,

    input logic [7:0] vaddr_i,
    output logic [7:0] paddr_o,

    input logic we_i,
    output logic ready_o
);
    typedef enum logic [1:0] {TRANSLATING, ACQUIRE, WRITE} state_t;

    state_t state_q, state_d;

    always_comb begin
        state_d = state_q;
        ready_o = 0;

        case (state_q)
            TRANSLATING: begin
                state_d = TRANSLATING;
                ready_o = 1;

                if (we_i) begin
                    state_d = ACQUIRE;
                end
            end
            ACQUIRE: begin
                state_d = WRITE;
            end
            WRITE: begin
                state_d = TRANSLATING;

                if (we_i) begin
                    state_d = ACQUIRE;
                end
            end
            default: begin
                state_d = TRANSLATING;
                ready_o = 0;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= TRANSLATING;
        end else begin
            state_q <= state_d;
        end
    end

endmodule