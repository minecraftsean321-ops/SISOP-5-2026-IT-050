# SISOP-5-2026-IT-050
| No. | Nama                   | NRP               |
|-----|------------------------|-------------------|
| 1.  | Sean Arthur Tamajaya   | 5027251050        |
## Reporting
### Soal_1

Penjelasan 
1. Pertama kita diminta untuk melengkapi scripth kenel.sh, script kernel ini kalau dijalanin bakal download linux kernel 6.1.1 dan nanti outputnya bakal ada di osboot/bzImage. Nah untuk itu kita memerlukan kode yang ada di bawah ini.

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

Setelah itu kita perlu menyiapkan konfigurasi (.config), melakukan proses kompilasi dan terakhir memindahkan output ke osboot/bzImage sesuai dengan yang diminta soal.

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
2. Setelah kita melakukan kompile kernel kita diminta untuk membuat single filesystem dengan melengkapi script single.sh, hasilnya nanti masuk ke osboot/single.gz.

Untuk langkah awal kita perlu menginisialisasi Variabel dan Folder kerja lalu membersihkan folder sisa build sebelumnya jika ada agar datanya tidak bertabrakan.

```bash
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
```
Setelah itu kita masuk ke proses download dan konfigurasi BusyBox seperti kode yang ada di bawah ini.

```bash 
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
```
Lalu karena kita telah mendownload dan mengonfigurasi BusyBoxnya sekarang kita perlu untuk membuat struktur direktori seperti yang diminta oleh soal yaitu berupa dev,proc,sys,etc,tmp dan root.

```bash
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
```
Kemudian kita perlu untuk mengonfigurasi network agar bisa mengakses internet dan dilanjutkan dengan membuat script init.

```bash
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
```

Langkah terakhir kita perlu mengemas rootfs menjadi .gz.

```bash 
# 7. Mengemas rootfs menjadi .gz
ABSOLUTE_OUTPUT="$(pwd)/${OUTPUT_DIR}"
echo "[*] Mengemas rootfs menjadi ${OUTPUT_DIR}/single.gz..."
cd "$ROOTFS"
find . -print0 | cpio --null -ov -H newc | gzip -9 > "${ABSOLUTE_OUTPUT}/single.gz"
cd ..
echo "[+] Selesai! Filesystem siap di ${OUTPUT_DIR}/single.gz"
```

3. Ketiga kita diminta untuk membuat multi filesystem dengan melengkapi script multi.sh. Nanti output hasil buildnya ada di osboot/multi.gz.

Untuk step pertama kita perlu menginisialisasi agar script ini dapat dijalankan dengan hak akses administrator karena kita nanti ada proses pembuatan file sistem dan       pengaturan izin file yang tidak bisa dilakukan oleh user biasa.

```bash 
# Auto-elevate ke root jika belum
if [ "$EUID" -ne 0 ]; then
    echo "[!] Script ini membutuhkan root. Menjalankan ulang dengan sudo..."
    exec sudo "$0" "$@"
fi

BUSYBOX_DIR="busybox-1.36.1"
ROOTFS="rootfs_multi"
OUTPUT_DIR="osboot"
```
Kemudian kita perlu untuk menginisialisasi Variabel dan Pembersihan lingkungan yang lama dan dilanjut dengan menyalin perintah-perintah yang ada di BusyBox ke OS kita.

```bash
# 1. Bersihkan lingkungan lama
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"/{dev,proc,sys,etc,tmp,root,home,var/log}
chmod 1777 "$ROOTFS/tmp"

# 2. Cek dan salin hasil build BusyBox
if [ ! -d "$BUSYBOX_DIR/_install" ]; then
    echo "[-] Error: Jalankan single.sh terlebih dahulu!"
    exit 1
fi
cp -av "$BUSYBOX_DIR/_install/"* "$ROOTFS/"
```
Setelah itu kita perlu untuk membuat daftar pengguna (users) beserta kata sandinya, kata sandi pengguna disini akan dienkripsi menggunakan algoritma MD5.

```bash
# 3. Generate Hash MD5
HASH_ROOT=$(openssl passwd -1 "root123")
HASH_HENN=$(openssl passwd -1 "henn123")
HASH_HANN=$(openssl passwd -1 "hann123")
HASH_VIII=$(openssl passwd -1 "viii123")
HASH_KIDS=$(openssl passwd -1 "kids123")

# 4. Tulis /etc/passwd dengan hash langsung (tanpa shadow)
printf "root:%s:0:0:root:/root:/bin/sh\n" "$HASH_ROOT" > "$ROOTFS/etc/passwd"
printf "henn:%s:1001:1001:henn:/home/henn:/bin/sh\n" "$HASH_HENN" >> "$ROOTFS/etc/passwd"
printf "hann:%s:1002:1002:hann:/home/hann:/bin/sh\n" "$HASH_HANN" >> "$ROOTFS/etc/passwd"
printf "viii:%s:1003:1003:viii:/home/viii:/bin/sh\n" "$HASH_VIII" >> "$ROOTFS/etc/passwd"
printf "kids:%s:1004:1004:kids:/home/kids:/bin/sh\n" "$HASH_KIDS" >> "$ROOTFS/etc/passwd"

# Hapus shadow agar login baca dari passwd langsung
rm -f "$ROOTFS/etc/shadow"
```

