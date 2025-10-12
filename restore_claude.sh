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
    ["GITHUB_PERSONAL_ACCESS_TOKEN"]="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"
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
        mkdir -p "$server_dir" || { log_error "Failed to create directory $server_dir"; continue; }

        # Create virtual environment
        if [ ! -d "${server_dir}/venv" ]; then
            if ! python3 -m venv "${server_dir}/venv"; then
                log_error "Failed to create virtual environment for $server"
                continue
            fi
            log_info "Created virtual environment for $server"
        else
            log_info "Virtual environment already exists for $server"
        fi

        # Activate and install dependencies
        if ! source "${server_dir}/venv/bin/activate"; then
            log_error "Failed to activate virtual environment for $server"
            continue
        fi

        # Install common MCP dependencies with error handling
        log_info "Installing dependencies for $server..."
        if ! pip install --upgrade pip -q; then
            log_warning "Failed to upgrade pip for $server"
        fi

        if ! pip install mcp pydantic -q 2>/dev/null; then
            log_warning "Failed to install MCP packages for $server (may already be installed)"
        fi

        # Server-specific installations
        case $server in
            gmail)
                pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client -q || log_warning "Failed to install Gmail dependencies"
                ;;
            zabbix)
                pip install pyzabbix requests -q || log_warning "Failed to install Zabbix dependencies"
                ;;
            elk)
                pip install elasticsearch -q || log_warning "Failed to install Elasticsearch dependencies"
                ;;
        esac

        deactivate
        log "✓ $server setup complete"
    done
}

# Install NPM packages globally
install_npm_packages() {
    log "Installing NPM MCP packages..."

    # Check if npm is available
    if ! command_exists npm; then
        log_error "NPM not found. Cannot install packages."
        return 1
    fi

    for package in "${NPM_PACKAGES[@]}"; do
        log_info "Checking $package"
        # Don't need to install globally since we use npx
        log_info "✓ $package will be used via npx"
    done

    log "NPM package configuration complete (using npx on-demand)"
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

    if ! install_dependencies; then
        log_error "Dependency installation had errors. Continuing anyway..."
    fi

    clone_mcp_repos
    setup_python_servers

    if ! install_npm_packages; then
        log_warning "NPM package setup had issues. MCP servers using npx should still work."
    fi

    restore_claude_config
    setup_environment

    if verify_installation; then
        log ""
        log "${GREEN}========================================${NC}"
        log "${GREEN}  MCP Restoration Complete!${NC}"
        log "${GREEN}========================================${NC}"
    else
        log ""
        log "${YELLOW}========================================${NC}"
        log "${YELLOW}  MCP Restoration Finished with Warnings${NC}"
        log "${YELLOW}========================================${NC}"
        log_warning "Some components may not be fully configured. Check the log above."
    fi
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
