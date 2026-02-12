#!/bin/bash
set -e

# 1. Ścieżki
MPY_DIR="lib/micropython"
MPY_CROSS_DIR="$MPY_DIR/mpy-cross"
# Używamy pełnej, sztywnej ścieżki
PORT_DIR="lib/micropython/ports/esp32"

# 2. BUDOWANIE MPY-CROSS (To już nam działa!)
echo "Budowanie mpy-cross..."
make -C "$MPY_CROSS_DIR" CC=gcc CROSS_COMPILE=""

# 3. TWORZENIE TABELI PARTYDJI 16MB
echo "Tworzenie tabeli partycji..."
cat <<EOF > "$PORT_DIR/partitions-16mb.csv"
nvs,      data, nvs,     0x9000,  0x6000,
otadata,  data, ota,     0xf000,  0x2000,
phy_init, data, phy,     0x11000, 0x1000,
ota_0,    app,  ota_0,   0x20000, 0x800000,
vfs,      data, fat,     0x820000, 0x7E0000,
EOF

# 4. KOMPILACJA (Wchodzimy fizycznie do folderu)
echo "Kompilacja MicroPython dla ESP32-S3..."
cd "$PORT_DIR"
make BOARD=ESP32_GENERIC_S3 BOARD_VARIANT=SPIRAM_OCTAL USER_C_MODULES=../../../../lib/lvgl/lv_binding_micropython/ports/esp32/partitions-16mb.csv
cd ../../../..

# 5. SZUKANIE WYNIKÓW I SCALANIE
echo "Szukanie plików .bin..."
# Szukamy folderu build wewnątrz ports/esp32
BUILD_PATH=$(find "$PORT_DIR" -name "build-ESP32_GENERIC_S3-SPIRAM_OCTAL" -type d | head -n 1)

esptool.py --chip esp32s3 merge_bin \
    -o FIRMWARE_GOTOWY_NA_0x0.bin \
    --flash_mode dio --flash_size 16MB \
    0x0000 "$BUILD_PATH/bootloader/bootloader.bin" \
    0x8000 "$BUILD_PATH/partition_table/partition-table.bin" \
    0x10000 "$BUILD_PATH/micropython.bin"

echo "SUKCES! Plik FIRMWARE_GOTOWY_NA_0x0.bin gotowy."