Lalu kita perlu mengatur hak akses dari pengguna yang telah ditetapkan, disini saya menggunakan sistem hierarki menurun yang dimana user yang memiliki kedudukan diatas dapat mengakses file user yang ada dibawahnya. Selain itu kita juga perlu untuk memasang pengelola aplikasi dan mengatur koneksi internet dasar agar OS kita dapat mengunduh file dari luar.

```bash
# 5. /etc/group — hierarki akses menurun
cat << 'EOF' > "$ROOTFS/etc/group"
root:x:0:
henn:x:1001:henn
hann:x:1002:hann,henn
viii:x:1003:viii,hann,henn
kids:x:1004:kids,viii,hann,henn
EOF

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

# 6. Konfigurasi Network
cat << 'EOF' > "$ROOTFS/etc/resolv.conf"
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

cat << 'EOF' > "$ROOTFS/etc/wgetrc"
check_certificate=off
EOF
```

Sesudah itu kita perlu untuk memubuat rumah/wadah bagi setiap user dan mengatur hak kepemilikan serta izin akses file secara ketat, selain itu juga membuat banner yang diperlukan untuk tampilan awal OS.

```bash
# 7. Membuat Direktori Home
mkdir -p "$ROOTFS"/home/{henn,hann,viii,kids}

# ==================== SETTING PERMISSION MATRIX ====================
chmod 755 "$ROOTFS"
chmod 755 "$ROOTFS/home"

chown 0:0 "$ROOTFS/root" && chmod 700 "$ROOTFS/root"

chown 1001:1001 "$ROOTFS/home/henn" && chmod 755 "$ROOTFS/home/henn"
chown 1002:1002 "$ROOTFS/home/hann" && chmod 755 "$ROOTFS/home/hann"
chown 1003:1003 "$ROOTFS/home/viii" && chmod 755 "$ROOTFS/home/viii"
chown 1004:1004 "$ROOTFS/home/kids" && chmod 755 "$ROOTFS/home/kids"

chown -R 1001:1001 "$ROOTFS/home/henn"
chown -R 1002:1002 "$ROOTFS/home/hann"
chown -R 1003:1003 "$ROOTFS/home/viii"
chown -R 1004:1004 "$ROOTFS/home/kids"

# ==================== BANNER SETTING ====================
cat << 'EOF' > "$ROOTFS/etc/profile"
echo "  ______                               _ _   _____                _H "
echo " |  ____|                             | | | |  __ \              | | "
echo " | |__ __ _ _ __ _____      _____  ___| | | | |__) |_ _ _ __| |_ _   "
echo " |  __/ _\` | '__/ _ \ \ /\ / / _ \/ _ \ | | |  ___/ _\` | '__| __| | | "
echo " | | | (_| | | |  __/\ V  V /  __/  __/ | | | |  | (_| | |  | |_| |_| "
echo " |_|  \__,_|_|  \___| \_/\_/ \___|\___|_|_| |_|   \__,_|_|   \__|\__, "
echo "                                                                     "
echo "Welcome, $(whoami)."
echo ""
cd ~
EOF
```

Terakhir saya membuat init script dan mengemas rootfs menjadi .gz  

```bash
# 8. Init Script
cat << 'EOF' > "$ROOTFS/init"
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev

# Setup network manual (QEMU user-mode)
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf

clear
exec /sbin/getty -L console 0 vt100
EOF
chmod +x "$ROOTFS/init"

# 9. Mengemas rootfs menjadi .gz
ABSOLUTE_OUTPUT="$(pwd)/${OUTPUT_DIR}"
echo "[*] Mengemas rootfs menjadi ${OUTPUT_DIR}/multi.gz..."
cd "$ROOTFS"
find . -print0 | cpio --null -ov -H newc | gzip -9 > "${ABSOLUTE_OUTPUT}/multi.gz"
cd ..
echo "[+] Selesai! Filesystem Multi-User siap di ${OUTPUT_DIR}/multi.gz"
```

4. Keempat kita diminta untuk membuat bootable yang dapat mengeload kedua filesystem sebelumnya dengan melengkapi script iso.sh dan outpunya akan masuk ke osboot/farewell.iso.

Untuk langkah pertama kita perlu menyiapkan folder sementara bernama iso_tmp sebagai tempat untuk merakit komponen OS sebelum diubah menjadi file ISO, setelah itu kita juga perlu untuk menyalin command Linux dari BusyBox.

