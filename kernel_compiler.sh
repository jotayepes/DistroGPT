#!/bin/bash
set -e

if [ $# -eq 0 ]; then
    echo "No se proporcionó un archivo de configuración del kernel. Usando la configuración del kernel actual."
    CONFIG_FILE="/boot/config-$(uname -r)"
else
    CONFIG_FILE=$1
fi

sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev || exit 1
sudo apt-get install gcc libncurses5-dev || exit 1
sudo apt install build-essential dwarves python3 libncurses-dev flex bison libssl-dev bc libelf-dev zstd gnupg2 wget -y || exit 1

echo "Obteniendo la lista de kernels disponibles..."
wget -qO- https://www.kernel.org/ | grep -oP '(?<=href=")https://cdn.kernel.org/pub/linux/kernel/v[0-9]+\.x/linux-[\d.]+\.tar\.xz(?=")' > kernel_list.txt

echo "Kernels disponibles:"
cat kernel_list.txt

read -p "Introduce la URL del kernel que deseas instalar (copiar y pegar de la lista anterior): " KERNEL_URL

wget $KERNEL_URL || exit 1
KERNEL_FILE=$(basename $KERNEL_URL)
KERNEL_DIR=$(basename $KERNEL_URL .tar.xz)

tar -xf $KERNEL_FILE || exit 1
cd $KERNEL_DIR || exit 1

if [ ! -f "$CONFIG_FILE" ]; then
    echo "El archivo de configuración del kernel no existe: $CONFIG_FILE"
    exit 1
fi

cp "$CONFIG_FILE" .config || exit 1
scripts/config --disable SYSTEM_REVOCATION_KEYS || exit 1
make oldconfig || exit 1
make localmodconfig || exit 1
make -j$(nproc) bzImage || exit 1
make -j$(nproc) modules || exit 1

sudo make modules_install || exit 1
sudo make install || exit 1

sudo update-grub || exit 1
