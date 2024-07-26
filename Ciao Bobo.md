# Ciao Bobo

## Download
Scaricare Arch come illustrato [qui](https://wiki.archlinux.org/title/Installation_guide) e verificare la key gpg e il checksum.

# Begin installation

Impostare il layout della tastiera:
```bash
loadkeys it
```

Ensure EUFI mode:
```bash
cat /sys/firmware/efi/fw_platform_size

# 64 (significa che siamo in efi)
```

Impostare connessione ad internet.

Controllare connessione `ping archlinux.org`

Sincronizzare il fuso orario.
```bash
timedatectl set-timezone "Europe/Rome"
```

# Fromattazione Standard

## Partizionare il disco

Scegliere il disco opportuno con `fdisk -l`.  
Usare il comando `cfdisk <disco>` e scegliere tipologia `gpt`.

Tabella delle partizioni:

| Device    | Mountpoint | Size | Type             | Type id |
| --------- | ---------- | ---- | ---------------- | ------- |
| /dev/sda1 | /boot      | 1G   | EFI System       | 1       |
| /dev/sda2 | /          | ?    | Linux filesystem | 20      |
| /dev/sda3 | /home      | ?    | Linux filesystem | 20      |

## Formattazione del disco

FAT32 per la boot partition:
```bash
mkfs.fat -F 32 /dev/sda1
```

ETX4 per la home e la root partition:

```bash
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
```

## Mount

Montare la partizione EFI
```bash
mount --mkdir /dev/sda1 /mnt/boot
```

Montare la partizione root
```bash
mount /dev/sda2 /mnt
```

Montare la partizione home
```
mount --mkdir /dev/sda3 /mnt/home
```

# Formattazione LVM

## Partizione del disco

Scegliere il disco opportuno con `fdisk -l`.  
Usare il comando `cfdisk <disco>` e scegliere tipologia `gpt`.

Tabella delle partizioni:

| Device    | Mountpoint | Size | Type             | Type id |
| --------- | ---------- | ---- | ---------------- | ------- |
| /dev/sda1 | /boot      | 500M | EFI System       | 1       |
| /dev/sda2 | /          | ?    | Linux LVM        | 30      |

## Formattazione del disco

FAT32 per la boot partition:
```bash
mkfs.fat -F 32 /dev/sda1
```

Formattazione del disco LVM

```bash
pvcreate --dataalignment 1m /dev/sda2
```

### Creazione dei volumi virtuali
```bash
# Crea un volume virtuale di 100G
lvcreate -L 100G volgroup0 -n lv_root
# Crea un volume virtuale con lo spazio rimanente
lvcreate -l 100%FREE voglgroup0 -n lv_home
# Carica il Kernel module per LVM
modprobe dm_mod
# Scansiona i dischi
vgscan
# Applica le modifiche di vgscan
vgchange -ay

# Formattazione dei volumi virtuali
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home
```

## Mount

Montare la partizione EFI
```bash
mount --mkdir /dev/sda1 /mnt/boot
```

Montare il volume virtuale root
```bash
mount --mkdir /dev/volgroup0/lv_root /mnt
```

Montare il volume virtuale home
```bash
mount --mkdir /dev/volgroup0/lv_home /mnt/home
```


# Connessione ad Internet

```bash
# Aprire il pannello per connettersi alla rete
iwctl

# Listare le interfaccie di rete disponibili
station list

# Dopo aver scelto un'interfaccia fare
# la scansione delle reti disponibili
station <interfaccia> scan

# Listare le connessioni trovate
station <interfaccia> get-networks

# Effettuare le connessione
station <interfaccia> connect <ssid>

# Esci
exit
```

# Controllare le connessione ad internet
```bash
ping www.google.com
```


# Generazione di fstab
```bash
mkdir -p /mnt/etc && genfstab -U /mnt >> /mnt/etc/fstab
```


# Install packages

Install base arch distribution:
```bash
pacstrap -i /mnt base
```

# Avvia il base system di Arch
```bash
arch-chroot /mnt
```
--- 
## Sezione necessaria per il setup di LVM

Installazione di LVM (necessario solo se eseguito il setup delle partizioni con LVM)
```bash
pacman -S lvm2
```

Aprire il file mkinitcpio
```bash
nano /etc/mkinitcpio
```

Modificare la sezione `HOOKS` con la seguente, aggiungendo `lvm2`
`HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block lvm2 filesystem fsck)`


Creazione dell'immagine della ram che viene caricata al boot
```bash
mkinitcpio -P
```
---
## Segue il setup normale

Installazione dei kernel: (latest e LTS)

```bash
# Installiamo sia il kernel latest (linux) e i suoi headers
# che il kernel lts in modo che se un update scazza si può
# bootare da lts per fare una recovery del kernel latest

pacman -S linux linux-firmware linux-headers linux-lts linux-lts-headers
```

Installazione di gruppo di dipendenze per sviluppo e ssh:
```bash
pacman -S base-devel openssh
```

Installazione e abilitazione del :sparkles: network manager :sparkles:
e di altri paccheti per la connessione ad internet.
```bash
pacman -S networkmanager wpa_supplicant wireless_tools netctl dialog net-tools

systemctl enable NetworkManager
```

Installazione di un text editor per proseguire con la configurazione:
```bash
pacman -S nano
```

Setup del locale
```bash
nano /etc/locale.gen  # Rimuove il commento davanti ai locale che si intende generare
locale-gen            # Genera i locale decommentati nello step precedente
nano /etc/locale.conf # Impostare il locale scelto
```
Inserire una stringa che indichi il locale con il formato:`LANG=en_US.UTF-8` nel file


Impostazione della password di root:
```bash
passwd
```

Creazione dell'utente:
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

# Installazione di grub
```bash
pacman -S grub efibootmgr dosfstools os-prober mtools
```
dove:
- `grub` e `efibootmgr` sono necessari
- `os-prober` server per rilevare altri sistemi operativi durante la generazione del config di grub
- `dosfstools` e `mtools` servono a qualcosa di ignoto


## Configurazione e installazione di Grub
```bash
# Montare la partizione efi
mount --mkdir /dev/sda1 /boot/efi

# Installazione di grub
grub-install --target=x86_64-efi --bootloader-id=grub --efi-directory=/boot/efi --recheck

# Generazione del config di grub
grub-mkconfig -o /boot/grub/grub.cfg

# Uscire da root
exit

# Smontare tutto
umount -a

# Reboot
reboot
```




# Creazione dello swapfile

Loggare con root e proseguire.

#### Creazione dello swapfile (impostare `<count>` all'ammontare di MB desiderato)
```bash
dd if=/dev/zero of=/swapfile bs=1M count=<count> status=progress
```

#### Impostazione dei permessi opportuni
```bash
chmod 600 /swapfile
```

#### Rendere il file uno swap a tutti gli effetti
```bash
mkswap /swapfile
```

#### Inserire lo swapfile in fstab per auto-mounting
```bash
# Eseguire un backup del fstab generato in precedenza con
cp /etc/fstab /etc/fstab.bak

# Inserire la entry in fstab
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

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

# Post install

## Timezone
```bash
timedatectl set-timezone <timezone> # Imposta il fuso orario e.g. Europe/Rome
systemctl enable systemd-timesyncd  # Keeps the system clock in sync
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
```
# Controllare se il wifi è attivo
nmcli radio wifi

# In caso sia disattivo abilitarlo
nmcli radio wifi on

# Mostrare la lista delle reti
nmcli dev wifi list

# Connettersi ad una rete
nmcli dev wifi connect <ssid> password <password>
```


## Installazione di neofetch
```bash
# Installazione
pacman -Sy neofetch

# Esecuzione
neofetch
```

## Installazione del firmware della CPU
```bash
pacman -S intel-ucode  # o amd-ucode, a seconda
```

## Installazione di xorg
```bash
pacman -S xorg-server
```

## Installazione dei driver NVIDIA
```bash
pacman -S nvidia nvidia-lts
```

## Installazione di Gnome
```bash
pacman -S gnome gnome-tweaks
systemctl enable gdm # abilita il display manager di gnome
```





