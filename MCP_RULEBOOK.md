# MCP Restoration Rulebook

## The Golden Rule: NEVER STRUGGLE AGAIN

**If something breaks, run ONE command:**
```bash
cd ~/work/projects/mcp-restore-system && ./restore_claude.sh --auto
```

That's it. Everything restored in under 2 minutes.

---

## Expected Configuration

### All 11 MCP Servers (ALWAYS)

1. **gmail** - Python-based Gmail integration
2. **zabbix** - Python-based Zabbix monitoring
3. **elk** - Python-based Elasticsearch/Kibana
4. **filesystem** - NPX file system access
5. **github** - NPX GitHub operations
6. **playwright** - NPX browser automation
7. **context7** - NPX documentation search
8. **agent-browser** - NPX headless browser
9. **n8n-workflows** - NPX workflow automation builder
10. **n8n-docs** - NPX n8n documentation
11. **firefly-iii** - Bash wrapper for finance manager

### Validation Command
```bash
./validate_mcp.sh
```
**Expected output:** "✓ Validation PASSED - All 11 MCP servers are configured"

If you see anything else, **restore immediately**.

---

## Common Problems & Instant Fixes

### Problem 1: "Only 6-10 servers loading"
**Cause:** Incomplete .claude.json configuration
**Fix:**
```bash
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --auto
# Restart Claude Code
```

### Problem 2: "n8n-workflows returns 401 unauthorized"
**Cause:** JWT token has typo (`pqblic-api` instead of `public-api`)
**Fix:**
```bash
cd ~/work/projects/mcp-restore-system
./validate_mcp.sh  # Will detect typo
./restore_claude.sh --auto  # Fixes automatically
```

### Problem 3: "firefly-iii not loading"
**Cause:** Missing wrapper script or credentials
**Fix:**
```bash
# Check if wrapper exists
ls -la ~/.firefly-mcp/firefly-mcp-wrapper.sh
ls -la ~/.firefly-mcp/credentials.env

# If missing, restore:
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --auto
```

### Problem 4: "context7 or agent-browser not available"
**Cause:** NPM packages not installed or Claude Code didn't load them
**Fix:**
```bash
# Verify npx works
npx @upstash/context7-mcp --version
npx @agent-infra/mcp-server-browser --version

# If fails, restore Node.js environment:
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --auto
```

### Problem 5: ".claude.json got corrupted"
**Cause:** Manual editing error or crash during save
**Fix:**
```bash
# Restore from daily backup
cp ~/.claude.json.backup ~/.claude.json

# Or use restore script
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --auto
```

---

## Decision Tree: "Something's Wrong"

```
├─ Can't access any MCP servers?
│  └─ Run: ./restore_claude.sh --auto
│
├─ Some servers work, some don't?
│  ├─ Run: ./validate_mcp.sh
│  ├─ Read the output
│  └─ Run: ./restore_claude.sh --auto
│
├─ All servers configured but none loading?
│  ├─ Check: jq '.mcpServers | keys | length' ~/.claude.json
│  ├─ Should be: 11
│  └─ If not 11: ./restore_claude.sh --auto
│
├─ JWT authentication errors?
│  ├─ Run: ./validate_mcp.sh  # Detects typo
│  └─ Run: ./restore_claude.sh --auto
│
└─ Unknown error?
   └─ Run: ./restore_claude.sh --auto
```

**The answer is ALWAYS: restore_claude.sh**

---

## Prevention: Daily Automatic Backups

### Setup Once (run this now):
```bash
cd ~/work/projects/mcp-restore-system
./setup_daily_backup.sh
```

This creates a cron job that:
- Backs up .claude.json daily at 3 AM
- Keeps last 7 days of backups
- Stores in `./backups/`
- Never interrupts your work

### Manual Backup Anytime:
```bash
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --backup
```

---

## File Locations Reference

### Configuration Files
- **Main config**: `~/.claude.json` (11 MCP servers)
- **Firefly wrapper**: `~/.firefly-mcp/firefly-mcp-wrapper.sh`
- **Firefly creds**: `~/.firefly-mcp/credentials.env`
- **n8n creds**: `~/.n8n-mcp/credentials.env`

### Python Virtual Environments
- **Gmail**: `/home/vjrana/custom-gmail-mcp/venv/`
- **Zabbix**: `/home/vjrana/work/mcp-servers/servers/zabbix/venv/`
- **ELK**: `/home/vjrana/mcp-servers/elk/venv/`

