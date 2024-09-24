#!/bin/sh

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