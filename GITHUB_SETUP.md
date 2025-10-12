# GitHub Setup Guide

Since the GitHub token is not configured, follow these steps to create a private repository and push the code.

## Option 1: Manual GitHub Repository Creation (Easiest)

### Step 1: Create Repository on GitHub Website

1. Go to https://github.com/new
2. Repository name: `mcp-restore-system`
3. Description: `Complete MCP server restoration and deployment system`
4. **Select: Private** ✓
5. **DO NOT** initialize with README (we already have files)
6. Click "Create repository"

### Step 2: Push Code to GitHub

After creating the repository, GitHub will show you commands. Use these:

```bash
cd /home/vjrana/work/projects/mcp-restore-system

# Add remote (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/mcp-restore-system.git

# Push code
git push -u origin main
```

## Option 2: Using GitHub CLI (Automated)

### Step 1: Install GitHub CLI

```bash
# Install gh CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

### Step 2: Authenticate

```bash
gh auth login
# Follow prompts:
# - Choose: GitHub.com
# - Protocol: HTTPS
# - Authenticate: with browser or token
```

### Step 3: Create Private Repository

```bash
cd /home/vjrana/work/projects/mcp-restore-system

# Create private repo and push
gh repo create mcp-restore-system --private --source=. --push
```

## Option 3: Configure GitHub Personal Access Token for MCP

### Step 1: Create Personal Access Token

1. Go to https://github.com/settings/tokens
2. Click "Generate new token" → "Generate new token (classic)"
3. Note: `MCP Server Access`
4. Expiration: Choose your preference (90 days, 1 year, or no expiration)
5. Select scopes:
   - ✓ `repo` (all repo permissions)
   - ✓ `workflow` (if you want workflow access)
   - ✓ `admin:org` (for organization repositories)
6. Click "Generate token"
7. **Copy the token immediately** (you won't see it again)

### Step 2: Update Claude Configuration

```bash
# Backup current config
cp ~/.claude.json ~/.claude.json.backup-$(date +%Y%m%d-%H%M%S)

# Update with your token (replace YOUR_TOKEN_HERE)
jq '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN = "YOUR_TOKEN_HERE"' ~/.claude.json > ~/.claude.json.tmp
mv ~/.claude.json.tmp ~/.claude.json

# Verify
jq -r '.mcpServers.github.env.GITHUB_PERSONAL_ACCESS_TOKEN' ~/.claude.json
```

### Step 3: Restart Claude Code

```bash
# Exit current session and restart
claude
```

### Step 4: Create Repository via GitHub MCP

Then in Claude Code, the GitHub MCP will work:
```
Create a private GitHub repository called mcp-restore-system
```

## Current Repository Status

✅ **Git repository initialized**
✅ **All files committed** (commit: 3742d10)
✅ **Branch: main**
✅ **7 files ready to push**

Waiting for:
- GitHub remote URL to be added
- Push to GitHub

## Quick Commands Reference

```bash
# Check current status
cd /home/vjrana/work/projects/mcp-restore-system
git status
git log --oneline

# View remote
git remote -v

# Add remote (after creating repo on GitHub)
git remote add origin https://github.com/YOUR_USERNAME/mcp-restore-system.git

# Push to GitHub
git push -u origin main

# Verify repository is private
gh repo view --web
# or
# Visit: https://github.com/YOUR_USERNAME/mcp-restore-system/settings
```

## Files in This Repository

```
mcp-restore-system/
├── .gitignore                    # Git ignore rules
├── DEPLOYMENT_SUMMARY.md         # Quick deployment reference
├── GITHUB_SETUP.md              # This file
├── README.md                     # Complete documentation
├── deploy_mcp_ansible.yml        # Ansible deployment playbook
├── inventory.example             # Ansible inventory template
├── quick_install.sh              # Quick install wrapper
└── restore_claude.sh             # Main restoration script
```

## Security Notes

⚠️ **Important**: This repository contains:
- n8n API keys
- Firefly III personal access token
- Zabbix configuration

**Recommendations:**
1. Keep repository **PRIVATE**
2. Use environment variables for secrets in production
3. Consider using Ansible Vault for sensitive data
4. Rotate API keys if repository is ever made public accidentally

## Next Steps After Push

Once pushed to GitHub, you can:

1. **Clone on any machine**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/mcp-restore-system.git
   cd mcp-restore-system
   ./quick_install.sh local
   ```

2. **Deploy to multiple hosts**:
   ```bash
   cp inventory.example inventory
   vim inventory  # Add your hosts
   ./quick_install.sh remote
   ```

3. **Keep updated**:
   ```bash
   # Make changes
   git add .
   git commit -m "Update configuration"
   git push
   ```

---

**Repository created successfully once you complete one of the options above!** 🚀
