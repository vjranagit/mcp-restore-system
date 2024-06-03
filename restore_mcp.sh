#!/bin/bash

################################################################################
# Claude MCP Server Restoration Script
#
# This script automatically restores all MCP servers and Claude configuration
# on any machine. It includes:
# - All MCP server installations
# - Claude configuration (.claude.json)
# - Python virtual environments
# - NPM packages
# - Environment variables and API keys
#
# Usage:
#   ./restore_mcp.sh              # Interactive mode
#   ./restore_mcp.sh --auto       # Automatic mode (no prompts)
#   ./restore_mcp.sh --backup     # Create backup only
################################################################################

# Note: Not using set -e to handle errors gracefully and continue with partial installs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/restore_$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="${SCRIPT_DIR}/backups"
AUTO_MODE=false
BACKUP_ONLY=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --auto)
            AUTO_MODE=true
            ;;
        --backup)
            BACKUP_ONLY=true
            ;;
        --help)
            echo "Usage: $0 [--auto] [--backup] [--help]"
            echo "  --auto    : Run in automatic mode without prompts"
            echo "  --backup  : Create backup only, don't restore"
            echo "  --help    : Show this help message"
            exit 0
            ;;
    esac
done

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running as root
check_not_root() {
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    else
        log_error "Cannot detect OS"
        exit 1
    fi
    log_info "Detected OS: $OS $OS_VERSION"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."

    # Check if dependencies already exist
    local missing_deps=()
    for cmd in python3 node npm git curl wget jq; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "All dependencies already installed"
        return 0
    fi

    log_info "Missing dependencies: ${missing_deps[*]}"

    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt-get update || { log_error "Failed to update apt"; return 1; }
        sudo apt-get install -y python3 python3-pip python3-venv nodejs npm git curl wget jq || { log_error "Failed to install dependencies"; return 1; }
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        sudo dnf install -y python3 python3-pip nodejs npm git curl wget jq || { log_error "Failed to install dependencies"; return 1; }
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm python python-pip nodejs npm git curl wget jq || { log_error "Failed to install dependencies"; return 1; }
    else
        log_warning "Unknown OS. Please install dependencies manually: python3, nodejs, npm, git, curl, wget, jq"
        return 1
    fi

    log "Dependencies installed successfully"
}

