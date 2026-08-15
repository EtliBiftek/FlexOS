# Hardware policy

FlexOS 0.1 targets ordinary x86_64 PCs and VMs.

Included by default:

- Debian amd64 kernel
- Intel and AMD CPU microcode
- Common Intel, Realtek, Qualcomm/Atheros and MediaTek firmware
- NetworkManager, Bluetooth and PipeWire audio
- UEFI/BIOS boot tooling

The first alpha intentionally does not bundle proprietary GPU driver stacks. Additional drivers can be installed from Debian repositories when appropriate after installation.
