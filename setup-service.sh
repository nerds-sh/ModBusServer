# Check if the service unit file already exists
if [ -f "$SERVICE_UNIT_FILE" ]; then
    echo "Service unit file already exists. Updating the file..."
    sudo systemctl stop escuplast-service
    sudo systemctl disable escuplast-service
    sudo rm "$SERVICE_UNIT_FILE"
    echo "$SERVICE_UNIT" | sudo tee "$SERVICE_UNIT_FILE"
    sudo systemctl daemon-reload
    sudo systemctl enable escuplast-service
    sudo systemctl start escuplast-service
    echo "Service updated and restarted successfully."
else
    # Create the service unit file
    echo "$SERVICE_UNIT" | sudo tee "$SERVICE_UNIT_FILE"

    # Reload systemd
    sudo systemctl daemon-reload

    # Enable and start the service
    sudo systemctl enable escuplast-service
    sudo systemctl start escuplast-service
fi

# Check the service status
sudo systemctl status escuplast-service --no-pager
