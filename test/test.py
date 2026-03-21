# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import random

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    ENTRIES = 64

    # input bit positions
    WRITE_EN_MASK = 1

    # output bit positions
    READ_VALID_BIT = 1
    TLB_HIT = 2

    # test all cells
    for base in range(256 // ENTRIES):
        for offset in range(64):
            addr = base * ENTRIES + offset
            dut.ui_in.value = addr
            dut.uio_in.value = WRITE_EN_MASK
            await ClockCycles(dut.clk, 1)
            dut.ui_in.value = (addr + 7) % 256
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 1)
            dut.ui_in.value = 0
            await ClockCycles(dut.clk, 1)

        for offset in range(64):
            addr = base * ENTRIES + offset
            dut.ui_in.value = addr
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 1)
            assert dut.uio_out.value[READ_VALID_BIT] == 1
            assert dut.uio_out.value[TLB_HIT] == 1
            assert dut.uo_out.value == (addr + 7) % 256

    # test tag checks
    async def test_tag_conflicts(addr):
        # do a write
        dut.ui_in.value = addr
        dut.uio_in.value = WRITE_EN_MASK
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 243  # random choice
        dut.uio_in.value = 0
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)

        # read a tag conflicting value
        for i in range(3):
            dut.ui_in.value = (addr + (i+1) * ENTRIES) % 256
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 1)
            assert dut.uio_out.value[READ_VALID_BIT] == 1
            assert dut.uio_out.value[TLB_HIT] == 0

    for i in range(256):
        await test_tag_conflicts(42)

    # random testing
    dut._log.info("random testing")
    # bring it to a known state, initialize the mode
    for addr in range(64):
        dut.ui_in.value = addr
        dut.uio_in.value = WRITE_EN_MASK
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)
    model: list[tuple[int, int]] = [(addr, 0) for addr in range(ENTRIES)]

    for _ in range(100000):
        is_read = random.choice([True,False])
        addr = random.randint(0,255)

        if is_read:
            dut.ui_in.value = addr
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 1)

            expected_addr, expected_value = model[addr % ENTRIES]

            #dut._log.info(f"read {expected_addr} {expected_value}")

            assert dut.uio_out.value[READ_VALID_BIT] == 1
            if expected_addr != addr:
                assert dut.uio_out.value[TLB_HIT] == 0
            if expected_addr == addr:
                assert dut.uio_out.value[TLB_HIT] == 1
                assert dut.uo_out.value == expected_value
        else:
            # do a write
            value = random.randint(0,255)

            model[addr % ENTRIES] = (addr, value)
            #dut._log.info(f"write {addr} {value}")

            dut.ui_in.value = addr
            dut.uio_in.value = WRITE_EN_MASK
            await ClockCycles(dut.clk, 1)
            dut.ui_in.value = value
            dut.uio_in.value = 0
            await ClockCycles(dut.clk, 1)
            dut.ui_in.value = 0
            await ClockCycles(dut.clk, 1)

        await ClockCycles(dut.clk, random.randint(0,3))
