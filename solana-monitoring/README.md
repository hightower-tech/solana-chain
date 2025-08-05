# Solana monitoring #


## Introduction

<img src="https://i.imgur.com/KmrCeax.jpeg" style="width:250px;"/><img src="https://i.imgur.com/e6PBegW.jpeg" style="width:274px;"/>

This code suite helps you monitor your Solana validator using Prometheus and Grafana.  
You can visually track your validator's performance and configure alerts when metrics deviate from specified thresholds. We used as a basis the code from the great [Stakeconomy](https://github.com/stakeconomy/solanamonitoring). Thank them very much for that!

## How It Works
In short, here’s how everything works: `solana-monitor` is periodically triggered by a cron job and uses the standard Solana CLI to collect the necessary data. The collected data is saved to a file in Prometheus metrics format.

To import the data into Prometheus, Node Exporter is used with its **textfile collector**, which scans a specified directory for metric files. `solana-monitor` simply overwrites the metrics file each time — this is expected behavior and works correctly with the textfile collector.

From there, everything proceeds as usual: Prometheus collects and stores the metrics, Grafana is used for visualization, and if desired, alerts can be configured via Alertmanager based on specified conditions.

## Requirements
- Grafana server  
- Prometheus  
- Node Exporter  

## Installation & Setup

1. Create a file for Prometheus metrics and set the correct permissions so the Node Exporter user can read it.  
In this example, we use the `node_exporter` user. You may choose any directory or filename.

```bash
mkdir -p /var/lib/node_exporter
touch /var/lib/node_exporter/solana_validator_metrics.prom
chown node_exporter:node_exporter -R /var/lib/node_exporter
```

2. Clone the repository and make the scripts executable.

```bash
git clone https://github.com/htwtech/solana-monitoring.git
cd solana-monitoring
chmod +x *.sh
```

3. Edit `solana-monitor.sh` and set the required configuration. You can use either the key file or the corresponding public key.
Required parameters:
- `identityPubkey` — the public identity key of your validator  
- `votePubkey` — the vote account public key of your validator
- `identityPubkeyFile` — the public identity key file  
- `votePubkeyFile` — the vote account public key file   
- `binDir` — the path to the solana binary file 
- `metricsFile` — the full path to the Prometheus metrics file, including the filename  


```bash
nano solana-monitor.sh
```

4. Run `solana-monitor.sh` and check the output and metrics file.  
If everything is working, there should be no output to the console, and the `metricsFile` will contain metrics.  
If not, check the settings in `solana-monitor.sh` and ouput.

5. Create a cron job for periodic data collection.  
**Note:** Make sure your user has permission to execute `solana-monitor.sh`.

```bash
(crontab -l 2>/dev/null; echo "* * * * * /full/path/to/solana-monitoring/solana-monitor.sh") | crontab -
```

6. Make sure the `metricsFile` is being updated periodically.  
If not, re-run `solana-monitor.sh` manually and check your cron settings. 

7. Since node exporter does not reset the metrics file after it is read, you can use this script to control its update. This script monitors the update of the metrics file and if it has not been updated within a specified interval, the script resets it.  
Add it to the cron 

```bash
(crontab -l 2>/dev/null; echo "* * * * * /full/path/to/solana-monitoring/watchdog-solana-monitor.sh") | crontab -
```

8. Add `--collector.textfile.directory=/path/to/your/node_exporter_metrics/dir/` to the Node Exporter service file, or create a new one. In the example below, we enable only the necessary Node Exporter collectors:

```bash
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter \
  --collector.disable-defaults \
  --collector.loadavg \
  --collector.pressure \
  --collector.uname \
  --collector.stat \
  --collector.vmstat \
  --collector.cpu \
  --collector.meminfo \
  --collector.netdev \
  --collector.netclass \
  --collector.netstat \
  --collector.diskstats \
  --collector.filefd \
  --collector.filesystem \
  --collector.time \
  --collector.textfile \
  --collector.textfile.directory=/var/lib/node_exporter
[Install]
WantedBy=default.target
EOF
```

9. **Reload the Node Exporter service and check the logs:**

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl restart node_exporter
journalctl -u node_exporter -f -o cat
```

## Prometheus & Grafana
If everything has been set up correctly and there are no errors, add your target to Prometheus, import the Grafana dashboard, and verify that the metrics are being displayed. The dashboard uses standard `instance` and `job` labels.  
Prometheus should include the following metrics: `solana_validator_*`:
- solana_validator_status
- solana_validator_rootSlot
- solana_validator_lastVote
- solana_validator_leaderSlots
- solana_validator_skippedSlots
- solana_validator_pctSkipped
- solana_validator_pctTotSkipped
- solana_validator_pctSkippedDelta
- solana_validator_pctTotDelinquent
- solana_validator_version
- solana_validator_pctNewerVersions
- solana_validator_commission
- solana_validator_activatedStake
- solana_validator_credits
- solana_validator_epochCredits
- solana_validator_validatorBalance
- solana_validator_validatorVoteBalance
- solana_validator_epoch
- solana_validator_pctEpochElapsed
- solana_validator_slotIndex
- solana_validator_epochEnds
- solana_validator_tps
- solana_validator_rootDistance
- solana_validator_voteDistance
- solana_validator_timeStamp
  
To provide a full view of the system's performance, we also export standard node metrics, including CPU load, memory usage, disk utilization, disk IOPS, and network throughput.  
