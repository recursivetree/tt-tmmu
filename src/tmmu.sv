/*
 * Copyright (c) 2026 Yuri Honegger
 * SPDX-License-Identifier: Apache-2.0
 */

module tmmu #(
    parameter integer PAGE_NUMBER_BITS = 7
) (
    input logic clk_i,
    input logic rst_ni,

    input logic [7:0] vaddr_i,
    output logic [7:0] paddr_o,

    input logic write_en_i,
    output logic ready_o
);
    /* latch memory */
    logic [PAGE_NUMBER_BITS-1:0] memory_q [(2**PAGE_NUMBER_BITS)-1:0];
    
    logic write_now_q, write_next_d;
    logic [PAGE_NUMBER_BITS-1:0] stable_vaddr_q, stable_vaddr_next_d;
    logic [PAGE_NUMBER_BITS-1:0] stable_new_vaddr_q, stable_new_vaddr_next_d;

    logic [PAGE_NUMBER_BITS-1:0] vpage_d;
    logic [8-PAGE_NUMBER_BITS-1:0] voffset_d;

    assign vpage_d = vaddr_i[7:7-PAGE_NUMBER_BITS+1];
    assign voffset_d = vaddr_i[PAGE_NUMBER_BITS-1:0];
    assign paddr_o = {memory_q[vpage_d], voffset_d};

    always_latch begin
        if(write_now_q) begin // TODO: only in first half of cycle
            for (integer i = 0; i < 2**PAGE_NUMBER_BITS; i = i+1) begin
                if(i == stable_vaddr_q) begin
                    memory_q[i] <= stable_new_vaddr_q;
                end
            end
        end
    end

    /* state machine */
    typedef enum logic [1:0] {TRANSLATING, ACQUIRE, WRITE} state_t;
    state_t state_q, state_d;

    always_comb begin
        state_d = state_q;
        ready_o = 0;
        write_next_d = 0;
        stable_vaddr_next_d = stable_vaddr_q;
        stable_new_vaddr_next_d = stable_new_vaddr_q;

        case (state_q)
            TRANSLATING: begin
                state_d = TRANSLATING;
                ready_o = 1;

                if (write_en_i) begin
                    state_d = ACQUIRE;
                    stable_vaddr_next_d = vaddr_i[7:7-PAGE_NUMBER_BITS+1];
                end
            end
            ACQUIRE: begin
                state_d = WRITE;
                write_next_d = 1; // we have to trigger it a cycle before we need to use the value
                stable_new_vaddr_next_d = vaddr_i[7:7-PAGE_NUMBER_BITS+1];
            end
            WRITE: begin
                state_d = TRANSLATING;

                if (write_en_i) begin
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
            write_now_q <= 0;
        end else begin
            state_q <= state_d;
            write_now_q <= write_next_d;
            stable_vaddr_q <= stable_vaddr_next_d;
            stable_new_vaddr_q <= stable_new_vaddr_next_d;
        end
    end

endmodule
