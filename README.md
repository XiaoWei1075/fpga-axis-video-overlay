# fpga-axis-video-overlay

Zero-latency AXI4-Stream pixel overlay engine with run-length encoding. Source-only distribution — import into any Xilinx Vivado project.

## Demo

| `play_video.py` Visualization | HDMI Output |
|:---:|:---:|
| ![play_video.py screenshot](assets/one.png) | ![HDMI display](assets/two.jpg) |

## What It Does

This IP sits inline on an AXI4-Stream video pipeline. You write color patterns through an AXI4-Lite register interface as RLE-compressed pixel runs. The engine overlays them onto the live stream with zero clock cycles of added latency.

Patterns are stored in a double-buffered BRAM. Writing hits one bank while the other bank is read. A `commit` register initiates a bank swap at the next frame boundary, making pattern changes tear-free.

## Getting Started

### Run the Simulation

1.  Create a new Vivado project (RTL Project, no sources at creation).
2.  Add the source files:
    - `image_filter.v` (top module)
    - `image_filter_slave_lite_v1_0_S00_AXI.v`
3.  Add the simulation source:
    - `tb_top.v`
4.  Generate a Block Memory Generator IP named `blk_mem_gen_0` with simple Dual-Port RAM, 64-bit write / 64-bit read, depth matching twice `ERAM_DEPTH`.
5.  Update the input file paths in `tb_top.v` — search for `$sformat(in_path, …)` and replace the absolute paths with your `InData/` directory location.
6.  Click **Run Behavioral Simulation**.

The testbench streams 30 frames of raw 256×256 RGB while applying three overlay patterns:

| Frame | Pattern | Color |
|:---:|---|:---:|
| 1 | Hexagram (star of David) | White |
| 10 | Circle (radius 24) | Blue |
| 20 | Square outline (16×16) | Green |

### Visualize Output

```bash
python3 play_video.py
```

Reads the generated `OutData/` frames and plays them as an animation.

## How It Works

```
AXI4-Stream IN ──→ [ pixel_cnt FSM ] ──→ AXI4-Stream OUT
                        │
                   match? ───→ overlay color from BRAM
                        │
                  eram_ptr walks sorted item list
```

Each RLE item is a 64-bit word:

```
[63:40] offset   — start pixel (linear address: y × width + x)
[39:24] run_len  — number of consecutive pixels
[23:0]  RGB      — 24-bit color value
```

Consecutive runs with the same color and contiguous offsets are merged into one entry, reducing BRAM usage.

### Key Design Choices

- **Two clock domains**: AXI4-Lite at ~133 MHz, video pipeline at 200 MHz. All cross-domain signals use 2-FF synchronizers.
- **Frame-aligned bank switching**: Writing `commit_bank = 1` marks the write bank ready. The hardware waits for the current read frame to finish, then swaps banks and clears the commit flag.
- **Configurable format**: Output format selector (RGB888, BGR888, RGB565, BGR565) via the `pixel_format` register.

## Register Map

Base address: `0x80400000`

| Offset | Name | R/W | Description |
|:---:|------|:---:|------|
| `0x00` | `enable_filter` | R/W | Enable overlay (1 = on) |
| `0x04` | `frame_pixels` | R | Total pixels per frame (read-only) |
| `0x08` | `pixel_offset` | R | Current pixel counter |
| `0x0C` | `commit_bank` | R/W | Write 1 to commit, auto-cleared on swap |
| `0x10` | `item_overflow` | R | Sticky overflow flag |
| `0x14` | `active_item_count` | R | Number of items in the active bank |
| `0x18` | `eram_write_ptr` | R | Number of items queued for commit |
| `0x1C` | `pixel_format` | R/W | bits [1:0]: 00=RGB888, 01=BGR888, 10=RGB565, 11=BGR565 |
| `0x20+` | item data | W | 64-bit RLE items across two 32-bit writes |

## Repository Files

| File | Description |
|------|------------|
| `image_filter.v` | Top-level module: AXI-Stream passthrough + overlay logic |
| `image_filter_slave_lite_v1_0_S00_AXI.v` | AXI4-Lite slave: register file + RLE merge + BRAM management |
| `tb_top.v` | Testbench: 30-frame AXI-Stream simulation with three overlay patterns |
| `play_video.py` | Python script to visualize `OutData/` frames as an animation |
| `InData/` | Input raw frames (256×256, 24-bit RGB) |
| `LICENSE` | MIT License |

## Requirements

- Xilinx Vivado (project uses `blk_mem_gen_0` block RAM IP)
- Python 3 with NumPy and Matplotlib (for `play_video.py`)

## License

MIT — see [LICENSE](LICENSE).
