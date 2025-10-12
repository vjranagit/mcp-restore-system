# MCP Testing Protocol

## Purpose
Systematically verify that all 11 MCP servers are functioning correctly after restoration or configuration changes.

---

## Pre-Test Checklist

Before running any tests:
- [ ] Claude Code has been restarted since last config change
- [ ] `~/.claude.json` exists and is valid JSON
- [ ] All Python virtual environments exist
- [ ] Node.js and npm are installed and accessible

---

## Automated Testing

### Level 1: Configuration Validation (10 seconds)
```bash
cd ~/work/projects/mcp-restore-system
./validate_mcp.sh
```

**Expected output:**
```
==================================
   MCP Server Validation
==================================

Configured servers: 11 / 11
✓ All 11 servers configured in .claude.json

Checking Python MCP servers...
  ✓ gmail: /home/vjrana/custom-gmail-mcp/venv/bin/python
  ✓ zabbix: /home/vjrana/work/mcp-servers/servers/zabbix/venv/bin/python
  ✓ elk: /home/vjrana/mcp-servers/elk/venv/bin/python

Checking Firefly III...
  ✓ Wrapper script exists and is executable
  ✓ Credentials file exists

Checking n8n servers...
  ✓ N8N_HOST configured: https://n8n.kryptoservs.com/n8n
  ✓ N8N_API_KEY configured (no typo detected)

Checking Node.js/NPM...
  ✓ Node.js: v22.16.0
  ✓ NPM: 10.9.2

==================================
✓ Validation PASSED
All 11 MCP servers are configured
==================================
```

**If validation fails:** Run `./restore_claude.sh --auto`

---

### Level 2: Server Count Verification (5 seconds)
```bash
jq '.mcpServers | keys | length' ~/.claude.json
```

**Expected output:** `11`

**If different:** Configuration is incomplete or corrupted. Run `./restore_claude.sh --auto`

---

### Level 3: Server Names Verification (5 seconds)
```bash
jq '.mcpServers | keys' ~/.claude.json
```

**Expected output (alphabetically sorted):**
```json
[
  "agent-browser",
  "context7",
  "elk",
  "filesystem",
  "firefly-iii",
  "github",
  "gmail",
  "n8n-docs",
  "n8n-workflows",
  "playwright",
  "zabbix"
]
```

**If missing any servers:** Run `./restore_claude.sh --auto`

---

### Level 4: JWT Token Typo Check (5 seconds)
```bash
grep -c "pqblic" ~/.claude.json
```

**Expected output:** `0`

**If output is 1 or higher:** JWT token has typo. Run `./restore_claude.sh --auto`

---

## Manual Testing in Claude Code

### Prerequisites
1. Restart Claude Code
2. Wait for initialization to complete (usually 10-15 seconds)
3. Open a new conversation

### Test Sequence

#### Test 1: Gmail MCP (Python-based)
**Prompt:** "list my unread emails"

**Expected behavior:**
- Claude uses `mcp__gmail__search_emails` tool
- Returns list of unread messages with subjects and senders
- No authentication errors

**If fails:**
- Check: `ls /home/vjrana/custom-gmail-mcp/venv/bin/python`
- Check: Gmail credentials configured
- Fix: `./restore_claude.sh --auto`

---

#### Test 2: Zabbix MCP (Python-based)
**Prompt:** "show me zabbix monitored hosts"

**Expected behavior:**
- Claude uses `mcp__zabbix__host_get` tool
- Returns list of monitored hosts with IDs and names
- No connection errors

**If fails:**
- Check: Zabbix running on `http://localhost:18082`
- Check: `ZABBIX_URL` in ~/.bashrc
- Fix: `./restore_claude.sh --auto`

---

#### Test 3: ELK MCP (Python-based)
**Prompt:** "check elasticsearch cluster health"

**Expected behavior:**
- Claude uses `mcp__elk__get_cluster_health` tool
- Returns cluster status (green/yellow/red)
- Shows node count and shard information

