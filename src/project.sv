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
    localparam integer WE_PORT = 0;
    localparam integer READY_PORT = 1;

    wire _unused = &{ena};

    logic write_en_d;
    logic ready_d;

    tmmu tmmu_i (
        .clk_i(clk),
        .rst_ni(rst_n),

        .vaddr_i(ui_in),
        .paddr_o(uo_out),

        .write_en_i(write_en_d),
        .ready_o(ready_d)
    );

    assign write_en_d = uio_in[WE_PORT];

    assign uio_out[WE_PORT] = 0;
    assign uio_out[READY_PORT] = ready_d;
    assign uio_out[2] = 0;
    assign uio_out[3] = 0;
    assign uio_out[4] = 0;
    assign uio_out[5] = 0;
    assign uio_out[6] = 0;
    assign uio_out[7] = 0;

    assign uio_oe[WE_PORT] = 0; // input
    assign uio_oe[READY_PORT] = 1; // output
    assign uio_oe[2] = 0; // input
    assign uio_oe[3] = 0; // input
    assign uio_oe[4] = 0; // input
    assign uio_oe[5] = 0; // input
    assign uio_oe[6] = 0; // input
    assign uio_oe[7] = 0; // input

endmodule
