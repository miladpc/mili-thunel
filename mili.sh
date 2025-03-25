#!/bin/bash

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help function
show_help() {
    echo -e "${BLUE}Mili-Tunnel${NC} - Simple TCP tunneling tool"
    echo
    echo -e "Usage:"
    echo -e "  ${GREEN}./mili.sh${NC} ${YELLOW}[command]${NC} ${YELLOW}[parameters]${NC}"
    echo
    echo -e "Commands:"
    echo -e "  ${GREEN}server${NC}        Run in server mode"
    echo -e "  ${GREEN}client${NC}        Run in client mode"
    echo -e "  ${GREEN}build${NC}         Compile the program"
    echo -e "  ${GREEN}help${NC}          Show this help"
    echo
    echo -e "Server parameters:"
    echo -e "  ${YELLOW}-p, --port${NC} PORT       Server listening port (default: 8443)"
    echo -e "  ${YELLOW}-r, --remote${NC} ADDR     Destination address (default: 127.0.0.1:80)"
    echo
    echo -e "Client parameters:"
    echo -e "  ${YELLOW}-l, --local${NC} ADDR      Local address (default: 127.0.0.1:8080)"
    echo -e "  ${YELLOW}-r, --remote${NC} ADDR     Destination address (default: 127.0.0.1:9090)"
    echo -e "  ${YELLOW}-s, --server${NC} ADDR     Tunnel server address (default: 127.0.0.1:8443)"
    echo
    echo -e "Examples:"
    echo -e "  ${GREEN}./mili.sh${NC} ${YELLOW}server -p 8443 -r 127.0.0.1:80${NC}"
    echo -e "  ${GREEN}./mili.sh${NC} ${YELLOW}client -l 127.0.0.1:2222 -r 192.168.1.100:80 -s example.com:8443${NC}"
}

# Check binary existence
check_binary() {
    if [ ! -f "./mili-tunnel" ]; then
        echo -e "${RED}Error:${NC} 'mili-tunnel' executable not found."
        echo -e "Please first compile with ${GREEN}./mili.sh build${NC} command."
        exit 1
    fi
}

# Build function
build_app() {
    echo -e "${BLUE}Compiling Mili-Tunnel...${NC}"
    go build -o mili-tunnel
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Compilation successful.${NC}"
    else
        echo -e "${RED}Error compiling the program.${NC}"
        exit 1
    fi
}

# Start server
start_server() {
    check_binary
    
    # Default values
    PORT="8443"
    REMOTE="127.0.0.1:80"
    
    # Process parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -r|--remote)
                REMOTE="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown parameter:${NC} $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}Starting server on port ${GREEN}$PORT${BLUE} and forwarding traffic to ${GREEN}$REMOTE${NC}"
    ./mili-tunnel --server --server-addr "0.0.0.0:$PORT" --remote "$REMOTE"
}

# Start client
start_client() {
    check_binary
    
    # Default values
    LOCAL="127.0.0.1:8080"
    REMOTE="127.0.0.1:9090"
    SERVER="127.0.0.1:8443"
    
    # Process parameters
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--local)
                LOCAL="$2"
                shift 2
                ;;
            -r|--remote)
                REMOTE="$2"
                shift 2
                ;;
            -s|--server)
                SERVER="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown parameter:${NC} $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}Starting client on ${GREEN}$LOCAL${BLUE}..."
    echo -e "Traffic to ${GREEN}$REMOTE${BLUE} is being tunneled through server ${GREEN}$SERVER${BLUE}.${NC}"
    ./mili-tunnel --local "$LOCAL" --remote "$REMOTE" --server-addr "$SERVER"
}

# Check parameter count
if [ $# -lt 1 ]; then
    show_help
    exit 1
fi

# Process main command
case "$1" in
    server)
        shift
        start_server "$@"
        ;;
    client)
        shift
        start_client "$@"
        ;;
    build)
        build_app
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command:${NC} $1"
        show_help
        exit 1
        ;;
esac 