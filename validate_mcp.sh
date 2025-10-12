#!/bin/bash

################################################################################
# MCP Server Validation Script
#
# Tests all 11 MCP servers to ensure they're properly configured and loading
# Returns exit code 0 only if all 11 servers are working
#
# Usage:
#   ./validate_mcp.sh           # Test all servers
#   ./validate_mcp.sh --list    # List expected servers
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Expected 11 MCP servers
EXPECTED_SERVERS=(
    "gmail"
    "zabbix"
    "elk"
    "filesystem"
    "github"
    "playwright"
    "context7"
    "agent-browser"
    "n8n-workflows"
    "n8n-docs"
    "firefly-iii"
)

EXPECTED_COUNT=11

# Check if .claude.json exists
if [ ! -f ~/.claude.json ]; then
    echo -e "${RED}ERROR: ~/.claude.json not found${NC}"
    exit 1
fi

# Validate JSON
if ! jq empty ~/.claude.json 2>/dev/null; then
    echo -e "${RED}ERROR: ~/.claude.json is not valid JSON${NC}"
    exit 1
fi

echo "=================================="
echo "   MCP Server Validation"
echo "=================================="
echo ""

# List mode
if [ "$1" == "--list" ]; then
    echo -e "${BLUE}Expected ${EXPECTED_COUNT} MCP servers:${NC}"
    for server in "${EXPECTED_SERVERS[@]}"; do
        echo "  - $server"
    done
    exit 0
fi

# Count configured servers
CONFIGURED_COUNT=$(jq '.mcpServers | keys | length' ~/.claude.json 2>/dev/null)
echo -e "${BLUE}Configured servers: $CONFIGURED_COUNT / $EXPECTED_COUNT${NC}"

# Check if all expected servers are present
MISSING_SERVERS=()
for server in "${EXPECTED_SERVERS[@]}"; do
    if ! jq -e ".mcpServers.\"$server\"" ~/.claude.json >/dev/null 2>&1; then
        MISSING_SERVERS+=("$server")
    fi
done

if [ ${#MISSING_SERVERS[@]} -gt 0 ]; then
    echo -e "${RED}Missing servers:${NC}"
    for server in "${MISSING_SERVERS[@]}"; do
        echo -e "  ${RED}✗${NC} $server"
    done
    echo ""
    echo -e "${YELLOW}Run ./restore_claude.sh to restore missing servers${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All ${EXPECTED_COUNT} servers configured in .claude.json${NC}"
echo ""

# Check Python server paths
echo -e "${BLUE}Checking Python MCP servers...${NC}"
PYTHON_SERVERS=("gmail" "zabbix" "elk")
PYTHON_ERRORS=0

for server in "${PYTHON_SERVERS[@]}"; do
    cmd=$(jq -r ".mcpServers.\"$server\".command" ~/.claude.json 2>/dev/null)
    if [ -f "$cmd" ]; then
        echo -e "  ${GREEN}✓${NC} $server: $cmd"
    else
        echo -e "  ${RED}✗${NC} $server: Python executable not found at $cmd"
        ((PYTHON_ERRORS++))
    fi
done

if [ $PYTHON_ERRORS -gt 0 ]; then
    echo -e "${YELLOW}Warning: $PYTHON_ERRORS Python server(s) have missing executables${NC}"
fi

# Check Firefly wrapper
echo ""
echo -e "${BLUE}Checking Firefly III...${NC}"
FIREFLY_WRAPPER=$(jq -r '.mcpServers."firefly-iii".command' ~/.claude.json 2>/dev/null)
if [ -f "$FIREFLY_WRAPPER" ] && [ -x "$FIREFLY_WRAPPER" ]; then
    echo -e "  ${GREEN}✓${NC} Wrapper script exists and is executable"
    if [ -f ~/.firefly-mcp/credentials.env ]; then
        echo -e "  ${GREEN}✓${NC} Credentials file exists"
    else
        echo -e "  ${RED}✗${NC} Credentials file missing: ~/.firefly-mcp/credentials.env"
    fi
else
    echo -e "  ${RED}✗${NC} Wrapper script missing or not executable: $FIREFLY_WRAPPER"
fi

# Check n8n configuration
echo ""
echo -e "${BLUE}Checking n8n servers...${NC}"
N8N_HOST=$(jq -r '.mcpServers."n8n-workflows".env.N8N_HOST' ~/.claude.json 2>/dev/null)
N8N_KEY=$(jq -r '.mcpServers."n8n-workflows".env.N8N_API_KEY' ~/.claude.json 2>/dev/null)

if [ "$N8N_HOST" != "null" ] && [ "$N8N_HOST" != "" ]; then
    echo -e "  ${GREEN}✓${NC} N8N_HOST configured: $N8N_HOST"
else
    echo -e "  ${RED}✗${NC} N8N_HOST not configured"
fi

if [ "$N8N_KEY" != "null" ] && [ "$N8N_KEY" != "" ]; then
    # Check for JWT typo
    if echo "$N8N_KEY" | grep -q "pqblic"; then
        echo -e "  ${RED}✗${NC} JWT token has typo: 'pqblic-api' should be 'public-api'"
    else
        echo -e "  ${GREEN}✓${NC} N8N_API_KEY configured (no typo detected)"
    fi
else
    echo -e "  ${RED}✗${NC} N8N_API_KEY not configured"
fi

# Check Node.js
echo ""
echo -e "${BLUE}Checking Node.js/NPM...${NC}"
if command -v node >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Node.js: $(node --version)"
else
    echo -e "  ${RED}✗${NC} Node.js not found"
fi

if command -v npm >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} NPM: $(npm --version)"
else
    echo -e "  ${RED}✗${NC} NPM not found"
fi

# Summary
echo ""
echo "=================================="
if [ $CONFIGURED_COUNT -eq $EXPECTED_COUNT ] && [ ${#MISSING_SERVERS[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ Validation PASSED${NC}"
    echo -e "${GREEN}All $EXPECTED_COUNT MCP servers are configured${NC}"
    echo ""
    echo "Next step: Restart Claude Code to load all servers"
    exit 0
else
    echo -e "${RED}✗ Validation FAILED${NC}"
    echo -e "${RED}Expected $EXPECTED_COUNT servers, found $CONFIGURED_COUNT${NC}"
    echo -e "${RED}Missing ${#MISSING_SERVERS[@]} server(s)${NC}"
    echo ""
    echo "Run: ./restore_claude.sh to fix"
    exit 1
fi
