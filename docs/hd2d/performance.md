# HD2D local runtime measurements

Windows / OpenGL / 3.3.0 NVIDIA 591.86 / NVIDIA Corporation / NVIDIA GeForce GTX 1650/PCIe/SSE2

Uncapped vsync=0, warmed idle boss battle. Consecutive wall-clock update intervals, not guarantees for target hardware.

| Window | Quality | Samples | Average ms | P50 ms | P95 ms | Mean FPS | World CPU submission ms |
|---|---|---:|---:|---:|---:|---:|---:|
| 1920x1080 | LOW | 284 | 4.16 | 4.06 | 5.35 | 240.1 | 0.51 |
| 1920x1080 | MEDIUM | 288 | 4.13 | 4.01 | 5.40 | 241.9 | 0.60 |
| 1920x1080 | HIGH | 269 | 4.42 | 4.27 | 6.05 | 226.1 | 0.67 |
| 1600x900 | LOW | 299 | 4.00 | 4.01 | 5.03 | 249.7 | 0.46 |
| 1600x900 | MEDIUM | 302 | 3.94 | 3.98 | 5.04 | 253.8 | 0.56 |
| 1600x900 | HIGH | 279 | 4.24 | 4.09 | 5.68 | 235.7 | 0.62 |
| 1366x768 | LOW | 309 | 3.83 | 3.71 | 4.85 | 261.2 | 0.42 |
| 1366x768 | MEDIUM | 304 | 3.89 | 3.95 | 4.92 | 256.9 | 0.55 |
| 1366x768 | HIGH | 284 | 4.16 | 4.11 | 5.27 | 240.5 | 0.58 |

CPU submission timing surrounds world render command submission; it is not GPU execution time. Shader validation, snapshots, mode changes and warmup are excluded from frame sample windows. Artwork, card shaders and full UI are enabled. Bloom uses 2 reduced targets; particles capped at 18/36/56.
