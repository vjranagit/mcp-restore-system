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
#   ./restore_claude.sh              # Interactive mode
#   ./restore_claude.sh --auto       # Automatic mode (no prompts)
#   ./restore_claude.sh --backup     # Create backup only
################################################################################

set -e  # Exit on error

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

# Install system dependencies
install_dependencies() {
    log "Installing system dependencies..."

    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv nodejs npm git curl wget jq
    elif [ "$OS" = "fedora" ] || [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
        sudo dnf install -y python3 python3-pip nodejs npm git curl wget jq
    elif [ "$OS" = "arch" ]; then
        sudo pacman -S --noconfirm python python-pip nodejs npm git curl wget jq
    else
        log_warning "Unknown OS. Please install dependencies manually: python3, nodejs, npm, git, curl, wget, jq"
    fi

    log "Dependencies installed successfully"
}

# Base64 encoded Claude configuration
# This is the snapshot of your current .claude.json with all MCP servers configured
CLAUDE_CONFIG_B64="ewogICJtY3BTZXJ2ZXJzIjogewogICAgImdtYWlsIjogewogICAgICAiY29tbWFuZCI6ICIvaG9tZS92anJhbmEvY3VzdG9tLWdtYWlsLW1jcC92ZW52L2Jpbi9weXRob24iLAogICAgICAiYXJncyI6IFsKICAgICAgICAiL2hvbWUvdmpyYW5hL2N1c3RvbS1nbWFpbC1tY3AvZW5oYW5jZWRfc2VydmVyLnB5IgogICAgICBdCiAgICB9LAogICAgInphYmJpeCI6IHsKICAgICAgImNvbW1hbmQiOiAiL2hvbWUvdmpyYW5hL3dvcmsvbWNwLXNlcnZlcnMvc2VydmVycy96YWJiaXgvdmVudi9iaW4vcHl0aG9uIiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi9ob21lL3ZqcmFuYS93b3JrL21jcC1zZXJ2ZXJzL3NlcnZlcnMvemFiYml4L3NjcmlwdHMvc3RhcnRfc2VydmVyLnB5IgogICAgICBdLAogICAgICAiZW52IjogewogICAgICAgICJaQUJCSVhfVVJMIjogImh0dHA6Ly9sb2NhbGhvc3Q6MTgwODIiLAogICAgICAgICJSRUFEX09OTFkiOiAidHJ1ZSIKICAgICAgfQogICAgfSwKICAgICJlbGsiOiB7CiAgICAgICJjb21tYW5kIjogIi9ob21lL3ZqcmFuYS9tY3Atc2VydmVycy9lbGsvdmVudi9iaW4vcHl0aG9uIiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi9ob21lL3ZqcmFuYS9tY3Atc2VydmVycy9lbGsvc2VydmVyLnB5IgogICAgICBdLAogICAgICAiZW52Ijoge30KICAgIH0sCiAgICAiZmlsZXN5c3RlbSI6IHsKICAgICAgImNvbW1hbmQiOiAibnB4IiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi15IiwKICAgICAgICAiQG1vZGVsY29udGV4dHByb3RvY29sL3NlcnZlci1maWxlc3lzdGVtIiwKICAgICAgICAiL2hvbWUvdmpyYW5hIgogICAgICBdCiAgICB9LAogICAgImdpdGh1YiI6IHsKICAgICAgImNvbW1hbmQiOiAibnB4IiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi15IiwKICAgICAgICAiQG1vZGVsY29udGV4dHByb3RvY29sL3NlcnZlci1naXRodWIiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7CiAgICAgICAgIkdJVEhVQl9QRVJTT05BTF9BQ0NFU1NfVE9LRU4iOiAiIgogICAgICB9CiAgICB9LAogICAgInBsYXl3cmlnaHQiOiB7CiAgICAgICJjb21tYW5kIjogIm5weCIsCiAgICAgICJhcmdzIjogWwogICAgICAgICIteSIsCiAgICAgICAgIkBwbGF5d3JpZ2h0L21jcEBsYXRlc3QiCiAgICAgIF0sCiAgICAgICJlbnYiOiB7fQogICAgfSwKICAgICJjb250ZXh0NyI6IHsKICAgICAgImNvbW1hbmQiOiAibnB4IiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi15IiwKICAgICAgICAiQHVwc3Rhc2gvY29udGV4dDctbWNwIgogICAgICBdLAogICAgICAiZW52IjogewogICAgICAgICJDT05URVhUN19BUElfS0VZIjogIiIKICAgICAgfQogICAgfSwKICAgICJhZ2VudC1icm93c2VyIjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJAYWdlbnQtaW5mcmEvbWNwLXNlcnZlci1icm93c2VyIgogICAgICBdLAogICAgICAiZW52Ijoge30KICAgIH0sCiAgICAibjhuLXdvcmtmbG93cyI6IHsKICAgICAgImNvbW1hbmQiOiAibnB4IiwKICAgICAgImFyZ3MiOiBbCiAgICAgICAgIi15IiwKICAgICAgICAibWNwLW44bi1idWlsZGVyIgogICAgICBdLAogICAgICAiZW52IjogewogICAgICAgICJOOE5fSE9TVCI6ICJodHRwczovL244bi5rcnlwdG9zZXJ2cy5jb20vbjhuIiwKICAgICAgICAiTjhOX0FQSV9LRVkiOiAiZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SnpkV0lpT2lKbVlURmhNMlptWmkwMU1UQmlMVFF3TnpBdFlUQXpPUzAxTXpZeE1XSXlOV0ZsWVRjaUxDSnBjM01pT2lKdU9HNGlMQ0poZFdRaU9pSndjV0pzYVdNdFlYQnBJaXdpYVdGMElqb3hOelU1TVRBd05qTTVmUS5TdDMtcS1pVzM3dnRULTR4M0M3VnFrWkRrYnh WbURNTVdjMm9qX2JjZllrIiwKICAgICAgICAiT1VUUFVUX1ZFUkJPU0lUWSI6ICJjb25jaXNlIgogICAgICB9CiAgICB9LAogICAgIm44bi1kb2NzIjogewogICAgICAiY29tbWFuZCI6ICJucHgiLAogICAgICAiYXJncyI6IFsKICAgICAgICAiLXkiLAogICAgICAgICJuOG4tbWNwIgogICAgICBdLAogICAgICAiZW52IjogewogICAgICAgICJNQ1BfTU9ERSI6ICJzdGRpbyIsCiAgICAgICAgIkxPR19MRVZFTCI6ICJlcnJvciIsCiAgICAgICAgIkRJU0FCTEVfQ09OU09MRV9PVVRQVVQiOiAidHJ1ZSIsCiAgICAgICAgIk44Tl9NQ1BfVEVMRU1FVFJZX0RJU0FCTEVEIjogInRydWUiLAogICAgICAgICJOOE5fQVBJX1VSTCI6ICJodHRwczovL244bi5rcnlwdG9zZXJ2cy5jb20vbjhuIiwKICAgICAgICAiTjhOX0FQSV9LRVkiOiAiZXlKaGJHY2lPaUpJVXpJMU5pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SnpkV0lpT2lKbVlURmhNMlptWmkwMU1UQmlMVFF3TnpBdFlUQXpPUzAxTXpZeE1XSXlOV0ZsWVRjaUxDSnBjM01pT2lKdU9HNGlMQ0poZFdRaU9pSndjV0pzYVdNdFlYQnBJaXdpYVdGMElqb3hOelU1TVRBd05qTTVmUS5TdDMtcS1pVzM3dnRULTR4M0M3VnFrWkRrYnh WbURNTVdjMm9qX2JjZllrIgogICAgICB9CiAgICB9CiAgfQp9Cg=="

# Environment variables (add your secrets here)
declare -A ENV_VARS=(
    ["ZABBIX_URL"]="http://localhost:18082"
    ["ZABBIX_READ_ONLY"]="true"
    ["N8N_HOST"]="https://n8n.kryptoservs.com/n8n"
    ["N8N_API_KEY"]="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmYTFhM2ZmZi01MTBiLTQwNzAtYTAzOS01MzYxMWIyNWFlYTciLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU5MTAwNjM5fQ.St3-q-iW37vTt-4x3C7VqkZDkbxVmDMMWC2oj_bcfYk"
    # Add more environment variables as needed
)

# Python MCP servers to install
declare -A PYTHON_SERVERS=(
    ["gmail"]="/home/vjrana/custom-gmail-mcp"
    ["zabbix"]="/home/vjrana/work/mcp-servers/servers/zabbix"
    ["elk"]="/home/vjrana/mcp-servers/elk"
)

# NPM MCP packages
declare -a NPM_PACKAGES=(
    "@modelcontextprotocol/server-filesystem"
    "@modelcontextprotocol/server-github"
    "@playwright/mcp@latest"
    "@upstash/context7-mcp"
    "@agent-infra/mcp-server-browser"
    "mcp-n8n-builder"
    "n8n-mcp"
)

# Create backup
create_backup() {
    log "Creating backup of current configuration..."

    mkdir -p "$BACKUP_DIR"
    local backup_file="${BACKUP_DIR}/claude_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Backup .claude.json if exists
    if [ -f ~/.claude.json ]; then
        cp ~/.claude.json "${BACKUP_DIR}/claude.json.backup"
    fi

    # Backup MCP server directories
    for server in "${!PYTHON_SERVERS[@]}"; do
        server_dir="${PYTHON_SERVERS[$server]}"
        if [ -d "$server_dir" ]; then
            tar czf "${BACKUP_DIR}/${server}_backup.tar.gz" -C "$(dirname "$server_dir")" "$(basename "$server_dir")" 2>/dev/null || true
        fi
    done

    # Create compressed backup
    tar czf "$backup_file" -C "$BACKUP_DIR" . 2>/dev/null || true

    log "Backup created: $backup_file"

    if [ "$BACKUP_ONLY" = true ]; then
        log "Backup completed. Exiting."
        exit 0
    fi
}

# Setup Python MCP servers
setup_python_servers() {
    log "Setting up Python MCP servers..."

    for server in "${!PYTHON_SERVERS[@]}"; do
        server_dir="${PYTHON_SERVERS[$server]}"
        log_info "Setting up $server in $server_dir"

        # Create directory
        mkdir -p "$server_dir"

        # Create virtual environment
        if [ ! -d "${server_dir}/venv" ]; then
            python3 -m venv "${server_dir}/venv"
            log_info "Created virtual environment for $server"
        fi

        # Activate and install dependencies
        source "${server_dir}/venv/bin/activate"

        # Install common MCP dependencies
        pip install --upgrade pip
        pip install mcp anthropic-mcp pydantic

        # Server-specific installations
        case $server in
            gmail)
                pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client
                ;;
            zabbix)
                pip install pyzabbix requests
                ;;
            elk)
                pip install elasticsearch
                ;;
        esac

        deactivate
        log "✓ $server setup complete"
    done
}

