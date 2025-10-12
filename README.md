# Claude MCP Restore System

A complete restoration and deployment system for Claude MCP servers. This toolkit allows you to backup, restore, and deploy all MCP configurations and servers across multiple machines with a single command.

## 🚀 Quick Start

### Local Installation
```bash
# Clone and run
git clone <your-repo-url>
cd mcp-restore-system
./quick_install.sh local
```

### Remote Deployment
```bash
# Deploy to multiple hosts
./quick_install.sh remote
```

## 📦 What's Included

### MCP Servers Configured
- **Gmail MCP** - Email management and search
- **Zabbix MCP** - Infrastructure monitoring
- **ELK MCP** - Elasticsearch/Kibana integration
- **Filesystem MCP** - Local file operations
- **GitHub MCP** - Repository management
- **Playwright MCP** - Browser automation
- **Context7 MCP** - Documentation lookup
- **Agent Browser MCP** - Web browsing agent
- **n8n Workflows MCP** - Workflow automation
- **n8n Docs MCP** - n8n documentation

### Scripts
- `restore_claude.sh` - Main restoration script
- `quick_install.sh` - Simplified installation wrapper
- `deploy_mcp_ansible.yml` - Ansible playbook for multi-host deployment
- `inventory.example` - Ansible inventory template

## 🛠️ Installation Methods

### Method 1: Local Installation (Bash Script)

```bash
# Interactive mode
./restore_claude.sh

# Automatic mode (no prompts)
./restore_claude.sh --auto

# Backup only
./restore_claude.sh --backup
```

**What it does:**
- Installs all system dependencies (Python, Node.js, npm, git)
- Creates Python virtual environments for custom MCP servers
- Installs NPM packages for MCP servers
- Restores `.claude.json` configuration
- Sets up environment variables
- Verifies installation

### Method 2: Remote Deployment (Ansible)

```bash
# 1. Edit inventory file
cp inventory.example inventory
vim inventory

# 2. Run deployment
ansible-playbook -i inventory deploy_mcp_ansible.yml

# Optional: Deploy to specific hosts
ansible-playbook -i inventory deploy_mcp_ansible.yml --limit production
ansible-playbook -i inventory deploy_mcp_ansible.yml --limit dev-server-1

# Optional: Run specific tags
ansible-playbook -i inventory deploy_mcp_ansible.yml --tags python-servers
ansible-playbook -i inventory deploy_mcp_ansible.yml --tags npm-packages
```

**Available Ansible Tags:**
- `dependencies` - Install system packages
- `python-servers` - Setup Python MCP servers
- `npm-packages` - Install NPM packages
- `config` - Deploy Claude configuration
- `environment` - Setup environment variables
- `verify` - Verification checks

### Method 3: Quick Install Wrapper

```bash
# Simple commands for common tasks
./quick_install.sh local      # Install locally
./quick_install.sh remote     # Deploy remotely
./quick_install.sh backup     # Create backup
./quick_install.sh help       # Show help
```

## 📋 Prerequisites

### System Requirements
- **OS**: Ubuntu 20.04+, Debian 11+, RHEL/CentOS 8+, Fedora 35+
- **Python**: 3.8+
- **Node.js**: 16+
- **NPM**: 8+
- **Git**: 2.x

### For Remote Deployment
- Ansible 2.9+
- SSH access to target hosts
- Sudo privileges (for package installation)

## 🔧 Configuration

### Environment Variables

The system automatically configures these environment variables:

```bash
# Zabbix Configuration
ZABBIX_URL=http://localhost:18082
ZABBIX_READ_ONLY=true

# n8n Configuration
N8N_HOST=https://n8n.kryptoservs.com/n8n
N8N_API_KEY=<your-api-key>
```

### Claude Configuration

The `.claude.json` file is automatically restored with all MCP server configurations. The paths are automatically adjusted to match the current user's home directory.

### Ansible Inventory

Edit `inventory` file to configure target hosts:

```ini
[all:vars]
ansible_user=youruser
ansible_ssh_private_key_file=~/.ssh/id_rsa

[production]
prod-server-1 ansible_host=192.168.1.200
prod-server-2 ansible_host=192.168.1.201

[development]
dev-server-1 ansible_host=192.168.1.100
```

## 🔍 Verification

After installation, verify the setup:

```bash
# Source environment
source ~/.bashrc

# Test Claude Code
claude

# List MCP servers
claude mcp list

# Test specific MCP server
# (through Claude Code interface)
```

### Manual Verification Checks