**If fails:**
- Check: Elasticsearch running on default port
- Check: `/home/vjrana/mcp-servers/elk/venv/` exists
- Fix: `./restore_claude.sh --auto`

---

#### Test 4: Filesystem MCP (NPX-based)
**Prompt:** "what directories can you access?"

**Expected behavior:**
- Claude uses `mcp__filesystem__list_allowed_directories` tool
- Returns: "Allowed directories: /home/vjrana"
- No permission errors

**If fails:**
- Check: `npx @modelcontextprotocol/server-filesystem --version`
- Fix: `./restore_claude.sh --auto`

---

#### Test 5: GitHub MCP (NPX-based)
**Prompt:** "search for my GitHub repositories"

**Expected behavior:**
- Claude uses `mcp__github__search_repositories` tool
- Returns list of your repositories
- No authentication errors (unless token is empty)

**If fails:**
- Check: `GITHUB_PERSONAL_ACCESS_TOKEN` in ~/.bashrc
- Check: `npx @modelcontextprotocol/server-github --version`
- Fix: `./restore_claude.sh --auto`

---

#### Test 6: Playwright MCP (NPX-based)
**Prompt:** "take a screenshot of example.com"

**Expected behavior:**
- Claude uses `mcp__playwright__browser_navigate` and `mcp__playwright__browser_take_screenshot`
- Returns screenshot or page snapshot
- No browser launch errors

**If fails:**
- Check: `npx @playwright/mcp@latest --version`
- Fix: `./restore_claude.sh --auto`

---

#### Test 7: Context7 MCP (NPX-based)
**Prompt:** "find React documentation"

**Expected behavior:**
- Claude uses `mcp__context7__resolve-library-id` tool
- Returns list of React-related libraries
- No API key errors

**If fails:**
- Check: `CONTEXT7_API_KEY` in ~/.bashrc (can be empty)
- Check: `npx @upstash/context7-mcp --version`
- Fix: `./restore_claude.sh --auto`

---

#### Test 8: Agent Browser MCP (NPX-based)
**Prompt:** "navigate to example.com using agent browser"

**Expected behavior:**
- Claude uses `mcp__agent-browser__browser_navigate` tool
- Returns page title and content
- No browser initialization errors

**If fails:**
- Check: `npx @agent-infra/mcp-server-browser --version`
- Fix: `./restore_claude.sh --auto`

---

#### Test 9: n8n-workflows MCP (NPX-based)
**Prompt:** "list my n8n workflows"

**Expected behavior:**
- Claude uses `mcp__n8n__list_workflows` tool
- Returns list of workflows with names and IDs
- No 401 authentication errors

**If fails:**
- Check: `N8N_API_KEY` has correct JWT (no "pqblic" typo)
- Check: n8n instance accessible at `N8N_HOST`
- Fix: `./restore_claude.sh --auto`

---

#### Test 10: n8n-docs MCP (NPX-based)
**Prompt:** "search n8n nodes for HTTP Request"

**Expected behavior:**
- Claude uses `mcp__n8n-docs__search_nodes` tool
- Returns node documentation and examples
- No authentication errors

**If fails:**
- Check: Same as n8n-workflows (shared credentials)
- Fix: `./restore_claude.sh --auto`

---

#### Test 11: Firefly III MCP (Bash wrapper)
**Prompt:** "list my firefly III accounts"

**Expected behavior:**
- Claude uses `mcp__firefly-iii__list_account` tool
- Returns list of financial accounts (may be empty)
- No wrapper script errors

**If fails:**
- Check: `~/.firefly-mcp/firefly-mcp-wrapper.sh` exists and is executable
- Check: `~/.firefly-mcp/credentials.env` exists
- Check: Firefly III running on `http://localhost:8066`
- Fix: `./restore_claude.sh --auto`

---

## Test Results Documentation

### Pass Criteria
✅ All 11 tests pass
✅ No authentication errors
✅ No "tool not available" errors
✅ All responses contain actual data (not just error messages)