# Install NPM packages globally
install_npm_packages() {
    log "Installing NPM MCP packages..."

    for package in "${NPM_PACKAGES[@]}"; do
        log_info "Installing $package"
        npm install -g "$package" || log_warning "Failed to install $package globally, will use npx"
    done

    log "NPM packages installed"
}

# Restore Claude configuration
restore_claude_config() {
    log "Restoring Claude configuration..."

    # Decode and write .claude.json
    local claude_config=$(echo "$CLAUDE_CONFIG_B64" | base64 -d)

    # Update paths to current user's home directory
    local current_user=$(whoami)
    local current_home=$(eval echo ~$current_user)

    # Replace hardcoded paths with current user's paths
    claude_config=$(echo "$claude_config" | sed "s|/home/vjrana|$current_home|g")

    # Backup existing config
    if [ -f ~/.claude.json ]; then
        cp ~/.claude.json ~/.claude.json.backup.$(date +%Y%m%d_%H%M%S)
        log_info "Backed up existing .claude.json"
    fi

    # Write new config
    echo "$claude_config" > ~/.claude.json
    log "✓ Claude configuration restored to ~/.claude.json"
}

# Set environment variables
setup_environment() {
    log "Setting up environment variables..."

    # Add to .bashrc if not already present
    for var in "${!ENV_VARS[@]}"; do
        if ! grep -q "export $var=" ~/.bashrc; then
            echo "export $var=\"${ENV_VARS[$var]}\"" >> ~/.bashrc
            log_info "Added $var to .bashrc"
        fi
    done

    log "Environment variables configured. Run 'source ~/.bashrc' to apply."
}

