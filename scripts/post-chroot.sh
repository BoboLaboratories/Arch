#!/bin/sh

source /install/system.sh

sed -i '0,/#ParallelDownloads/s//ParallelDownloads/' /etc/pacman.conf
sed -i '0,/#Color/s//Color/' /etc/pacman.conf

# Install main packages
pacman -S linux-zen         \
          linux-zen-headers \
          linux-firmware    \
          intel-ucode       \
          base-devel        \
          networkmanager    \
          wireless-regdb    \
          btrfs-progs       \
          fastfetch         \
          openssh           \
          nano              \
          wget              \
          tree              \
          git

systemctl enable NetworkManager

for LOCALE in "${LOCALES[@]}"; do
  sed -i "0,/#$LOCALE.UTF-8/s//$LOCALE.UTF-8/" /etc/locale.gen
done

locale-gen

useradd -m -g users -G wheel "$USER"

PASSWORD=$(cat /install/user-password)
echo "$USER:$PASSWORD" | chpasswd

echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

sed -i "0,/^HOOKS=([^)]*)/s//HOOKS=($MKINITCPIO_HOOKS)/" /etc/mkinitcpio.conf

UUID_LINE=$(blkid "$DISK_PRIMARY_PARTITION")
UUID=$(expr "$UUID_LINE" : '[^ ]* UUID="\([^"]*\).*"')
OPTIONS="rd.luks.name=$UUID=$DISK_CRYPT_DEVICE"
OPTIONS="$OPTIONS root=/dev/mapper/$DISK_CRYPT_DEVICE"
OPTIONS="$OPTIONS rd.luks.options=discard"
for PARAMETER in "${KERNEL_PARAMS[@]}"; do
  OPTIONS="$OPTIONS $PARAMETER"
done

btrfs subvolume set-default 256 /

bootctl install

echo "default      arch.conf"           >  /boot/loader/loader.conf
echo "timeout      $BOOT_TIMEOUT"       >> /boot/loader/loader.conf
echo "console-mode max"                 >> /boot/loader/loader.conf
echo "editor       no"                  >> /boot/loader/loader.conf

echo "title   $BOOT_TITLE"              >  /boot/loader/entries/arch.conf
echo "linux   /vmlinuz-linux-zen"       >> /boot/loader/entries/arch.conf
echo "initrd  /initramfs-linux-zen.img" >> /boot/loader/entries/arch.conf
echo "options $OPTIONS"                 >> /boot/loader/entries/arch.conf

systemctl enable systemd-boot-update.service

mkinitcpio -P

bootctl update

rm -r /install