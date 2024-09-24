```bash
loadkeys it

cat /sys/firmware/efi/fw_platform_size
```

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

ping archlinux.org
```

```bash
# Set a root password
passwd

# Enable SSH root login.
# Ensure `PermitRootLogin` is uncommented and set to `yes`.
# i.e. PermitRootLogin yes
nano /etc/ssh/sshd_config

# Get the IP
ip a
```