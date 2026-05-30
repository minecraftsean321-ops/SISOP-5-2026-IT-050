#!/bin/bash

OUTPUT_DIR="osboot"
ISO_DIR="iso_tmp"

rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/boot/grub

cp "${OUTPUT_DIR}/bzImage" "$ISO_DIR/boot/"
cp "${OUTPUT_DIR}/single.gz" "$ISO_DIR/boot/"
cp "${OUTPUT_DIR}/multi.gz" "$ISO_DIR/boot/"

cat << EOF > "$ISO_DIR/boot/grub/grub.cfg"
set default=0
set timeout=10

menuentry "Linux Minimalist - Single User Mode" {
    linux /boot/bzImage quiet root=/dev/ram0 rdinit=/init
    initrd /boot/single.gz
}

menuentry "Linux Minimalist - Multi User Mode" {
    linux /boot/bzImage quiet root=/dev/ram0 rdinit=/init
    initrd /boot/multi.gz
}
EOF

grub-mkrescue -o "${OUTPUT_DIR}/farewell.iso" "$ISO_DIR"
rm -rf "$ISO_DIR"
echo "[+] Selesai! Bootable ISO sukses dibuat."