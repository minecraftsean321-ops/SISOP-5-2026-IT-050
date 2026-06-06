#!/bin/bash

OUTPUT_DIR="osboot"

# Setup tap network otomatis
setup_network() {
    # Hapus tap0 lama jika ada
    sudo ip link delete tap0 2>/dev/null

    # Buat tap0 baru owned by root
    sudo tunctl -t tap0
    sudo ip addr add 10.0.2.1/24 dev tap0
    sudo ip link set tap0 up
    sudo sysctl -w net.ipv4.ip_forward=1 > /dev/null

    # Deteksi interface internet host
    HOST_IF=$(ip route | grep default | awk '{print $5}' | head -1)

    # Flush iptables lama untuk tap0
    sudo iptables -t nat -D POSTROUTING -o "$HOST_IF" -j MASQUERADE 2>/dev/null
    sudo iptables -D FORWARD -i tap0 -o "$HOST_IF" -j ACCEPT 2>/dev/null
    sudo iptables -D FORWARD -i "$HOST_IF" -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null

    # Setup NAT baru
    sudo iptables -t nat -A POSTROUTING -o "$HOST_IF" -j MASQUERADE
    sudo iptables -A FORWARD -i tap0 -o "$HOST_IF" -j ACCEPT
    sudo iptables -A FORWARD -i "$HOST_IF" -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT

    echo "[+] Network tap0 siap!"
}

case "$1" in
    --single)
        echo "[*] Booting Single-User Filesystem langsung..."
        setup_network
        sudo qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/single.gz" \
            -append "quiet root=/dev/ram0 rdinit=/init console=tty1" \
            -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
            -device virtio-net-pci,netdev=net0
        ;;
    --multi)
        echo "[*] Booting Multi-User Filesystem langsung..."
        setup_network
        sudo qemu-system-x86_64 \
            -kernel "${OUTPUT_DIR}/bzImage" \
            -initrd "${OUTPUT_DIR}/multi.gz" \
            -append "quiet root=/dev/ram0 rdinit=/init console=tty1" \
            -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
            -device virtio-net-pci,netdev=net0
        ;;
    --all)
        echo "[*] Booting dari Menu Grub ISO Image..."
        setup_network
        sudo qemu-system-x86_64 \
            -cdrom "${OUTPUT_DIR}/farewell.iso" \
            -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
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