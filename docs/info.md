<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This is a TLB (translation lookaside buffer) for a TTL IC breadboard CPU using latch memory.

While I've designed it as a TLB, more generally it is a latch-based, direct-mapped cache.
Input addresses are 8 bits, and each entries contain 10 bits. There is a total of 64 entries
in the cache (so 25% of addressable values, with a tag of 1 bit).

For a detailed explanation of latch memory, I can recommend [this TT submission](https://github.com/MichaelBell/tt06-memory/blob/main/docs/info.md).

## How to test
The design has three states:

- READ: The initial state. In this state, the value on ui_in is used as an address to look up. If it is a hit, the 
  tlb_hit and read_valid signals should be one. The data can be seen on uo_out plus two pins on
  uio_out.

  When the write_en signal is raised while in READ state, we initiate a write. In the cycle where write_en goes high,
  the address on ui_in is captured as the address to be used for the write. We also transition into the ACQUIRE state.
- ACQUIRE: The ACQUIRE state captures the data that will be written on the ui_in pins and two uio_in pins. We also transition to the WRITE state in the next cycle.
- WRITE: The actual write will execute during this cycle. The design transitions back to the READ state in the next cycle.

## External hardware

You should be able to test it with just the devboard, but I haven't tried it yet.
