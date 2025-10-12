#!/bin/bash

################################################################################
# Quick MCP Installation Script
#
# This is a simplified installation script that combines both local installation
# and remote deployment capabilities.
#
# Usage:
#   ./quick_install.sh local              # Install on local machine
#   ./quick_install.sh remote             # Deploy to remote hosts (Ansible)
#   ./quick_install.sh backup             # Create backup only
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Help message
show_help() {
    cat << EOF
MCP Quick Installation Tool

Usage:
    $0 local                 Install MCP servers locally
    $0 remote                Deploy to remote hosts via Ansible
    $0 backup                Create configuration backup
    $0 help                  Show this help message

Local Installation:
    Installs all MCP servers on the current machine

Remote Deployment:
    Uses Ansible to deploy to multiple hosts
    Requires: inventory file configured

Examples:
    $0 local                 # Install everything locally
    $0 remote                # Deploy to all hosts in inventory
    $0 backup                # Backup current configuration

EOF
}

# Check prerequisites
check_prerequisites() {
    local missing=0

    echo -e "${BLUE}Checking prerequisites...${NC}"

    # Check for required commands
    for cmd in python3 node npm git; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}✗ $cmd not found${NC}"
            ((missing++))
        else
            echo -e "${GREEN}✓ $cmd found${NC}"
        fi
    done

    if [ $missing -gt 0 ]; then
        echo -e "${RED}Missing $missing required tool(s). Please install them first.${NC}"
        return 1
    fi

    return 0
}

# Local installation
install_local() {
    echo -e "${GREEN}Starting local MCP installation...${NC}"

    if [ ! -f "$SCRIPT_DIR/restore_claude.sh" ]; then
        echo -e "${RED}Error: restore_claude.sh not found${NC}"
        exit 1
    fi

    chmod +x "$SCRIPT_DIR/restore_claude.sh"
    "$SCRIPT_DIR/restore_claude.sh" --auto
}

# Remote deployment
deploy_remote() {
    echo -e "${GREEN}Starting remote MCP deployment...${NC}"

    # Check for Ansible
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${YELLOW}Ansible not found. Installing...${NC}"

        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y ansible
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y ansible
        elif command -v yum &> /dev/null; then
            sudo yum install -y ansible
        else
            echo -e "${RED}Cannot install Ansible automatically. Please install manually.${NC}"
            exit 1
        fi
    fi

    # Check for inventory file
    if [ ! -f "$SCRIPT_DIR/inventory" ]; then
        echo -e "${YELLOW}No inventory file found. Creating from template...${NC}"

        if [ -f "$SCRIPT_DIR/inventory.example" ]; then
            cp "$SCRIPT_DIR/inventory.example" "$SCRIPT_DIR/inventory"
            echo -e "${YELLOW}Please edit $SCRIPT_DIR/inventory with your host information${NC}"
            echo -e "${YELLOW}Then run: $0 remote${NC}"
            exit 0
        else
            echo -e "${RED}inventory.example not found${NC}"
            exit 1
        fi
    fi

    # Run Ansible playbook
    echo -e "${BLUE}Deploying MCP servers via Ansible...${NC}"
    ansible-playbook -i "$SCRIPT_DIR/inventory" "$SCRIPT_DIR/deploy_mcp_ansible.yml"
}

# Create backup
create_backup() {
    echo -e "${GREEN}Creating MCP configuration backup...${NC}"

    if [ ! -f "$SCRIPT_DIR/restore_claude.sh" ]; then
        echo -e "${RED}Error: restore_claude.sh not found${NC}"
        exit 1
    fi

    chmod +x "$SCRIPT_DIR/restore_claude.sh"
    "$SCRIPT_DIR/restore_claude.sh" --backup
}

# Main execution
main() {
    case "${1:-help}" in
        local)
            check_prerequisites || exit 1
            install_local
            ;;
        remote)
            check_prerequisites || exit 1
            deploy_remote
            ;;
        backup)
            create_backup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main
main "$@"
