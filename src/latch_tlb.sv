/*
 * Copyright (c) 2026 Yuri Honegger
 * SPDX-License-Identifier: Apache-2.0
 */

module latch_tlb #(
    parameter integer NUM_ENTRIES = 128
) (
    input logic clk_i,
    input logic rst_ni,

    input logic [7:0] data_i,
    output logic [7:0] paddr_o,

    input logic [1:0] ancil_data_i,
    output logic [1:0] ancil_data_o,

    input logic write_en_i,
    output logic read_valid_o,
    output logic tlb_hit_o
);
    localparam integer TAG_SIZE = 8 - $clog2(NUM_ENTRIES);
    localparam integer WORD_SIZE = 8 + TAG_SIZE + 2;

    logic [WORD_SIZE-1:0] latch_memory_read_result;

    /* latch memory */
    logic [WORD_SIZE-1:0] memory_q [NUM_ENTRIES-1:0];
    
    logic write_now_q, write_next_d;
    logic [$clog2(NUM_ENTRIES)-1:0] stable_addr_q, stable_addr_next_d;
    logic [WORD_SIZE-1:0] stable_new_data_q, stable_new_data_next_d;

    assign latch_memory_read_result = memory_q[data_i[$clog2(NUM_ENTRIES)-1:0]];

    generate
        for (genvar i = 0; i < NUM_ENTRIES; i = i+1) begin : mem_entry
            logic write_entry_d;
            logic entry_selected;
            assign entry_selected = i == stable_addr_q;

            `ifdef RTLSIM
             assign write_entry_d = write_now_q && entry_selected;
            `else
            sg13g2_and2_2 anti_glitch_and_i (
                .A(write_now_q),
                .B(entry_selected),
                .X(write_entry_d)
            );
            `endif

            always_latch begin
                if(write_entry_d) begin
                    memory_q[i] = stable_new_data_q;
                end
            end
        end
    endgenerate

    assign paddr_o = latch_memory_read_result[7:0];
    assign ancil_data_o = latch_memory_read_result[WORD_SIZE-1:WORD_SIZE-2];
    assign tlb_hit_o = latch_memory_read_result[8+TAG_SIZE-1:8] == data_i[7:$clog2(NUM_ENTRIES)];

    /* state machine */
    typedef enum logic [1:0] {READ, ACQUIRE, WRITE} state_t;
    state_t state_q, state_d;

    always_comb begin
        state_d = state_q;
        read_valid_o = 0;
        write_next_d = 0;
        stable_addr_next_d = stable_addr_q;
        stable_new_data_next_d = stable_new_data_q;

        case (state_q)
            READ: begin
                state_d = READ;
                read_valid_o = 1;

                if (write_en_i) begin
                    state_d = ACQUIRE;
                    stable_addr_next_d = data_i[$clog2(NUM_ENTRIES)-1:0];
                    stable_new_data_next_d[8+TAG_SIZE-1:8] = data_i[7:$clog2(NUM_ENTRIES)];
                end
            end
            ACQUIRE: begin
                state_d = WRITE;
                stable_new_data_next_d[7:0] = data_i;
                stable_new_data_next_d[WORD_SIZE-1:WORD_SIZE-2] = ancil_data_i;
                write_next_d = 1; // we have to trigger it a cycle before we need to use the value
            end
            WRITE: begin
                state_d = READ;
            end
            default: begin
                state_d = READ;
            end
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state_q <= READ;
            write_now_q <= 0;
        end else begin
            state_q <= state_d;
            write_now_q <= write_next_d;
            stable_addr_q <= stable_addr_next_d;
            stable_new_data_q <= stable_new_data_next_d;
        end
    end

endmodule
