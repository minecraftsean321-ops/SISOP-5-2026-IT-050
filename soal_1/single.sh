#!/bin/bash

# 1. Inisialisasi Variabel dan Folder Kerja
BUSYBOX_VERSION="1.36.1"
BUSYBOX_TAR="busybox-${BUSYBOX_VERSION}.tar.bz2"
BUSYBOX_URL="https://busybox.net/downloads/${BUSYBOX_TAR}"
BUSYBOX_DIR="busybox-${BUSYBOX_VERSION}"

ROOTFS="rootfs_single"
OUTPUT_DIR="osboot"

# Bersihkan folder sisa build sebelumnya jika ada
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"
mkdir -p "$OUTPUT_DIR"

# 2. Download dan Ekstrak BusyBox
if [ ! -f "$BUSYBOX_TAR" ] && [ ! -d "$BUSYBOX_DIR" ]; then
    echo "[*] Mendownload BusyBox v${BUSYBOX_VERSION}..."
    wget "$BUSYBOX_URL" || { echo "[-] Download BusyBox gagal!"; exit 1; }
fi

if [ ! -d "$BUSYBOX_DIR" ]; then
    echo "[*] Mengekstrak ${BUSYBOX_TAR}..."
    tar -xf "$BUSYBOX_TAR" || { echo "[-] Ekstraksi BusyBox gagal!"; exit 1; }
fi

# 3. Konfigurasi dan Build BusyBox secara Statis
echo "[*] Mengonfigurasi BusyBox..."
cd "$BUSYBOX_DIR"
make defconfig

sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config

echo "[*] Memulai kompilasi BusyBox..."
make -j$(nproc) install || { echo "[-] Kompilasi BusyBox gagal!"; exit 1; }
cd ..

# 4. Membuat Struktur Direktori
echo "[*] Menyusun struktur rootfs..."
cp -av "$BUSYBOX_DIR/_install/"* "$ROOTFS/"
mkdir -p "$ROOTFS"/{dev,proc,sys,etc,tmp,root}

# Tambahkan party package manager
if [ -f "party" ]; then
    echo "[*] Menambahkan party package manager..."
    cp party "$ROOTFS/usr/bin/party"
    chmod +x "$ROOTFS/usr/bin/party"
else
    echo "[!] Warning: file 'party' tidak ditemukan di folder ini!"
fi
 
# Setup Alpine repository untuk party
mkdir -p "$ROOTFS/etc/apk"
cat << 'EOF' > "$ROOTFS/etc/apk/repositories"
https://dl-cdn.alpinelinux.org/alpine/latest-stable/main
https://dl-cdn.alpinelinux.org/alpine/latest-stable/community
EOF

# 5. Konfigurasi Network (untuk akses internet)
mkdir -p "$ROOTFS/etc"
cat << 'EOF' > "$ROOTFS/etc/resolv.conf"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

# Konfigurasi wget bypass TLS verification
cat << 'EOF' > "$ROOTFS/etc/wgetrc"
check_certificate=off
EOF

# Script network auto-up saat boot
cat << 'EOF' >> "$ROOTFS/etc/profile"
# Auto-configure network
ifconfig eth0 up 2>/dev/null
udhcpc -i eth0 -q 2>/dev/null
EOF

# 6. Membuat Script init
echo "[*] Membuat script init..."
cat << 'EOF' > "$ROOTFS/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Setup network manual (QEMU user-mode)
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf

echo "========================================"
echo "  Selamat Datang di Linux Single-User   "
echo "========================================"

setsid cttyhack /bin/sh
EOF

chmod +x "$ROOTFS/init"

# 7. Mengemas rootfs menjadi .gz
ABSOLUTE_OUTPUT="$(pwd)/${OUTPUT_DIR}"
echo "[*] Mengemas rootfs menjadi ${OUTPUT_DIR}/single.gz..."
cd "$ROOTFS"
find . -print0 | cpio --null -ov -H newc | gzip -9 > "${ABSOLUTE_OUTPUT}/single.gz"
cd ..
echo "[+] Selesai! Filesystem siap di ${OUTPUT_DIR}/single.gz"
