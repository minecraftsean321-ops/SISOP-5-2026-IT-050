#!/bin/bash

OUTPUT_DIR="osboot"

case "$1" in
    --single)
        echo "[*] Booting Single-User Filesystem langsung..."
        qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/single.gz" \
            -append "quiet root=/dev/ram0 rdinit=/init console=tty1" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;
    --multi)
        echo "[*] Booting Multi-User Filesystem langsung..."
        qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/multi.gz" \
            -append "quiet root=/dev/ram0 rdinit=/init console=tty1" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;
    --all)
        echo "[*] Booting dari Menu Grub ISO Image..."
        qemu-system-x86_64 \
            -cdrom "${OUTPUT_DIR}/farewell.iso" \
            -netdev user,id=net0 \
            -device virtio-net-pci,netdev=net0
        ;;
    *)
        echo "Cara Penggunaan:"
        echo "  $0 --single     -> Booting single-user"
        echo "  $0 --multi      -> Booting multi-user"
        echo "  $0 --all        -> Booting ISO"
        exit 1
        ;;
esac