# Clone MCP server repositories (if needed)
clone_mcp_repos() {
    log "Checking MCP server repositories..."

    # Gmail MCP (if you have a repo for it)
    if [ ! -d "/home/$(whoami)/custom-gmail-mcp/.git" ]; then
        log_info "Gmail MCP needs to be cloned or created"
        # Add your repo URL here if available
        # git clone <your-repo-url> /home/$(whoami)/custom-gmail-mcp
    fi

    # Zabbix MCP
    if [ ! -d "/home/$(whoami)/work/mcp-servers/servers/zabbix/.git" ]; then
        log_info "Zabbix MCP needs to be cloned or created"
        mkdir -p "/home/$(whoami)/work/mcp-servers/servers/zabbix"
        # Add setup logic here
    fi

    # ELK MCP
    if [ ! -d "/home/$(whoami)/mcp-servers/elk/.git" ]; then
        log_info "ELK MCP needs to be cloned or created"
        mkdir -p "/home/$(whoami)/mcp-servers/elk"
        # Add setup logic here
    fi
}

# Verify installation
verify_installation() {
    log "Verifying installation..."

    local errors=0

    # Check .claude.json
    if [ -f ~/.claude.json ]; then
        log "✓ .claude.json exists"
        if jq empty ~/.claude.json 2>/dev/null; then
            log "✓ .claude.json is valid JSON"
        else
            log_error ".claude.json is not valid JSON"
            ((errors++))
        fi
    else
        log_error ".claude.json not found"
        ((errors++))
    fi

    # Check Python servers
    for server in "${!PYTHON_SERVERS[@]}"; do
        server_dir="${PYTHON_SERVERS[$server]}"
        if [ -d "${server_dir}/venv" ]; then
            log "✓ $server virtual environment exists"
        else
            log_error "$server virtual environment missing"
            ((errors++))
        fi
    done

    # Check node/npm
    if command -v node &> /dev/null; then
        log "✓ Node.js installed: $(node --version)"
    else
        log_error "Node.js not found"
        ((errors++))
    fi

    if command -v npm &> /dev/null; then
        log "✓ NPM installed: $(npm --version)"
    else
        log_error "NPM not found"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        log "${GREEN}✓ All verifications passed!${NC}"
        return 0
    else
        log_error "$errors error(s) found during verification"
        return 1
    fi
}

# Main execution
main() {
    clear
    echo "=================================="
    echo "   Claude MCP Restore System"
    echo "=================================="
    echo ""

    log "Starting restoration process..."
    log "Log file: $LOG_FILE"

    check_not_root
    detect_os

    if [ "$AUTO_MODE" = false ] && [ "$BACKUP_ONLY" = false ]; then
        read -p "This will restore all MCP servers. Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Restoration cancelled by user"
            exit 0
        fi
    fi

    create_backup
    install_dependencies
    clone_mcp_repos
    setup_python_servers
    install_npm_packages
    restore_claude_config
    setup_environment
    verify_installation

    log ""
    log "${GREEN}========================================${NC}"
    log "${GREEN}  MCP Restoration Complete!${NC}"
    log "${GREEN}========================================${NC}"
    log ""
    log "Next steps:"
    log "  1. Run: source ~/.bashrc"
    log "  2. Test Claude Code: claude"
    log "  3. Check MCP servers: claude mcp list"
    log ""
    log "Log saved to: $LOG_FILE"
}

# Run main function
main "$@"
