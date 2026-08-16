# FlexOS 0.5 Beta test matrix

The machine-readable source of truth is `qa/test-matrix.json`.

Status values:

- `pending`: not tested yet
- `pass`: verified
- `fail`: reproduced failure
- `blocked`: test could not be completed

For manual tests, record the VM/hardware model, ISO SHA256 and a short note.
Do not mark a test `pass` only because the same feature worked in an older ISO.

Suggested VM coverage:
- VirtualBox UEFI and BIOS
- QEMU/KVM
- VMware

Suggested real hardware:
- Intel iGPU
- AMD GPU
- NVIDIA GPU
- laptop with battery, Wi-Fi and Bluetooth
- NVMe and SATA where available
