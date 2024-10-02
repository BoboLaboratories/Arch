#!/bin/sh

source /install/utils.sh

DISK_DEVICE=/dev/nvme0n1

ESP_PART_SIZE=1GiB
ESP_PART_LABEL=ESP
# Maximum of 11 characters, uppercase characters
ESP_FS_LABEL="${ESP_PART_LABEL}_FS"

PRIMARY_PART_LABEL=primary
PRIMARY_FS_LABEL="${PRIMARY_PART_LABEL}_FS"

# Without the /dev/mapper/ part
DISK_CRYPT_DEVICE=cryptroot

LOCALES=("en_US" "en_GB")

USER=glowy

BOOT_TIMEOUT=0
BOOT_TITLE="Arch Linux"

# LUKS parameters will be set automatically
KERNEL_PARAMS=(
  "loglevel=3"
  "splash"
  "quiet"
)

# Do not alter below this point

DISK_ESP_PARTITION=$(get_partition "$ESP_PART_LABEL")
DISK_PRIMARY_PARTITION=$(get_partition "$PRIMARY_PART_LABEL")

# HOOKS=(base systemd plymouth autodetect microcode modconf keyboard sd-vconsole sd-encrypt block filesystems fsck)

MKINITCPIO_HOOKS="base"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS systemd"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS autodetect"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS microcode"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS modconf"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS kms"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS keyboard"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS sd-vconsole"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS block"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS sd-encrypt"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS filesystems"
MKINITCPIO_HOOKS="$MKINITCPIO_HOOKS fsck"