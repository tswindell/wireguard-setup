# Setting up Wireguard on Raspberry Pi4 Debian "buster"

## Wireguard Installation

#### Add the unstable repository to apt sources.list.d
```
echo "deb http://deb.debian.org/debian/ unstable main" | sudo tee --append /etc/apt/sources.list.d/unstable.list
```

#### Add key to apt key ring for repository.
```
wget -O - https://ftp-master.debian.org/keys/archive-key-$(lsb_release -sr).asc | sudo apt-key add -
```

#### Update apt policy settings to only install unstable versions if unavailable from stable sources. (?)
```
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 150\n' | sudo tee --append /etc/apt/preferences.d/limit-unstable
```

#### Update apt cache, install kernel headers and wireguard.
```
sudo apt update
sudo apt install -y raspberrypi-kernel-headers
sudo apt install -y wireguard
```

## Generate Server and Client Keys
```
./wg_genkeys.sh my_server
./wg_genkeys.sh my_client
```

## Generate Server Configuration
```
cat > server.conf << EOF
[Interface]
Address = 10.0.0.1/32
ListenPort = 54321
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PrivateKey = $(cat ./my_server.key)
SaveConfig = true

[Peer]
PublicKey = $(cat ./my_client.pub)
AllowedIPs = 10.0.0.0/24
EOF
```

## Generate Client Configuration
```
cat > client.conf << EOF
[Interface]
Address = 10.0.0.2/32
PrivateKey = $(cat ./my_client.key)

[Peer]
Endpoint=<SERVER_IP>:54321
PublicKey=$(cat ./my_server.pub)
EOF
```

## Bring-Up Host Connection
```
wg-quick up ./server.conf
```

Test connectivity with pinging 10.0.0.1 from client, and 10.0.0.5 from host, etc.

## Make Host Connection active on start.

```
sudo cp ./server.conf /etc/wireguard/wg0.conf
sudo chmod og-rwx /etc/wireguard/wg0.conf
sudo systemctl enable wg-quick@wg0
```