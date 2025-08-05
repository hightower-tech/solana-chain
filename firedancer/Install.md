```
sudo apt update  -y 
sudo apt-get update  -y
sudo apt upgrade -y
sudo apt install -y gcc clang git make net-tools mc curl nano bc jq pkg-config libssl-dev  python3-venv git
```

```
sudo bash -c "cat >/etc/sysctl.d/21-solana-validator.conf <<EOF

# Increase UDP buffer sizes
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 2024000

# Increase number of allowed open file descriptors
fs.nr_open = 2024000
EOF"
```

```
sudo sysctl -p /etc/sysctl.d/21-solana-validator.conf
```

```
echo "Set disable_coredump false" >> /etc/sudo.conf
```

```
sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1024000
root - nofile 1024000
EOF"
```

```
ulimit -n 1024000
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.rmem_default=26214400
sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="default_hugepagesz=1G hugepagesz=1G hugepages=58 hugepagesz=2M hugepages=119"/' /etc/default/grub
sudo update-grub
sudo reboot
```

```
sudo adduser solana
grep -q "^DenyUsers" /etc/ssh/sshd_config && sudo sed -i '/^DenyUsers/ s/$/ solana/' /etc/ssh/sshd_config || echo "DenyUsers solana" | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart ssh
```

```
sudo usermod -aG sudo solana
su - solana
```

```
rustup install 1.81.0
```

```
git clone --recurse-submodules https://github.com/firedancer-io/firedancer.git
cd firedancer
git checkout v0.408.20113
./deps.sh
make -j fdctl solana
```

```
tee /home/solana/config.toml > /dev/null <<EOF
user = "solana"
dynamic_port_range = "8900-9000"

[gossip]
entrypoints = [
  "entrypoint.testnet.solana.com:8001",
  "entrypoint2.testnet.solana.com:8001",
  "entrypoint3.testnet.solana.com:8001",
]

[consensus]
identity_path = "/home/solana/validator-keypair.json"
vote_account_path = "/home/solana/vote-keypair.json"

expected_genesis_hash = "4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY"
#expected_shred_version = 64506

snapshot_fetch = false
genesis_fetch = true
poh_speed_test = false

known_validators = [
    "5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on",
]

[layout]
affinity = "auto"
agave_affinity = "auto"
verify_tile_count = 1
bank_tile_count = 1
shred_tile_count = 1
quic_tile_count = 1
resolv_tile_count = 1
net_tile_count = 1

[ledger]
path = "/home/solana/ledger"
accounts_path = "/home/solana/accounts/"
limit_size = 50_000_000

[snapshots]
incremental_snapshots = true
full_snapshot_interval_slots = 25000
incremental_snapshot_interval_slots = 500
maximum_full_snapshots_to_retain = 1
maximum_incremental_snapshots_to_retain = 2
path = "/home/solana/snapshots/"
incremental_path = "/home/solana/snapshots/"
minimum_snapshot_download_speed = 10485760

[log]
path = "/home/solana/fd.log"
colorize = "auto"
level_logfile = "INFO"
level_stderr = "NOTICE"
level_flush = "WARNING"

[rpc]
port = 8899
full_api = true
private = true
bind_address = "127.0.0.1"


[reporting]
solana_metrics_config = "host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"

[tiles]
[tiles.quic]
max_concurrent_connections = 131072
max_concurrent_handshakes = 4096

[tiles.shred]
max_pending_shred_sets = 512

[tiles.bundle]
    enabled = false
    url = "https://testnet.block-engine.jito.wtf"
    tip_distribution_program_addr = "F2Zu7QZiTYUhPd7u9ukRVwxh7B71oA3NMJcHuCHc29P2"
    tip_payment_program_addr = "GJHtFqM9agxPmkeKjHny6qiRKrXZALvvFGiKf11QE7hy"
    tip_distribution_authority = "GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib"
    commission_bps = 10000
EOF
```
```
sudo tee /etc/systemd/system/solana.service > /dev/null <<EOF
[Unit]
Description=Firedancer Validator Service
After=network.target

[Service]
User=root
ExecStartPre=/home/solana/firedancer/build/native/gcc/bin/fdctl configure init all --config /home/solana/config.toml
ExecStart=/home/solana/firedancer/build/native/gcc/bin/fdctl run --config /home/solana/config.toml
ExecStop=/home/solana/firedancer/build/native/gcc/bin/fdctl stop
Restart=on-failure
LimitNOFILE=100000
LimitNPROC=100000
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
```

```
mkdir snapshots
python3 snapshot-finder.py --min_download_speed 150 --max_snapshot_age 20 --snapshot_path /home/solana/snapshots -r http://api.testnet.solana.com
deactivate
```

```
solana -ut catchup --our-localhost 8899
```

```
sudo systemctl enable solana
```

```
sudo sed -i 's/^genesis_fetch.*/genesis_fetch = false/' /home/solana/config.toml
sudo sed -i 's/^snapshot_fetch.*/snapshot_fetch = true/' /home/solana/config.toml
```
