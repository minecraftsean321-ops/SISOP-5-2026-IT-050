# SISOP-5-2026-IT-050
| No. | Nama                   | NRP               |
|-----|------------------------|-------------------|
| 1.  | Sean Arthur Tamajaya   | 5027251050        |
## Reporting
### Soal_1

Penjelasan 
Pertama kita diminta untuk melengkapi scripth kenel.sh, script kernel ini kalau dijalanin bakal download linux kernel 6.1.1 dan nanti outputnya bakal ada di osboot/bzImage. Nah untuk itu kita memerlukan kode yang ada di bawah ini.

Kode ini digunakan untuk menginisialisasi Variabel dan Folder yang akan digunakan, selain itu kode ini juga memastikan apakah folder osboot itu tersedia.

```bash
KERNEL_VERSION="6.1.1"
KERNEL_TAR="linux-${KERNEL_VERSION}.tar.xz"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/${KERNEL_TAR}"
KERNEL_DIR="linux-${KERNEL_VERSION}"
OUTPUT_DIR="osboot"

mkdir -p "$OUTPUT_DIR"
```

Lalu kita lanjut untuk membuat kode yang dapat mendownload Kernel Linux 6.1.1 (jika belum ada) dan melakukan proses ekstrasi source code.

```bash
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
```

Setelah itu kita perlu menyiapkan konfigurasi (.config), melakukan proses kompilasi dan terakhir memindahkan output ke osboot/bzImage sesuai dengan yang diminta soal>

```bash
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
```
