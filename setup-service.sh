#!/bin/bash

# Define the service unit file content with absolute paths
SERVICE_UNIT="[Unit]
Description=escuplast-service
After=network.target

[Service]
ExecStart=/usr/bin/python3.9 /home/escuplast/ModbusServer/server.py
WorkingDirectory=/home/escuplast/ModbusServer
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

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable escuplast-service

# Start the service
sudo systemctl start escuplast-service

# Optionally, check the service status to ensure it's running as expected
echo "Checking the service status..."
sudo systemctl status escuplast-service --no-pager
