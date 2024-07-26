# First steps

## Download
Scaricare Arch come illustrato [qui](https://wiki.archlinux.org/title/Installation_guide) e verificare la key gpg e il checksum.

## Begin installation

Impostare il layout della tastiera:
```bash
loadkeys it
```

Ensure EUFI mode:
```bash
cat /sys/firmware/efi/fw_platform_size
# 64 (significa che siamo in efi)
```

Sincronizzare il fuso orario.
```bash
timedatectl set-timezone "Europe/Rome"
```

## Internet connection

### Setup connection

```bash
# Aprire il pannello per connettersi alla rete
iwctl

# Listare le interfaccie di rete disponibili
station list

# Dopo aver scelto un'interfaccia fare la scansione delle reti disponibili
station <interfaccia> scan

# Listare le connessioni trovate
station <interfaccia> get-networks

# Effettuare le connessione
station <interfaccia> connect <ssid>

# Esci
exit
```

### Check connection
```bash
ping archlinux.org
```

## Disk setup

### Partitioning

Choose the proper disk using `fdisk -l`.
Run `cfdisk <disk>`, choose `gpt` partitioning and create the following partitions:

| Device    | Mountpoint       | Size                | Type             |
|-----------|------------------|---------------------|------------------|
| /dev/sda1 | /efi             | 512M                | EFI System       |
| /dev/sda2 | /boot            | 1G                  | Linux filesystem |
| /dev/sda3 | /                | All remaining space | Linux filesystem |

### Encryption

```bash
# LUKS encryption on the root partition
cryptsetup -y -v luksFormat /dev/sda3

# Open encrypted partition (will be mapped to /dev/mapper/root)
cryptsetup open --type luks /dev/sda3 root
```

### Formatting

```bash
# FAT32 for the efi partition
mkfs.fat -F 32 /dev/sda1

# EXT4 for the boot partition
mkfs.ext4 /dev/sda2

# BTRFS for the root partition
mkfs.btrfs -L arch /dev/mapper/root
```

### BTRFS subvolumes and mounting

```bash
# Mount the root partition
mount /dev/mapper/root /mnt

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
mount -o compress=zstd,subvol=@ /dev/mapper/root /mnt
mount --mkdir -o compress=zstd,subvol=@tmp /dev/mapper/root /mnt/tmp
mount --mkdir -o compress=zstd,subvol=@home /dev/mapper/root /mnt/home
mount --mkdir -o compress=zstd,subvol=@log /dev/mapper/root /mnt/var/log
mount --mkdir -o compress=zstd,subvol=@cache /dev/mapper/root /mnt/var/cache
mount --mkdir -o compress=zstd,subvol=@snapshots /dev/mapper/root /mnt/.snapshots

# Mount the efi partition
mount --mkdir /dev/sda1 /mnt/efi

# Mount the boot partition
mount --mkdir /dev/sda2 /mnt/boot

# Generate fstab
mkdir -p /mnt/etc && genfstab -U /mnt >> /mnt/etc/fstab
```

## Systemd keyboard
```bash
echo 'KEYMAP=it' >> /mnt/etc/vconsole.conf
```

# Main installation

## Base system installation

```bash
pacstrap -i /mnt base

arch-chroot /mnt
```

## Kernel and misc packages installation

```bash
# Install main packages
pacman -S linux-zen         \
          linux-zen-headers \
          linux-firmware    \
          intel-ucode       \
          base-devel        \
          networkmanager    \
          wireless-regdb    \
          neofetch          \
          openssh           \
          nano              \
          wget              \
          git

```

## Enable Network Manager

```bash
systemctl enable NetworkManager
```

## Setup locale(s)

```bash
# Rimuove il commento davanti ai locale che si intende generare
nano /etc/locale.gen

# Genera i locale decommentati nello step precedente
locale-gen
```

## Root password setup

Impostazione della password di root:
```bash
passwd
```

## User creation

```bash
useradd -m -g users -G wheel <utente>
```

dove:

- `-m` genera la user directory
- `-g users` imposta il gruppo base/principale dell'utente a `users`
- `-G wheel` assegna l'utente al gruppo `wheel`

Impostazione della password dell'utente:

```bash
passwd <utente>
```

Permettere agli utenti nel gruppo `wheel` di eseguire comandi con `sudo`:

```bash
EDITOR=nano visudo
```

e decommentare la riga

```bash
# %wheel ALL=(ALL:ALL) ALL
```

## GRUB

### Install required packages

```bash
pacman -S grub grub-btrfs btrfs-progs efibootmgr
```

### Setup LUKS encrypted boot

In `/etc/default/grub`:
- decommentare `GRUB_ENABLE_CRYPTODISK=y`
- aggiungere in `GRUB_CMDLINE_LINUX_DEFAULT` quanto segue `rd.luks.name=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX=name rd.luks.options=discard`.

Lo uuid rappresentato è quello del LUKS superblock (crypto_LUKS) ottenibile tramite `blkid`.
Specificare `rd.luks.name=UUID=<name>` comporta il mounting automatico della partizione su `dev/mapper/<name>`.
N.B. C'è il parametro `root` se vi vuole cambiare mountpoint [wiki](https://wiki.archlinux.org/title/Dm-crypt/System_configuration#root).

In `/etc/mkinitcpio.conf` modificare gli hook come segue: ([wiki](https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system#Configuring_mkinitcpio))

```text
HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
```

### GRUB install and configuration

```bash
# Installazione di grub
grub-install --target=x86_64-efi --bootloader-id=GRUB --efi-directory=/efi (--removable) --recheck

# Generazione del config di grub
grub-mkconfig -o /boot/grub/grub.cfg

# Uscire da root
exit

# Smontare tutto
umount -a

# Reboot
reboot
```

Loggare con root e proseguire.


# Post install

## Swapfile creation

```bash
# Create an untracked file partition
btrfs subvolume create /swap

# Create the swapfile
btrfs filesystem mkswapfile --size <size>g --uuid clear /swap/swapfile

# (is this needed?) swapon /swap/swapfile

# Eseguire un backup del fstab generato in precedenza con
cp /etc/fstab /etc/fstab.bak

# Inserire la entry in fstab
echo '/swap/swapfile none swap defaults 0 0' | tee -a /etc/fstab

# Controllare che sia stata inserita correttamente
cat /etc/fstab

# Montare fstab per controllare che non vengano rilevati errori
mount -a    # Nessun ouput = successo

# Abilitare lo swapfile
swapon -a

# Verificare la presenza dello swap
free -m

# Eliminare il backup
rm /etc/fstab.bak
```

## Timezone e system clock

```bash
# Imposta il fuso orario e.g. Europe/Rome
timedatectl set-timezone <timezone>

# Keeps the system clock in sync
systemctl enable systemd-timesyncd
```

## Hostname e hosts

Impostazione dell'hostname

```bash
hostnamectl hostname <hostname>
```

Impostazione degli hosts

```bash
nano /etc/hosts
```

aggiungere

```
127.0.0.1 localhost
127.0.1.1 <hostname>
```

## Connessione ad internet

```bash
# Controllare se il wifi è attivo
nmcli radio wifi

# In caso sia disattivo abilitarlo
nmcli radio wifi on

# Mostrare la lista delle reti
nmcli dev wifi list

# Connettersi ad una rete
nmcli dev wifi connect <ssid> password <password>
```

## Installazione di xorg

```bash
pacman -S xorg-server
```

## Installazione dei driver NVIDIA

```bash
pacman -S nvidia-dkms
```

## Installazione di Gnome

```bash
pacman -S gnome gnome-tweaks

# Enable gnome display manager
systemctl enable gdm
```

---

# Post-post-setup

- [x] paru (BatchInstall e SkipReview nel config, /etc/makepkg.conf disabilitare build di debug)
- [x/remaining] snapper, snap-pac, snp 
- [x] unneded default gnome apps removal (malcontent)
- [x] pacman parallel downloads (/etc/pacman.conf)
- [ ] plymouth
- [x] reflector
- [ ] alacritty
- [ ] restic
- sdkman
- catppuccin theme (+ cursor)
- grub theme
- papirus-folders-catppuccin
- papirus icon set
- inkscape
- gimp
- virt-manager + config per non chiedere pwd ogni volta
- obsidian
- RStudio
- [x] VSCode
- editor JetBrains
- elixir
- bitwarden
- helvum
- expressvpn
- JetBrains Mono
- SSH agent
- SSH keys
- [x] zsh
- [x] zsh-autosuggestions
- [x] zsh-syntax-highlighting
- [ ] docker (e docker-compose)
- powerlevel10k
- xclip
    - alias pbcopy='xclip -selection clipboard'
    - alias pbpaste='xclip -selection clipboard -o'
- [x] gnome-shell-extensions-dash-to-dock
- [x] ufw
- dns-over-https
- https://github.com/catppuccin/zsh-syntax-highlighting
- papirus-folders -C cat-mocha-mauve -t Papirus-Dark