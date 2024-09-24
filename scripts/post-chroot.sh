#!/bin/sh

. /install/system.sh

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

# Verifica se il comando è stato eseguito con successo
# TODO
if [ $? -eq 0 ]; then
    echo "Password aggiornata con successo per l'utente $username."
else
    echo "Errore nell'aggiornamento della password."
fi
