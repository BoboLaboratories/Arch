#!/bin/sh

. /install/system.sh
. /install/utils.sh

input_password luks "Enter LUKS encryption password: "
input_password root "Enter root password: "
input_password user "Enter user password: "

# Disk partitioning
parted --script "$DISK_DEVICE"                              \
  mklabel gpt                                               \
  mkpart "$ESP_PART_LABEL" fat32 1MiB "$ESP_PART_SIZE"      \
  set 1 boot on                                             \
  mkpart "$PRIMARY_PART_LABEL" btrfs "$ESP_PART_SIZE" 100%

DISK_ESP_PARTITION=$(get_partition "$ESP_PART_LABEL")
DISK_PRIMARY_PARTITION=$(get_partition "$PRIMARY_PART_LABEL")

# LUKS encryption on the root partition
cryptsetup -y -v --batch-mode luksFormat "$DISK_PRIMARY_PARTITION" --key-file=/install/luks-password

# Open encrypted partition (will be mapped to /dev/mapper/..)
cryptsetup open --type luks "$DISK_PRIMARY_PARTITION" "$DISK_CRYPT_DEVICE" --key-file=/install/luks-password

# Format EFI boot partition
mkfs.fat -F32 -n "$ESP_FS_LABEL" "$DISK_ESP_PARTITION"

# Format primary partition
mkfs.btrfs -L "$PRIMARY_FS_LABEL" "/dev/mapper/$DISK_CRYPT_DEVICE"

# Mount the root partition
mount "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt

# Create the BTRFS subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@snapshots

# Unmount everything
umount -a

# Remount all the BTRFS subvolumes with proper flags
mount         -o compress=zstd,subvol=@          "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt
mount --mkdir -o compress=zstd,subvol=@tmp       "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt/tmp
mount --mkdir -o compress=zstd,subvol=@home      "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt/home
mount --mkdir -o compress=zstd,subvol=@log       "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt/var/log
mount --mkdir -o compress=zstd,subvol=@cache     "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt/var/cache
mount --mkdir -o compress=zstd,subvol=@snapshots "/dev/mapper/$DISK_CRYPT_DEVICE" /mnt/.snapshots

# Mount the efi boot partition
mount --mkdir "$DISK_ESP_PARTITION" /mnt/boot

# Generate fstab
mkdir -p /mnt/etc && genfstab -U /mnt >> /mnt/etc/fstab

# Set systemd keyboard
echo 'KEYMAP=it' >> /mnt/etc/vconsole.conf

# Install base system.
# When prompted, choose iptables-nft.
pacstrap -i /mnt base

cp -r /install /mnt/install

# Chroot
arch-chroot /mnt /bin/bash /install/post-chroot.sh
