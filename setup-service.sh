#!/bin/bash

# Define the service unit file content with absolute paths
SERVICE_UNIT="[Unit]
Description=escuplast-service
After=network.target

[Service]
ExecStart=/usr/local/bin/python3.9 /home/escuplast/ModbusServer/server.py
WorkingDirectory=/home/escuplast/ModbusServer
Restart=always
User=escuplast

[Install]
WantedBy=multi-user.target"

# Define the service unit file path
SERVICE_UNIT_FILE="/etc/systemd/system/escuplast-service.service"

# Ensure the ModbusServer directory exists and set the correct ownership
if [ ! -d "/home/escuplast/ModbusServer" ]; then
    sudo mkdir -p /home/escuplast/ModbusServer
fi
sudo chown -R escuplast:escuplast /home/escuplast/ModbusServer

# Check if the server script exists
if [ ! -f "/home/escuplast/ModbusServer/server.py" ]; then
    echo "Server script not found in /home/escuplast/ModbusServer. Please ensure server.py is in place."
    exit 1
fi

# Set permissions for the server script
sudo chmod +x /home/escuplast/ModbusServer/server.py

# Check if the service unit file already exists
if [ -f "$SERVICE_UNIT_FILE" ]; then
    echo "Service unit file already exists. Updating the file..."
    # Stop and disable the service before updating the file
    sudo systemctl stop escuplast-service
    sudo systemctl disable escuplast-service
    # Remove the existing service file
    sudo rm "$SERVICE_UNIT_FILE"
    # Create the service unit file with new configuration
    echo "$SERVICE_UNIT" | sudo tee "$SERVICE_UNIT_FILE"
    # Reload systemd to recognize the new/updated service
    sudo systemctl daemon-reload
    # Enable the service to start on boot and start it immediately
    sudo systemctl enable escuplast-service
    sudo systemctl start escuplast-service
    echo "Service updated and restarted successfully."
else
    # Service file does not exist, create it with the specified configuration
    echo "$SERVICE_UNIT" | sudo tee "$SERVICE_UNIT_FILE"
    # Reload systemd to recognize the new service
    sudo systemctl daemon-reload
    # Enable the service to start on boot and start it immediately
    sudo systemctl enable escuplast-service
    sudo systemctl start escuplast-service
    echo "Service created and started successfully."
fi

# Optionally, check the service status
echo "Checking the service status..."
sudo systemctl status escuplast-service --no-pager
