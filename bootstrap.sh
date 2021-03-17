#!/usr/bin/env bash
sudo apt-get update

# create downloads directory so that we can download all the packages
# which are required during provisioning process
mkdir /home/vagrant/Downloads
cd /home/vagrant/Downloads

# download prometheus installation files
wget --quiet https://github.com/prometheus/prometheus/releases/download/v2.25.2/prometheus-2.25.2.linux-amd64.tar.gz

# create directory for prometheus installation files
# so that we can extrac all the files into it
mkdir -p /home/vagrant/Prometheus/server
cd /home/vagrant/Prometheus/server

# Extract files
tar -xvzf /home/vagrant/Downloads/prometheus-2.25.2.linux-amd64.tar.gz

cd prometheus-2.25.2.linux-amd64

# check prometheus version
./prometheus --version

# create directory for node_exporter which can be used to send ubuntu metrics to the prometheus server
mkdir -p /home/vagrant/Prometheus/node_exporter
cd /home/vagrant/Prometheus/node_exporter

# download node_exporter
wget --quiet https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz -O /home/vagrant/Downloads/node_exporter-1.1.2.linux-amd64.tar.gz

# extract node_exporter
tar -xvzf /home/vagrant/Downloads/node_exporter-1.1.2.linux-amd64.tar.gz

# create a symbolic link of node_exporter
sudo ln -s /home/vagrant/Prometheus/node_exporter/node_exporter-1.1.2.linux-amd64/node_exporter /usr/local/bin

cat <<EOF > /lib/systemd/system/node_exporter.service
[Unit]
Description=node_exporter

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo cp /lib/systemd/system/node_exporter.service /etc/systemd/system/node_exporter.service
sudo chmod 644 /etc/systemd/system/node_exporter.service
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

cd /home/vagrant/Prometheus/server/prometheus-2.25.2.linux-amd64/

# edit prometheus configuration file which will pull metrics from node_exporter
# every 15 seconds time interval
cat <<EOF > prometheus.yml
global:
  scrape_interval:     15s # By default, scrape targets every 15 seconds.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
    monitor: 'codelab-monitor'

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label 'job=<job_name>' to any timeseries scraped from this config.
  - job_name: 'node-prometheus'

    static_configs:
      - targets: ['localhost:9100']
EOF

# start prometheus
nohup ./prometheus > prometheus.log 2>&1 &

# download grafana
wget --quiet https://dl.grafana.com/oss/release/grafana_6.7.0_amd64.deb -O /home/vagrant/Downloads/grafana_6.7.0_amd64.deb

sudo apt-get install -y adduser libfontconfig

# install grafana 
sudo dpkg -i /home/vagrant/Downloads/grafana_6.7.0_amd64.deb

# start grafana service 
sudo service grafana-server start

# run on every boot
sudo update-rc.d grafana-server defaults
