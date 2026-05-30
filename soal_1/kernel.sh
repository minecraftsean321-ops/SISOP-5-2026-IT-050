#!/bin/bash

# 1. Inisialisasi Variabel dan Folder
KERNEL_VERSION="6.1.1"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}"
KERNEL_DIR="linux-${KERNEL_VERSION}"
OUTPUT_DIR="osboot"

# Memastikan folder osboot/ tersedia
mkdir -p "$OUTPUT_DIR"

# 2. Proses Download Kernel Linux 6.1.1 (jika belum ada)
if [ ! -f "$KERNEL_TAR" ] && [ ! -d "$KERNEL_DIR" ]; then
    echo "[*] Mendownload Linux Kernel v${KERNEL_VERSION}..."
    wget "$KERNEL_URL" || { echo "[-] Download gagal!"; exit 1; }
fi

# 3. Proses Ekstraksi Source Code
if [ ! -d "$KERNEL_DIR" ]; then
    echo "[*] Mengekstrak ${KERNEL_TAR}..."
    tar -xf "$KERNEL_TAR" || { echo "[-] Ekstraksi gagal!"; exit 1; }
fi

# 4. Penyiapan Konfigurasi (.config)
if [ -f ".config" ]; then
    echo "[*] Menyalin file .config ke folder kernel..."
    cp .config "$KERNEL_DIR/"
else
    echo "[!] Peringatan: File .config tidak ditemukan di folder utama."
    echo "[*] Menggunakan default config (defconfig)..."
    make -C "$KERNEL_DIR" defconfig
fi

# 5. Proses Kompilasi (Koreksi/Build)
echo "[*] Memulai kompilasi kernel (ini akan memakan waktu)..."
# -j$(nproc) digunakan untuk mempercepat proses menggunakan semua core CPU yang ada
make -C "$KERNEL_DIR" -j$(nproc) bzImage KCFLAGS="-w" || { echo "[-] Kompilasi kernel gagal!"; exit 1; }

# 6. Memindahkan Output ke osboot/bzImage
# Jalur default bzImage arsitektur x86 biasanya ada di arch/x86/boot/bzImage
BUILT_IMAGE="${KERNEL_DIR}/arch/x86/boot/bzImage"

if [ -f "$BUILT_IMAGE" ]; then
    echo "[*] Memindahkan hasil build ke ${OUTPUT_DIR}/bzImage..."
    cp "$BUILT_IMAGE" "${OUTPUT_DIR}/bzImage"
    echo "[+] Selesai! Kernel siap di ${OUTPUT_DIR}/bzImage"
else
    echo "[-] Error: bzImage tidak ditemukan di tempat hasil kompilasi."
    exit 1;
fi
