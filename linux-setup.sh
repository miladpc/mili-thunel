#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root or with sudo${NC}"
  exit 1
fi

echo -e "${BLUE}=== Mili-Tunnel Linux Server Setup ===${NC}"
echo -e "${YELLOW}This script will set up Mili-Tunnel on your Linux server${NC}"
echo

# Create working directory
INSTALL_DIR="/opt/mili-tunnel"
echo -e "Creating installation directory at ${GREEN}$INSTALL_DIR${NC}..."
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Check if Go is installed
echo -e "${BLUE}Checking if Go is installed...${NC}"
if ! command -v go &> /dev/null; then
    echo -e "${YELLOW}Go is not installed. Installing...${NC}"
    apt update
    apt install -y golang-go
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to install Go. Please install it manually.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Go installed successfully!${NC}"
else
    echo -e "${GREEN}Go is already installed.${NC}"
fi

# Get Go version
GO_VERSION=$(go version)
echo -e "Go version: ${GREEN}$GO_VERSION${NC}"

# Clone repository or download files
echo -e "${BLUE}Setting up Mili-Tunnel...${NC}"
if [ -f "main.go" ] && [ -f "go.mod" ]; then
    echo -e "${GREEN}Mili-Tunnel files already exist. Skipping download.${NC}"
else
    echo -e "${YELLOW}Downloading Mili-Tunnel source code...${NC}"
    
    # Copy files from the current directory if we're running from the project directory
    if [ -f "../main.go" ] && [ -f "../go.mod" ]; then
        cp -r ../* .
        echo -e "${GREEN}Files copied from parent directory.${NC}"
    else
        # Otherwise try to clone from GitHub (assume it exists)
        echo -e "${YELLOW}Attempting to clone from GitHub...${NC}"
        apt install -y git
        git clone https://github.com/miladpc/mili-tunnel .
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to clone repository. Please download the files manually.${NC}"
            exit 1
        fi
    fi
fi

# Build the application
echo -e "${BLUE}Building Mili-Tunnel...${NC}"
go mod download
go build -o mili-tunnel
if [ $? -ne 0 ]; then
    echo -e "${RED}Build failed. Please check the error messages above.${NC}"
    exit 1
fi
echo -e "${GREEN}Build successful!${NC}"

# Create systemd service
echo -e "${BLUE}Creating systemd service...${NC}"
read -p "Do you want to run as server or client? [server/client]: " MODE
MODE=${MODE:-server}

if [ "$MODE" = "server" ]; then
    read -p "Server port [8443]: " PORT
    PORT=${PORT:-8443}
    read -p "Remote address to forward to [127.0.0.1:80]: " REMOTE
    REMOTE=${REMOTE:-127.0.0.1:80}
    
    SERVICE_CONTENT="[Unit]
Description=Mili Tunnel Server
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/mili-tunnel --server --server-addr 0.0.0.0:$PORT --remote $REMOTE
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target"

    # Open firewall port
    echo -e "${BLUE}Opening firewall port $PORT...${NC}"
    if command -v ufw &> /dev/null; then
        ufw allow $PORT/tcp
        echo -e "${GREEN}Port $PORT opened in UFW firewall.${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$PORT/tcp
        firewall-cmd --reload
        echo -e "${GREEN}Port $PORT opened in FirewallD.${NC}"
    else
        echo -e "${YELLOW}No supported firewall detected. Please open port $PORT manually if needed.${NC}"
    fi
else
    read -p "Local address to listen on [127.0.0.1:8080]: " LOCAL
    LOCAL=${LOCAL:-127.0.0.1:8080}
    read -p "Remote address to forward to [127.0.0.1:9090]: " REMOTE
    REMOTE=${REMOTE:-127.0.0.1:9090}
    read -p "Tunnel server address [your-server-ip:8443]: " SERVER
    SERVER=${SERVER:-your-server-ip:8443}
    
    SERVICE_CONTENT="[Unit]
Description=Mili Tunnel Client
After=network.target

[Service]
Type=simple
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/mili-tunnel --local $LOCAL --remote $REMOTE --server-addr $SERVER
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target"
fi

# Write systemd service file
echo "$SERVICE_CONTENT" > /etc/systemd/system/mili-tunnel.service
chmod 644 /etc/systemd/system/mili-tunnel.service

# Make sure mili.sh is executable
chmod +x $INSTALL_DIR/mili.sh

# Enable and start the service
echo -e "${BLUE}Enabling and starting Mili-Tunnel service...${NC}"
systemctl daemon-reload
systemctl enable mili-tunnel
systemctl start mili-tunnel
systemctl status mili-tunnel

echo -e "\n${GREEN}=== Mili-Tunnel setup complete! ===${NC}"
echo -e "The service is now running and will start automatically on boot."
echo -e "You can manage it with: ${YELLOW}systemctl {start|stop|restart|status} mili-tunnel${NC}"
echo -e "Configuration files are in: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "${BLUE}Thank you for using Mili-Tunnel!${NC}" 