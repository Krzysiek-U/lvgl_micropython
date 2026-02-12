#!/bin/bash
set -e

# 1. Ścieżki - absolutne
ROOT_DIR=$(pwd)
MPY_DIR="$ROOT_DIR/lib/micropython"
MPY_CROSS_DIR="$MPY_DIR/mpy-cross"
PORT_DIR="$MPY_DIR/ports/esp32"
LV_MOD="$ROOT_DIR/lib/lvgl/lv_binding_micropython"

# 2. NAPRAWA FLAG (Działa, nie ruszamy)
echo "Naprawa flag architektury..."
find "$MPY_DIR" -name "*.mk" -exec sed -i 's/-m64//g' {} +
find "$MPY_DIR" -name "*.mk" -exec sed -i 's/--64//g' {} +

# 3. PRZYGOTOWANIE MPY-CROSS
echo "Przygotowanie mpy-cross..."
mkdir -p "$MPY_CROSS_DIR/build"
curl -L https://github.com -o "$MPY_CROSS_DIR/mpy-cross"
chmod +x "$MPY_CROSS_DIR/mpy-cross"
cp "$MPY_CROSS_DIR/mpy-cross" "$MPY_CROSS_DIR/build/mpy-cross"

# 4. TWORZENIE TABELI PARTYDJI
echo "Tworzenie tabeli partycji..."
cat <<EOF > "$PORT_DIR/partitions-16mb.csv"
nvs,      data, nvs,     0x9000,  0x6000,
otadata,  data, ota,     0xf000,  0x2000,
phy_init, data, phy,     0x11000, 0x1000,
ota_0,    app,  ota_0,   0x20000, 0x800000,
vfs,      data, fat,     0x820000, 0x7E0000,
EOF

# 5. KLUCZOWA NAPRAWA PYTHONA DLA ESP-IDF
echo "Naprawa pakietów Pythona dla ESP-IDF..."
# Instalujemy setuptools, bo bez nich idf.py rzuca błędem pkg_resources
pip install --upgrade setuptools wheel

# 6. KOMPILACJA ESP32-S3
echo "Kompilacja MicroPython..."
cd "$PORT_DIR"

# Używamy ścieżki do folderu cmake, co jest standardem
make BOARD=ESP32_GENERIC_S3 \
     BOARD_VARIANT=SPIRAM_OCTAL \
     USER_C_MODULES="$LV_MOD/ports/esp32/cmake" \
     V=1

cd "$ROOT_DIR"

# 7. SCALANIE
echo "Sklejanie firmware..."
BUILD_DIR=$(find "$PORT_DIR" -maxdepth 1 -name "build-ESP32_GENERIC_S3-SPIRAM_OCTAL" -type d | head -n 1)

esptool.py --chip esp32s3 merge_bin \
    -o FIRMWARE_GOTOWY_NA_0x0.bin \
    --flash_mode dio --flash_size 16MB \
    0x0000 "$BUILD_DIR/bootloader/bootloader.bin" \
    0x8000 "$BUILD_DIR/partition_table/partition-table.bin" \
    0x10000 "$BUILD_DIR/micropython.bin"

echo "SUKCES! Plik FIRMWARE_GOTOWY_NA_0x0.bin gotowy."
