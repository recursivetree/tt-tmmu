# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
import random

async def wait_clk_cycle_to_app(dut, n):
    if n > 0:
        await ClockCycles(dut.clk, n)
        await cocotb.triggers.Timer(5, unit="ns")

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")
    random.seed(2)

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await wait_clk_cycle_to_app(dut, 1)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    ENTRIES = 64

    # input bit positions
    WRITE_EN_MASK = 1
    ANCIL_DATA_1_IN = 1 << 3
    ANCIL_DATA_2_IN = 1 << 5

    # output bit positions
    READ_VALID_BIT = 1
    TLB_HIT = 2
    ANCIL_DATA_1_OUT = 4
    ANCIL_DATA_2_OUT = 6

    # test all cells
    for base in range(256 // ENTRIES):
        for offset in range(64):
            addr = base * ENTRIES + offset
            dut.ui_in.value = addr
            dut.uio_in.value = WRITE_EN_MASK
            await wait_clk_cycle_to_app(dut, 1)
            dut.ui_in.value = (addr + 7) % 256
            dut.uio_in.value = ANCIL_DATA_1_IN if addr % 3 == 1 else ANCIL_DATA_2_IN
            await wait_clk_cycle_to_app(dut, 1)
            dut.ui_in.value = 0
            await wait_clk_cycle_to_app(dut, 1)

        for offset in range(64):
            addr = base * ENTRIES + offset
            dut.ui_in.value = addr
            dut.uio_in.value = 0
            await cocotb.triggers.Timer(10, unit="ns")
            assert dut.uio_out.value[READ_VALID_BIT] == 1
            assert dut.uio_out.value[TLB_HIT] == 1
            assert dut.uo_out.value == (addr + 7) % 256
            if addr % 3 == 1:
                assert dut.uio_out.value[ANCIL_DATA_1_OUT] == 1
                assert dut.uio_out.value[ANCIL_DATA_2_OUT] == 0
            else:
                assert dut.uio_out.value[ANCIL_DATA_1_OUT] == 0
                assert dut.uio_out.value[ANCIL_DATA_2_OUT] == 1
            await cocotb.triggers.Timer(10, unit="ns")

    # test tag checks
    async def test_tag_conflicts(addr):
        # do a write
        dut.ui_in.value = addr
        dut.uio_in.value = WRITE_EN_MASK
        await wait_clk_cycle_to_app(dut, 1)
        dut.ui_in.value = 243  # random choice
        dut.uio_in.value = 0
        await wait_clk_cycle_to_app(dut, 1)
        dut.ui_in.value = 0
        await wait_clk_cycle_to_app(dut, 1)

        # read a tag conflicting value
        for i in range(3):
            dut.ui_in.value = (addr + (i+1) * ENTRIES) % 256
            dut.uio_in.value = 0
            await cocotb.triggers.Timer(10, unit="ns")
            assert dut.uio_out.value[READ_VALID_BIT] == 1
            assert dut.uio_out.value[TLB_HIT] == 0
            await cocotb.triggers.Timer(10, unit="ns")

    for i in range(256):
        await test_tag_conflicts(42)

    # random testing
    dut._log.info("random testing")
    # bring it to a known state, initialize the mode
    for addr in range(64):
        dut.ui_in.value = addr
        dut.uio_in.value = WRITE_EN_MASK
        await wait_clk_cycle_to_app(dut, 1)
        dut.ui_in.value = 0
        dut.uio_in.value = 0
        await wait_clk_cycle_to_app(dut, 1)
        dut.ui_in.value = 0
        await wait_clk_cycle_to_app(dut, 1)
    model: list[tuple[int, int]] = [(addr, 0) for addr in range(ENTRIES)]

    for _ in range(100000):
        is_read = random.choice([True,False])
        addr = random.randint(0,255)

        if is_read:
            dut.ui_in.value = addr
            dut.uio_in.value = 0

            await cocotb.triggers.Timer(10, unit="ns")

            expected_addr, expected_value = model[addr % ENTRIES]

            #dut._log.info(f"read addr={addr} expected_addr={expected_addr} expected_value={expected_value}")

            assert dut.uio_out.value[READ_VALID_BIT] == 1
            if expected_addr != addr:
                assert dut.uio_out.value[TLB_HIT] == 0
            if expected_addr == addr:
                assert dut.uio_out.value[TLB_HIT] == 1
                assert dut.uo_out.value == expected_value

            await cocotb.triggers.Timer(10, unit="ns")
        else:
            # do a write
            value = random.randint(0,255)

            model[addr % ENTRIES] = (addr, value)
            #dut._log.info(f"write {addr} {value}")

            dut.ui_in.value = addr
            dut.uio_in.value = WRITE_EN_MASK
            await wait_clk_cycle_to_app(dut, 1)
            dut.ui_in.value = value
            dut.uio_in.value = 0
            await wait_clk_cycle_to_app(dut, 1)
            dut.ui_in.value = 0
            await wait_clk_cycle_to_app(dut, 1)

        await cocotb.triggers.Timer(10, unit="ns")
        assert dut.uio_out.value[READ_VALID_BIT] == 1
        await cocotb.triggers.Timer(10, unit="ns")

        await wait_clk_cycle_to_app(dut, random.randint(0,3))