```bash
# Check .claude.json
cat ~/.claude.json | jq .

# Check Python virtual environments
ls -la ~/custom-gmail-mcp/venv/bin/python
ls -la ~/work/mcp-servers/servers/zabbix/venv/bin/python
ls -la ~/mcp-servers/elk/venv/bin/python

# Check NPM packages
npm list -g --depth=0 | grep mcp

# Check environment variables
env | grep -E 'ZABBIX|N8N'
```

## 📂 Directory Structure

```
mcp-restore-system/
├── restore_claude.sh           # Main restoration script
├── quick_install.sh            # Quick install wrapper
├── deploy_mcp_ansible.yml      # Ansible playbook
├── inventory.example           # Inventory template
├── inventory                   # Your inventory (gitignored)
├── README.md                   # This file
└── backups/                    # Backup directory (created automatically)
    ├── claude.json.backup
    ├── gmail_backup.tar.gz
    ├── zabbix_backup.tar.gz
    └── elk_backup.tar.gz
```

## 🔐 Security Notes

### API Keys and Secrets

The restoration system includes API keys embedded in the scripts. For production use:

1. **Store secrets separately**:
   ```bash
   # Use environment variables
   export N8N_API_KEY="your-secret-key"

   # Or use Ansible Vault
   ansible-vault encrypt_string 'your-secret' --name 'N8N_API_KEY'
   ```

2. **Update scripts to read from secure storage**:
   ```bash
   # Example: Read from .env file
   source ~/.mcp-secrets.env
   ```

3. **Use SSH keys instead of passwords**:
   ```ini
   # In inventory file
   ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```

### Permissions

The system automatically sets secure permissions:
- `.claude.json`: `600` (read/write owner only)
- Virtual environments: `755` (standard directory)
- Scripts: `755` (executable)

## 🚨 Troubleshooting

### Common Issues

**Issue**: Python virtual environment creation fails
```bash
# Solution: Install python3-venv
sudo apt-get install python3-venv  # Debian/Ubuntu
sudo dnf install python3-venv      # RHEL/Fedora
```

**Issue**: NPM packages fail to install globally
```bash
# Solution: Use npx (automatically handled by scripts)
# Or fix npm permissions
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
export PATH=~/.npm-global/bin:$PATH
```

**Issue**: Ansible connection fails
```bash
# Solution: Test SSH connection
ssh user@hostname

# Check Ansible connectivity
ansible all -i inventory -m ping
```

**Issue**: .claude.json not recognized
```bash
# Solution: Verify JSON format
jq empty ~/.claude.json

# Restore from backup
cp ~/.mcp-backups/claude.json.* ~/.claude.json
```

### Logs

Check logs for detailed error information:
```bash
# Restoration script logs
cat ~/mcp-restore-system/restore_*.log

# Ansible logs
ANSIBLE_LOG_PATH=./ansible.log ansible-playbook ...
```

## 🔄 Updates and Maintenance

### Update MCP Servers

```bash
# Update Python packages
source ~/custom-gmail-mcp/venv/bin/activate
pip install --upgrade mcp anthropic-mcp
deactivate

# Update NPM packages
npm update -g @modelcontextprotocol/server-filesystem
npm update -g @playwright/mcp
```

### Create New Backup

```bash
# Manual backup
./restore_claude.sh --backup

# Or use quick install
./quick_install.sh backup
```

### Update Configuration

```bash
# 1. Update .claude.json manually
vim ~/.claude.json

# 2. Create new encoded backup
cat ~/.claude.json | base64 > claude_config.b64

# 3. Update restore_claude.sh with new base64 string
vim restore_claude.sh  # Update CLAUDE_CONFIG_B64 variable
```

## 📚 Additional Resources

### MCP Documentation
- [Claude Code Docs](https://docs.claude.com/en/docs/claude-code)
- [MCP Protocol](https://modelcontextprotocol.io/)

### Ansible Resources
- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

## 🤝 Contributing

To contribute to this restoration system:

1. Test changes on a clean system
2. Update documentation
3. Create backups before major changes
4. Test multi-platform compatibility

## 📝 License

This is a personal infrastructure tool. Modify and use as needed.

## 🎯 Supported Platforms

- ✅ Ubuntu 20.04, 22.04, 24.04
- ✅ Debian 11, 12
- ✅ RHEL 8, 9
- ✅ CentOS Stream 8, 9
- ✅ Fedora 35+
- ⚠️ Arch Linux (manual dependency installation)

## 📞 Support

For issues:
1. Check troubleshooting section
2. Review logs
3. Verify prerequisites
4. Test on a fresh system

---

**Last Updated**: $(date +%Y-%m-%d)
**Version**: 1.0.0
