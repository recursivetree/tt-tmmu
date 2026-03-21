/*
 * Copyright (c) 2026 Yuri Honegger
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

/* verilator lint_off DECLFILENAME */
module tt_um_recursivetree_tmmu_top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    localparam integer WRITE_EN_PORT = 0;
    localparam integer READ_VALID_PORT = 1;
    localparam integer TLB_HIT_PORT = 2;

    wire _unused = &{ena};

    logic read_valid_d;
    logic tlb_hit_d;

    latch_tlb #(
        .NUM_ENTRIES(64)
    ) latch_memory_i (
        .clk_i(clk),
        .rst_ni(rst_n),

        .data_i(ui_in),
        .paddr_o(uo_out),

        .write_en_i(uio_in[WRITE_EN_PORT]),
        .read_valid_o(read_valid_d),
        .tlb_hit_o(tlb_hit_d)
    );

    assign uio_out[WRITE_EN_PORT] = 0;
    assign uio_out[READ_VALID_PORT] = read_valid_d;
    assign uio_out[TLB_HIT_PORT] = tlb_hit_d;
    assign uio_out[3] = 0;
    assign uio_out[4] = 0;
    assign uio_out[5] = 0;
    assign uio_out[6] = 0;
    assign uio_out[7] = 0;

    assign uio_oe[WRITE_EN_PORT] = 0; // input
    assign uio_oe[READ_VALID_PORT] = 1; // output
    assign uio_oe[TLB_HIT_PORT] = 1; // input
    assign uio_oe[3] = 0; // input
    assign uio_oe[4] = 0; // input
    assign uio_oe[5] = 0; // input
    assign uio_oe[6] = 0; // input
    assign uio_oe[7] = 0; // input

endmodule
