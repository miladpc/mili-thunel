# Mili-Tunnel

Mili-Tunnel is a simple tool for creating TCP tunnels between two Linux servers, written in Go.

## Features

- Tunneling TCP traffic between two servers
- Support for server and client modes
- Configurable local and remote ports

## Installation

To install and use this project, you first need to install Go. Then:

```bash
# Get the code from GitHub
git clone https://github.com/milad/mili-tunnel
cd mili-tunnel

# Install dependencies
go mod download

# Build the project
go build -o mili-tunnel
```

## Usage

### Running in server mode

```bash
./mili-tunnel --server --server-addr 0.0.0.0:8443 --remote 127.0.0.1:80
```

This command starts the server listening on port 8443 and forwards incoming connections to the local port 80.

### Running in client mode

```bash
./mili-tunnel --local 127.0.0.1:2222 --remote 192.168.1.100:80 --server-addr your-server-ip:8443
```

This command makes the client listen on local port 2222. Any connection to this port will be tunneled through the tunnel server to address 192.168.1.100:80.

### Using the UI script

For ease of use, you can use the `mili.sh` script:

```bash
# Run in server mode
./mili.sh server

# Run in client mode
./mili.sh client

# Show help
./mili.sh help
```

## Parameters

- `--local`: Local address the client listens on (default: 127.0.0.1:8080)
- `--remote`: Destination address to which traffic is forwarded (default: 127.0.0.1:9090)
- `--server`: If specified, the program runs in server mode
- `--server-addr`: Address the tunnel server listens on (default: 0.0.0.0:8443)

## Use Cases

- Accessing services behind firewalls
- Secure data transfer between two servers
- Connecting to local services remotely

## Deploying on a Linux Server

### 1. Installing Go on the Server

First, install Go on your Linux server:

```bash
# Update package lists
sudo apt update

# Install Go
sudo apt install golang-go

# Verify installation
go version
```

For the latest version, you can use:

```bash
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-go
```

### 2. Deploying the Application

#### Option 1: Build locally and transfer the binary

```bash
# On your local machine
GOOS=linux GOARCH=amd64 go build -o mili-tunnel
scp mili-tunnel mili.sh user@your-server-ip:~/
```

#### Option 2: Clone and build on the server

```bash
# On the server
git clone https://github.com/milad/mili-tunnel
cd mili-tunnel
go mod download
go build -o mili-tunnel
chmod +x mili.sh
```

### 3. Running as a Service

Create a systemd service file for automatic startup:

```bash
sudo nano /etc/systemd/system/mili-tunnel.service
```

Add the following content (adjust paths and parameters as needed):

```
[Unit]
Description=Mili Tunnel Service
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/home/your-username/mili-tunnel
ExecStart=/home/your-username/mili-tunnel/mili-tunnel --server --server-addr 0.0.0.0:8443 --remote 127.0.0.1:80
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mili-tunnel
sudo systemctl start mili-tunnel
sudo systemctl status mili-tunnel
```

### 4. Configuring Firewall

Allow the tunnel port through the firewall:

```bash
sudo ufw allow 8443/tcp
sudo ufw status
```

### 5. Using Nginx as Reverse Proxy (Optional)

Install Nginx:

```bash
sudo apt install nginx
```

Create a site configuration:

```bash
sudo nano /etc/nginx/sites-available/mili-tunnel
```

Add the following (adjust as needed):

```
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site and restart Nginx:

```bash
sudo ln -s /etc/nginx/sites-available/mili-tunnel /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. SSL with Certbot (Optional)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## Future Development

- Adding encryption for secure communications
- Support for UDP tunnels
- Adding authentication for connections
- Performance optimization 