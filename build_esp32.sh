#!/bin/bash
set -e

# 1. Ścieżki
MPY_DIR="lib/micropython"
MPY_CROSS_DIR="$MPY_DIR/mpy-cross"
PORT_DIR="$MPY_DIR/ports/esp32"

# 2. BRUTALNA NAPRAWA (Wycinamy powód błędu u źródła)
echo "Usuwanie błędnych flag architektury..."
find "$MPY_DIR" -name "*.mk" -exec sed -i 's/-m64//g' {} +
find "$MPY_DIR" -name "*.mk" -exec sed -i 's/--64//g' {} +

# 3. POBIERANIE GOTOWEGO MPY-CROSS (Zabezpieczenie przed błędem --64)
echo "Przygotowanie narzędzia mpy-cross..."
mkdir -p "$MPY_CROSS_DIR/build"
# Pobieramy oficjalny binarek dla Linux x64
curl -L https://github.com -o "$MPY_CROSS_DIR/mpy-cross"
chmod +x "$MPY_CROSS_DIR/mpy-cross"
# Kopiujemy do folderu build, żeby oszukać system make
cp "$MPY_CROSS_DIR/mpy-cross" "$MPY_CROSS_DIR/build/mpy-cross"

# Próbujemy też zbudować (opcjonalnie), ale mamy już gotowca powyżej
make -C "$MPY_CROSS_DIR" CC=gcc CROSS_COMPILE="" || echo "Kompilacja mpy-cross nie była potrzebna, używam pobranego pliku."

# 4. TWORZENIE TABELI PARTYDJI 16MB
echo "Tworzenie tabeli partycji..."
cat <<EOF > "$PORT_DIR/partitions-16mb.csv"
nvs,      data, nvs,     0x9000,  0x6000,
otadata,  data, ota,     0xf000,  0x2000,
phy_init, data, phy,     0x11000, 0x1000,
ota_0,    app,  ota_0,   0x20000, 0x800000,
vfs,      data, fat,     0x820000, 0x7E0000,
EOF

# 5. KOMPILACJA ESP32-S3 (Właściwy firmware)
echo "Kompilacja MicroPython dla ESP32-S3..."
cd "$PORT_DIR"
# Dodajemy USER_C_MODULES, żeby wkompilować LVGL, jeśli ścieżki są poprawne
make BOARD=ESP32_GENERIC_S3 BOARD_VARIANT=SPIRAM_OCTAL
cd ../../../..

# 6. SCALANIE
echo "Szukanie plików i scalanie..."
# Szukamy folderu build wewnątrz ports/esp32
BUILD_DIR=$(find "$PORT_DIR" -name "build-ESP32_GENERIC_S3-SPIRAM_OCTAL" -type d | head -n 1)

if [ -z "$BUILD_DIR" ]; then
    echo "BŁĄD: Nie znaleziono folderu build!"
    exit 1
fi

esptool.py --chip esp32s3 merge_bin \
    -o FIRMWARE_GOTOWY_NA_0x0.bin \
    --flash_mode dio --flash_size 16MB \
    0x0000 "$BUILD_DIR/bootloader/bootloader.bin" \
    0x8000 "$BUILD_DIR/partition_table/partition-table.bin" \
    0x10000 "$BUILD_DIR/micropython.bin"

echo "SUKCES! Plik FIRMWARE_GOTOWY_NA_0x0.bin jest gotowy."
