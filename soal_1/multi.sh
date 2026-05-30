#!/bin/bash

# Auto-elevate ke root jika belum
if [ "$EUID" -ne 0 ]; then
    echo "[!] Script ini membutuhkan root. Menjalankan ulang dengan sudo..."
    exec sudo "$0" "$@"
fi

BUSYBOX_DIR="busybox-1.36.1"
ROOTFS="rootfs_multi"
OUTPUT_DIR="osboot"

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
