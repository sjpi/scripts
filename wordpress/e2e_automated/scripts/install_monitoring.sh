#!/bin/bash

# Initialize log file
LOG_FILE="monitoring_install.log"
echo "Monitoring Installation Log - $(date)" > $LOG_FILE
echo "===============================" >> $LOG_FILE

# Function to log and execute commands
run_command() {
    echo "Executing: $@" | tee -a $LOG_FILE
    if "$@" >> $LOG_FILE 2>&1; then
        echo "Success: $@" | tee -a $LOG_FILE
    else
        echo "Error: $@" | tee -a $LOG_FILE
        exit 1
    fi
}

# Ask if monitoring should be installed
echo -n "Do you want to install Prometheus and Grafana monitoring? (y/n): "
read -r INSTALL_MONITORING

if [[ ! "$INSTALL_MONITORING" =~ ^[Yy]$ ]]; then
    echo "Monitoring installation skipped." | tee -a $LOG_FILE
    exit 0
fi

# Install dependencies
echo "Installing dependencies..." | tee -a $LOG_FILE
run_command sudo apt-get update
run_command sudo apt-get install -y apt-transport-https software-properties-common wget curl gnupg2

# Add Grafana repository
echo "Adding Grafana repository..." | tee -a $LOG_FILE
run_command wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

# Install Prometheus
echo "Installing Prometheus..." | tee -a $LOG_FILE
PROMETHEUS_VERSION="2.45.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo mkdir -p /etc/prometheus
sudo mv prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus.yml /etc/prometheus/
sudo mkdir -p /var/lib/prometheus
rm -rf prometheus-${PROMETHEUS_VERSION}.linux-amd64*

# Create Prometheus user
sudo useradd --no-create-home --shell /bin/false prometheus
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Configure Prometheus
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Create Prometheus systemd service
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Install Node Exporter
echo "Installing Node Exporter..." | tee -a $LOG_FILE
NODE_EXPORTER_VERSION="1.6.1"
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64*

# Create Node Exporter systemd service
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Install Grafana
echo "Installing Grafana..." | tee -a $LOG_FILE
run_command sudo apt-get update
run_command sudo apt-get install -y grafana

# Configure alert rules
echo "Configuring alert rules..." | tee -a $LOG_FILE
sudo mkdir -p /etc/prometheus
cat <<EOF | sudo tee /etc/prometheus/alert.rules.yml
groups:
- name: instance
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Instance {{ \$labels.instance }} down"
      description: "{{ \$labels.instance }} of job {{ \$labels.job }} has been down for more than 5 minutes."
EOF

# Start and enable services
echo "Starting services..." | tee -a $LOG_FILE
sudo systemctl daemon-reload
run_command sudo systemctl enable prometheus
run_command sudo systemctl start prometheus
run_command sudo systemctl enable node_exporter
run_command sudo systemctl start node_exporter
run_command sudo systemctl enable grafana-server
run_command sudo systemctl start grafana-server

# Wait for services to start
echo "Waiting for services to start..." | tee -a $LOG_FILE
sleep 10

# Configure Grafana datasource
echo "Configuring Grafana datasource..." | tee -a $LOG_FILE
curl -X POST -H "Content-Type: application/json" -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "basicAuth":false
}' http://admin:admin@localhost:3000/api/datasources

# Create basic dashboard
echo "Creating dashboard..." | tee -a $LOG_FILE
curl -X POST -H "Content-Type: application/json" -d '{
    "dashboard": {
        "id": null,
        "title": "System Monitoring",
        "tags": [ "templated" ],
        "timezone": "browser",
        "panels": [
            {
                "type": "graph",
                "title": "CPU Usage",
                "gridPos": { "x": 0, "y": 0, "w": 12, "h": 8 }
            },
            {
                "type": "graph",
                "title": "Memory Usage",
                "gridPos": { "x": 0, "y": 8, "w": 12, "h": 8 }
            }
        ]
    },
    "overwrite": true
}' http://admin:admin@localhost:3000/api/dashboards/db

echo "Monitoring setup complete!" | tee -a $LOG_FILE
echo "Access Grafana at http://your-domain:3000" | tee -a $LOG_FILE
echo "Default credentials: admin/admin" | tee -a $LOG_FILE
echo "Detailed log available at $LOG_FILE" | tee -a $LOG_FILE