### Firefly III Source
- **Repo**: `/home/vjrana/mcp-servers/firefly-iii-mcp/`
- **Built with**: Bun package manager
- **Packages**: core, local, server, cloudflare-worker

---

## Emergency Recovery

### Scenario: "Everything is broken, I'm panicking"

**Step 1:** Take a breath
**Step 2:** Run this:
```bash
cd ~/work/projects/mcp-restore-system
./restore_claude.sh --auto
```
**Step 3:** Wait 2 minutes
**Step 4:** Restart Claude Code
**Step 5:** Done. All 11 servers working.

### Scenario: "I need to move to a new machine"

**On new machine:**
```bash
git clone https://github.com/vjrana/mcp-restore-system.git
cd mcp-restore-system
./restore_claude.sh --auto
```

Everything installs automatically:
- Python virtual environments
- NPM packages (via npx on-demand)
- Firefly III with Bun
- All credentials from env vars
- Ready in under 5 minutes

---

## Testing After Restore

### Quick Test (30 seconds):
```bash
./validate_mcp.sh
```

### Full Test (2 minutes):
```bash
cd ~/work/projects/mcp-restore-system
./test_all_servers.sh
```

### Manual Test in Claude Code:
1. Restart Claude Code
2. Type: "list my unread emails" (tests Gmail)
3. Type: "show zabbix hosts" (tests Zabbix)
4. Type: "check elasticsearch health" (tests ELK)
5. Type: "list my GitHub repos" (tests GitHub)
6. Type: "show n8n workflows" (tests n8n-workflows)
7. Type: "get firefly accounts" (tests Firefly III)

If ALL work → You're golden ✨
If ANY fail → Run restore script

---

## Maintenance

### Weekly Checklist (5 minutes):
- [ ] Run `./validate_mcp.sh`
- [ ] Check backup count: `ls -l backups/ | wc -l` (should be 7+)
- [ ] Test one random MCP server in Claude Code
- [ ] If anything fails → restore

### Monthly Checklist (10 minutes):
- [ ] Update MCP packages: `./restore_claude.sh --auto`
- [ ] Test all 11 servers: `./test_all_servers.sh`
- [ ] Push latest config to GitHub
- [ ] Verify cron job still running: `crontab -l | grep claude`

### When Problems Occur:
**Don't debug. Don't troubleshoot. Don't waste time.**

Just run:
```bash
./restore_claude.sh --auto
```

---

## Environment Variables

### Required in ~/.bashrc:
```bash
# Zabbix
export ZABBIX_URL="http://localhost:18082"
export ZABBIX_READ_ONLY="true"

# n8n
export N8N_HOST="https://n8n.kryptoservs.com/n8n"
export N8N_API_KEY="<your-jwt-token-here>"

# GitHub
export GITHUB_PERSONAL_ACCESS_TOKEN="<your-token-here>"

# Firefly III
export FIREFLY_III_PAT="<your-jwt-token-here>"
export FIREFLY_III_BASE_URL="http://localhost:8066"
```

**Restore script manages these automatically** - you don't need to edit manually.

---

## Success Criteria

### How to Know Everything is Perfect:

1. **Validation passes:**
   ```bash
   ./validate_mcp.sh
   # Output: ✓ Validation PASSED
   ```

2. **Server count is 11:**
   ```bash
   jq '.mcpServers | keys | length' ~/.claude.json
   # Output: 11
   ```

3. **All servers listed:**
   ```bash
   jq '.mcpServers | keys' ~/.claude.json
   # Output: [agent-browser, context7, elk, filesystem, firefly-iii,
   #          github, gmail, n8n-docs, n8n-workflows, playwright, zabbix]
   ```

4. **No JWT typos:**
   ```bash
   grep -c "pqblic" ~/.claude.json
   # Output: 0 (typo should be "public-api", not "pqblic-api")
   ```

5. **Claude Code loads all tools:**
   - Restart Claude Code
   - Type: "what MCP tools do you have?"
   - Should mention all 11 servers

---

## Remember

**You are NEVER more than 2 minutes away from a working setup.**

No matter what breaks:
1. cd ~/work/projects/mcp-restore-system
2. ./restore_claude.sh --auto
3. Done.

Stop struggling. Stop debugging. Just restore.

This is the way. 🚀
