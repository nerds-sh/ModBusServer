#!/bin/bash

# Define the service unit file content
SERVICE_UNIT="[Unit]
Description=escuplast-service
After=network.target

[Service]
ExecStart=python3.9 ~/ModbusServer/server.py
WorkingDirectory=~/ModbusServer
Restart=always
User=escuplast

[Install]
WantedBy=multi-user.target"

# Define the service unit file path
SERVICE_UNIT_FILE="/etc/systemd/system/escuplast-service.service"

# Check if the service unit file already exists
if [ -f "$SERVICE_UNIT_FILE" ]; then
    echo "Service unit file already exists. Please remove it manually if needed."
    exit 1
fi

# Create the service unit file
echo "$SERVICE_UNIT" | sudo tee "$SERVICE_UNIT_FILE"

# Reload systemd
sudo systemctl daemon-reload

# Enable and start the service
sudo systemctl enable escuplast-service
sudo systemctl start escuplast-service

# Check the service status
sudo systemctl status escuplast-service
