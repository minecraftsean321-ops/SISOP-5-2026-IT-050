#!/bin/bash

OUTPUT_DIR="osboot"

# Generate nama file dengan format DDMMYYYY-HHMMSS
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
BACKUP_NAME="farewell_backup_${TIMESTAMP}.zip"
BACKUP_PATH="${OUTPUT_DIR}/${BACKUP_NAME}"

echo "[*] Memulai backup ke ${BACKUP_PATH}..."

# Cek semua file yang dibutuhkan
FILES_TO_BACKUP=(
    "${OUTPUT_DIR}/bzImage"
    "${OUTPUT_DIR}/single.gz"
    "${OUTPUT_DIR}/multi.gz"
    "${OUTPUT_DIR}/farewell.iso"
)

for f in "${FILES_TO_BACKUP[@]}"; do
    if [ ! -f "$f" ]; then
        echo "[-] Error: File $f tidak ditemukan! Pastikan semua script sudah dijalankan."
        exit 1
    fi
done

# Zip semua file
zip "$BACKUP_PATH" "${FILES_TO_BACKUP[@]}" || { echo "[-] Proses zip gagal!"; exit 1; }

echo "[*] Menghapus file asli..."
for f in "${FILES_TO_BACKUP[@]}"; do
    rm -f "$f"
    echo "    [-] Dihapus: $f"
done

echo "[+] Selesai! Backup tersimpan di ${BACKUP_PATH}"