### Partial Pass Criteria
⚠️ 8-10 tests pass
⚠️ Some tools have empty responses (e.g., no workflows, no accounts)
⚠️ Minor connectivity issues to external services

**Action:** Document which servers failed, then run `./restore_claude.sh --auto`

### Fail Criteria
❌ Less than 8 tests pass
❌ Multiple "tool not available" errors
❌ Configuration validation fails

**Action:** Immediately run `./restore_claude.sh --auto`

---

## Troubleshooting Decision Tree

```
Server not responding?
├─ Is it in .claude.json? → jq '.mcpServers | keys' ~/.claude.json
│  ├─ Yes → Continue
│  └─ No → ./restore_claude.sh --auto
│
├─ Is it loading in Claude Code? → Ask Claude "what tools do you have?"
│  ├─ Yes → Test the specific tool
│  └─ No → ./restore_claude.sh --auto
│
├─ Tool available but returns errors?
│  ├─ Python server → Check venv exists
│  ├─ NPX server → Check `npx <package> --version`
│  ├─ n8n server → Check JWT token for typo
│  └─ Firefly → Check wrapper script and credentials
│
└─ Still broken? → ./restore_claude.sh --auto
```

---

## Post-Restore Testing Schedule

### Immediately After Restore:
1. Run `./validate_mcp.sh` (10 seconds)
2. Restart Claude Code
3. Test 3 random servers from the list above (2 minutes)

### Within 24 Hours:
1. Test all 11 servers systematically (10 minutes)
2. Document any persistent issues
3. If any issues: run `./restore_claude.sh --auto` again

### Weekly:
1. Run `./validate_mcp.sh` (10 seconds)
2. Test 2-3 random servers (1 minute)

### Monthly:
1. Full test of all 11 servers (10 minutes)
2. Update MCP packages: `./restore_claude.sh --auto`
3. Verify backup cron job: `crontab -l | grep claude`

---

## Quick Reference Commands

```bash
# Full validation
cd ~/work/projects/mcp-restore-system && ./validate_mcp.sh

# Server count
jq '.mcpServers | keys | length' ~/.claude.json

# Server names
jq '.mcpServers | keys' ~/.claude.json

# JWT typo check
grep -c "pqblic" ~/.claude.json

# Restore everything
cd ~/work/projects/mcp-restore-system && ./restore_claude.sh --auto

# Check backups
ls -lt ~/work/projects/mcp-restore-system/backups/ | head -10
```

---

## Emergency Testing (When Everything is Broken)

If you suspect everything is broken:

```bash
# 1. Validate configuration (10 seconds)
cd ~/work/projects/mcp-restore-system
./validate_mcp.sh

# 2. If validation fails, restore (2 minutes)
./restore_claude.sh --auto

# 3. Restart Claude Code

# 4. Quick smoke test (30 seconds)
# In Claude Code, type: "list my unread emails"
# If Gmail works, everything likely works

# 5. Full test if needed (10 minutes)
# Test all 11 servers using prompts above
```

---

## Success Metrics

### Gold Standard (Perfect State):
- ✅ Validation script passes
- ✅ All 11 servers load in Claude Code
- ✅ All 11 manual tests pass
- ✅ No authentication errors
- ✅ No "tool not available" errors

### Acceptable State:
- ✅ Validation script passes
- ✅ At least 10/11 servers work
- ⚠️ One server has connectivity issues (external service down)

### Unacceptable State:
- ❌ Validation script fails
- ❌ Less than 10 servers work
- ❌ Any JWT typos detected

**If unacceptable:** Run `./restore_claude.sh --auto` immediately

---

## Remember

**Testing should be FAST and EASY.**

Don't spend hours debugging. If 2+ servers fail testing:
1. Run `./restore_claude.sh --auto`
2. Wait 2 minutes
3. Restart Claude Code
4. Test again

Stop debugging. Start restoring. 🚀