```bash 
rm -rf "$ISO_DIR"
mkdir -p "$ISO_DIR"/boot/grub

cp "${OUTPUT_DIR}/bzImage" "$ISO_DIR/boot/"
cp "${OUTPUT_DIR}/single.gz" "$ISO_DIR/boot/"
cp "${OUTPUT_DIR}/multi.gz" "$ISO_DIR/boot/"
```

Kemudian kita perlu membuat menu booting yang akan ditampilkan saat komputer pertama kali dinyalakan. 

```bash
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
EO
```  

Terakhir kita perlu mengubah file iso sementara tadi menjadi file master ISO yang siap pakai.

```bash
grub-mkrescue -o "${OUTPUT_DIR}/farewell.iso" "$ISO_DIR"
rm -rf "$ISO_DIR"
echo "[+] Selesai! Bootable ISO sukses dibuat."
```

5. Kelima kita diminta untuk ngeboot OS yang telah kita bikin tadi dengan melengkapi script qemu.sh. Dengan specs ./qemu.sh --single untuk ngeboot filesystem yang singe-user lalu ./qemu.sh --multi untuk ngeboot filesystem yang multi-user dan ./qemu.sh --all untuk mendapatkan pilihan nanti mau ngeboot yang single atau multi.

Jadi inti dari kode qemu.sh dibawah ini adalah kita menggunakan syntax case untuk mengambil kondisi string setelah perintah ./qemu.sh itu apakah single, multi atau all. Jika user memilih --single, qemu akan memasukkan sistem single.gz, begitu juga jika user memilih --multi maka qemu akan memasukkan sistem multi.gz, dan terakhir jika user memilih --all maka qemu akan menggunakan farewell.iso.

```bash
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
```

6. Keenam untuk keperluan arsip maka semua file tadi perlu dibackup dengan melengkapi script backup.sh dimana script ini bakal nge zip semua file bzimage, single.gz, multi.gz dan farewell.iso yang hasilnya akan disimpan di osboot/.

Langkah pertama kita perlu membuat nama file yang unik dengan menggunakan tanggal dan waktu saat ini sehingga saat script dijalankan tidak ada file yang saling menimpa.

```bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="farewell_backup_${TIMESTAMP}.zip"
BACKUP_PATH="${OUTPUT_DIR}/${BACKUP_NAME}"
```

Kemudian kita perlu memeriksa kelengkapan file penting yang akan di zip.

```bash
FILES_TO_BACKUP=(
    "${OUTPUT_DIR}/bzImage"
    "${OUTPUT_DIR}/single.gz"
    "${OUTPUT_DIR}/multi.gz"
    "${OUTPUT_DIR}/farewell.iso"
)

for f in "${FILES_TO_BACKUP[@]}"; do
    if [ ! -f "$f" ]; then
        echo "[-] Error: File $f tidak ditemukan!..."
        exit 1
    fi
done
```

Jika semua file dipastikan ada kita mulai membungkus keempat file tersebut menjadi satu file .zip di dalam folder osboot.

```bash
zip "$BACKUP_PATH" "${FILES_TO_BACKUP[@]}" || { echo "[-] Proses zip gagal!"; exit 1; }
```

Setelah semua file asli dipastikan aman tersimpan di dalam file .zip, script akan menghapus file-file mentah yang berserakan di folder osboot.

```bash 
echo "[*] Menghapus file asli..."
for f in "${FILES_TO_BACKUP[@]}"; do
    rm -f "$f"
    echo "    [-] Dihapus: $f"
done
```

7. Untuk langkah ketuju kita diminta mengecek apakah OS kita sudah bisa akses internet. Nah untuk OS kita kali ini itu menggunakan TAP network interface untuk koneksi internetnya, dan itu perlu untuk set up terlebih dahulu, jadi sistem host itu perlu dikonfigurai dengan membuat virtual network interface tap0 yang berperan sebagai gateway antara guest OS dan jaringan host.

Ini merupakan bagian kode di file qemu.sh untuk setup networknya.

```bash
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

    # Setup NAT
    sudo iptables -t nat -A POSTROUTING -o "$HOST_IF" -j MASQUERADE
    sudo iptables -A FORWARD -i tap0 -o "$HOST_IF" -j ACCEPT
    sudo iptables -A FORWARD -i "$HOST_IF" -o tap0 -m state --state RELATED,ESTABLISHED -j ACCEPT
}
```
Lalu ini bagian untuk attach tap0 ke qemunya.

```bash
-netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
-device virtio-net-pci,netdev=net0
```

Terakhir ini merupakan bagian untuk ini script di dalam rootfs nya.

```bash
ifconfig eth0 10.0.2.15 netmask 255.255.255.0 up
route add default gw 10.0.2.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

Output:

![Isi file gsx](<Assets/Soal_2/Isifilegsx.png>)