# Base64 encoded Claude configuration
# This is the snapshot of your current .claude.json with all MCP servers configured
CLAUDE_CONFIG_B64="ewogICJpbnN0YWxsTWV0aG9kIjogInVua25vd24iLAogICJhdXRvVXBkYXRlcyI6IHRydWUsCiAgIm1jcFNlcnZlcnMiOiB7CiAgICAiZ21haWwiOiB7CiAgICAgICJjb21tYW5kIjogIi9ob21lL3ZqcmFuYS9jdXN0b20tZ21haWwtbWNwL3ZlbnYvYmluL3B5dGhvbiIsCiAgICAgICJhcmdzIjogWwogICAgICAgICIvaG9tZS92anJhbmEvY3VzdG9tLWdtYWlsLW1jcC9lbmhhbmNlZF9zZXJ2ZXIucHkiCiAgICAgIF0KICAgIH0sCiAgICAiemFiYml4IjogewogICAgICAiY29tbWFuZCI6ICIvaG9tZS92anJhbmEvd29yay9tY3Atc2VydmVycy9zZXJ2ZXJzL3phYmJpeC92ZW52L2Jpbi9weXRob24iLAogICAgICAiYXJncyI6IFsKICAgICAgICAiL2hvbWUvdmpyYW5hL3dvcmsvbWNwLXNlcnZlcnMvc2VydmVycy96YWJiaXgvc2NyaXB0cy9zdGFydF9zZXJ2ZXIucHkiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7CiAgICAgICAgIlpBQkJJWF9VUkwiOiAiaHR0cDovL2xvY2FsaG9zdDoxODA4MiIsCiAgICAgICAgIlJFQURfT05MWSI6ICJ0cnVlIgogICAgICB9CiAgICB9LAogICAgImVsayI6IHsKICAgICAgImNvbW1hbmQiOiAiL2hvbWUvdmpyYW5hL21jcC1zZXJ2ZXJzL2Vsay92ZW52L2Jpbi9weXRob24iLAogICAgICAiYXJncyI6IFsKICAgICAgICAiL2hvbWUvdmpyYW5hL21jcC1zZXJ2ZXJzL2Vsay9zZXJ2ZXIucHkiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7fQogICAgfSwKICAgICJmaWxlc3lzdGVtIjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJAbW9kZWxjb250ZXh0cHJvdG9jb2wvc2VydmVyLWZpbGVzeXN0ZW0iLAogICAgICAgICIvaG9tZS92anJhbmEiCiAgICAgIF0KICAgIH0sCiAgICAiZ2l0aHViIjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJAbW9kZWxjb250ZXh0cHJvdG9jb2wvc2VydmVyLWdpdGh1YiIKICAgICAgXSwKICAgICAgImVudiI6IHsKICAgICAgICAiR0lUSFVCX1BFUlNPTkFMX0FDQ0VTU19UT0tFTiI6ICIiCiAgICAgIH0KICAgIH0sCiAgICAicGxheXdyaWdodCI6IHsKICAgICAgImNvbW1hbmQiOiAibnB4IiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi15IiwKICAgICAgICAiQHBsYXl3cmlnaHQvbWNwQGxhdGVzdCIKICAgICAgXSwKICAgICAgImVudiI6IHt9CiAgICB9LAogICAgImNvbnRleHQ3IjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJAdXBzdGFzaC9jb250ZXh0Ny1tY3AiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7CiAgICAgICAgIkNPTlRFWFQ3X0FQSV9LRVkiOiAiIgogICAgICB9CiAgICB9LAogICAgImFnZW50LWJyb3dzZXIiOiB7CiAgICAgICJjb21tYW5kIjogIm5weCIsCiAgICAgICJhcmdzIjogWwogICAgICAgICIteSIsCiAgICAgICAgIkBhZ2VudC1pbmZyYS9tY3Atc2VydmVyLWJyb3dzZXIiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7fQogICAgfSwKICAgICJuOG4td29ya2Zsb3dzIjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJtY3AtbjhuLWJ1aWxkZXIiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7CiAgICAgICAgIk44Tl9IT1NUIjogImh0dHBzOi8vbjhuLmtyeXB0b3NlcnZzLmNvbS9uOG4iLAogICAgICAgICJOOE5fQVBJX0tFWSI6ICJleUpoYkdjaU9pSklVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKemRXSWlPaUptWVRGaE0yWm1aaTAxTVRCaUxUUXdOekF0WVRBek9TMDFNell4TVdJeU5XRmxZVGNpTENKcGMzTWlPaUp1T0c0aUxDSmhkV1FpT2lKd2RXSnNhV010WVhCcElpd2lhV0YwSWpveE56WXdNalE0TmpZNWZRLkcwTFp3TDJCQXYxVGpZeHJGajNsTXY2RnNEUlYwanpMV2VPUUM4WDlHeG8iLAogICAgICAgICJPVVRQVVRfVkVSQk9TSVRZIjogImNvbmNpc2UiCiAgICAgIH0KICAgIH0sCiAgICAibjhuLWRvY3MiOiB7CiAgICAgICJjb21tYW5kIjogIm5weCIsCiAgICAgICJhcmdzIjogWwogICAgICAgICIteSIsCiAgICAgICAgIm44bi1tY3AiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7CiAgICAgICAgIk1DUF9NT0RFIjogInN0ZGlvIiwKICAgICAgICAiTE9HX0xFVkVMIjogImVycm9yIiwKICAgICAgICAiRElTQUJMRV9DT05TT0xFX09VVFBVVCI6ICJ0cnVlIiwKICAgICAgICAiTjhOX01DUF9URUxFTUVUUllfRElTQUJMRUQiOiAidHJ1ZSIsCiAgICAgICAgIk44Tl9BUElfVVJMIjogImh0dHBzOi8vbjhuLmtyeXB0b3NlcnZzLmNvbS9uOG4iLAogICAgICAgICJOOE5fQVBJX0tFWSI6ICJleUpoYkdjaU9pSklVekkxTmlJc0luUjVjQ0k2SWtwWFZDSjkuZXlKemRXSWlPaUptWVRGaE0yWm1aaTAxTVRCaUxUUXdOekF0WVRBek9TMDFNell4TVdJeU5XRmxZVGNpTENKcGMzTWlPaUp1T0c0aUxDSmhkV1FpT2lKd2RXSnNhV010WVhCcElpd2lhV0YwSWpveE56WXdNalE0TmpZNWZRLkcwTFp3TDJCQXYxVGpZeHJGajNsTXY2RnNEUlYwanpMV2VPUUM4WDlHeG8iCiAgICAgIH0KICAgIH0sCiAgICAiZmlyZWZseS1paWkiOiB7CiAgICAgICJjb21tYW5kIjogIi9ob21lL3ZqcmFuYS8uZmlyZWZseS1tY3AvZmlyZWZseS1tY3Atd3JhcHBlci5zaCIsCiAgICAgICJhcmdzIjogW10KICAgIH0KICB9Cn0K"

# Environment variables (add your secrets here)
declare -A ENV_VARS=(
    ["ZABBIX_URL"]="http://localhost:18082"
    ["ZABBIX_READ_ONLY"]="true"
    ["N8N_HOST"]="https://n8n.kryptoservs.com/n8n"
    ["N8N_API_KEY"]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYTFhM2ZmZi01MTBiLTQwNzAtYTAzOS01MzYxMWIyNWFlYTciLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU5MTAwNjM5fQ.St3-q-iW37vtT-4x3C7VqkZDkbxVmDMMWc2oj_bcfYk"
GITHUB_TOKEN="REDACTED_GITHUB_TOKEN"
    # Add more environment variables as needed
)

# Python MCP servers to install
declare -A PYTHON_SERVERS=(
    ["gmail"]="/home/vjrana/custom-gmail-mcp"
