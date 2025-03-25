package main

import (
	"flag"
	"io"
	"net"
	"os"
	"os/signal"
	"syscall"

	log "github.com/sirupsen/logrus"
)

// Program Configuration
type Config struct {
	localAddr  string
	remoteAddr string
	isServer   bool
	serverAddr string
}

func main() {
	// Setup logger
	log.SetFormatter(&log.TextFormatter{
		FullTimestamp: true,
	})
	log.SetOutput(os.Stdout)

	// Parse command line arguments
	config := parseFlags()

	// Handle system signals
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	log.Info("Starting tunnel")

	if config.isServer {
		go startServer(config)
	} else {
		go startClient(config)
	}

	// Wait for exit signal
	<-sigCh
	log.Info("Shutting down...")
}

func parseFlags() *Config {
	config := &Config{}

	flag.StringVar(&config.localAddr, "local", "127.0.0.1:8080", "Local address (IP:PORT)")
	flag.StringVar(&config.remoteAddr, "remote", "127.0.0.1:9090", "Remote address (IP:PORT)")
	flag.BoolVar(&config.isServer, "server", false, "Run in server mode")
	flag.StringVar(&config.serverAddr, "server-addr", "0.0.0.0:8443", "Server listening address (IP:PORT)")

	flag.Parse()

	return config
}

// Start server mode
func startServer(config *Config) {
	listener, err := net.Listen("tcp", config.serverAddr)
	if err != nil {
		log.Fatalf("Error starting server: %v", err)
	}
	defer listener.Close()

	log.Infof("Server started on %s", config.serverAddr)

	for {
		clientConn, err := listener.Accept()
		if err != nil {
			log.Errorf("Error accepting connection: %v", err)
			continue
		}

		log.Infof("New connection from %s", clientConn.RemoteAddr())
		go handleServerConnection(clientConn, config.remoteAddr)
	}
}

// Handle server connections
func handleServerConnection(clientConn net.Conn, remoteAddr string) {
	defer clientConn.Close()

	remoteConn, err := net.Dial("tcp", remoteAddr)
	if err != nil {
		log.Errorf("Error connecting to destination server: %v", err)
		return
	}
	defer remoteConn.Close()

	// Bidirectional data transfer
	go func() {
		_, err := io.Copy(remoteConn, clientConn)
		if err != nil {
			log.Debugf("Client->Destination connection closed: %v", err)
		}
	}()

	_, err = io.Copy(clientConn, remoteConn)
	if err != nil {
		log.Debugf("Destination->Client connection closed: %v", err)
	}
}

// Start client mode
func startClient(config *Config) {
	listener, err := net.Listen("tcp", config.localAddr)
	if err != nil {
		log.Fatalf("Error starting client: %v", err)
	}
	defer listener.Close()

	log.Infof("Client started on %s", config.localAddr)
	log.Infof("Traffic to %s is being tunneled through server %s", config.remoteAddr, config.serverAddr)

	for {
		localConn, err := listener.Accept()
		if err != nil {
			log.Errorf("Error accepting local connection: %v", err)
			continue
		}

		log.Infof("New local connection from %s", localConn.RemoteAddr())
		go handleClientConnection(localConn, config)
	}
}

// Handle client connections
func handleClientConnection(localConn net.Conn, config *Config) {
	defer localConn.Close()

	serverConn, err := net.Dial("tcp", config.serverAddr)
	if err != nil {
		log.Errorf("Error connecting to tunnel server: %v", err)
		return
	}
	defer serverConn.Close()

	// Bidirectional data transfer between local connection and tunnel server
	go func() {
		_, err := io.Copy(serverConn, localConn)
		if err != nil {
			log.Debugf("Local->Server connection closed: %v", err)
		}
	}()

	_, err = io.Copy(localConn, serverConn)
	if err != nil {
		log.Debugf("Server->Local connection closed: %v", err)
	}
}
