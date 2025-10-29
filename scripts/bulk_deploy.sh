#!/bin/bash

#==============================================================================
# Bulk Deploy - Deploy multiple channels simultaneously
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANNELS_DIR="${SCRIPT_DIR}/../channels"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🚀 BULK DEPLOYMENT - Multi-Channel Manager            ║
║   Deploy all channels at once                            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if channels directory exists
if [ ! -d "$CHANNELS_DIR" ]; then
    echo -e "${RED}Error: Channels directory not found${NC}"
    exit 1
fi

# Get all channel directories
channels=($(find "$CHANNELS_DIR" -mindepth 1 -maxdepth 1 -type d))

if [ ${#channels[@]} -eq 0 ]; then
    echo -e "${YELLOW}No channels found to deploy${NC}"
    echo ""
    echo "Create channels with:"
    echo "  ./quick_start.sh"
    echo ""
    exit 0
fi

echo -e "${GREEN}Found ${#channels[@]} channels${NC}"
echo ""

# Display channels
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  CHANNELS TO DEPLOY${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

declare -a deploy_list=()
index=1

for channel_path in "${channels[@]}"; do
    channel_dir=$(basename "$channel_path")
    config_file="$channel_path/config/channel_config.json"
    
    if [ -f "$config_file" ]; then
        channel_name=$(jq -r '.channel.name' "$config_file" 2>/dev/null || echo "Unknown")
        niche=$(jq -r '.channel.niche' "$config_file" 2>/dev/null || echo "unknown")
        active=$(jq -r '.platforms.rumble.enabled' "$config_file" 2>/dev/null || echo "false")
        
        status_icon="⚪"
        status_text="Not deployed"
        
        if [ "$active" = "true" ]; then
            status_icon="🟢"
            status_text="Ready"
        fi
        
        echo -e "${PURPLE}[$index]${NC} $status_icon ${CYAN}$channel_name${NC}"
        echo "    Niche: $niche"
        echo "    Directory: $channel_dir"
        echo "    Status: $status_text"
        echo ""
        
        deploy_list+=("$channel_dir|$channel_name")
        ((index++))
    fi
done

# Ask for confirmation
echo -e "${YELLOW}═══════════════════════════════════════${NC}"
read -p "$(echo -e ${YELLOW}Deploy all channels? [y/N]:${NC} )" confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  STARTING DEPLOYMENT${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# Deployment counters
deployed=0
failed=0
skipped=0

# Deploy each channel
for item in "${deploy_list[@]}"; do
    IFS='|' read -r channel_dir channel_name <<< "$item"
    
    echo -e "${YELLOW}Deploying: $channel_name${NC}"
    
    # Check if .env exists
    if [ ! -f "$CHANNELS_DIR/$channel_dir/.env" ]; then
        echo -e "${RED}  ✗ Skipped: No .env file found${NC}"
        ((skipped++))
        echo ""
        continue
    fi
    
    # Check if workflow exists
    workflow_file="$CHANNELS_DIR/$channel_dir/workflow.json"
    
    if [ ! -f "$workflow_file" ]; then
        # Generate workflow
        echo "  → Generating workflow..."
        
        # Copy template and inject channel config
        cp "$SCRIPT_DIR/../template/workflows/main-workflow.json" "$workflow_file.tmp"
        
        jq --arg channel_dir "$channel_dir" \
           --arg channel_name "$channel_name" \
           '.name = $channel_name | .settings.channelDir = $channel_dir' \
           "$workflow_file.tmp" > "$workflow_file"
        
        rm "$workflow_file.tmp"
    fi
    
    echo -e "${GREEN}  ✓ Workflow ready: $workflow_file${NC}"
    
    # Create deployment record
    deployment_file="$CHANNELS_DIR/$channel_dir/.deployed"
    cat > "$deployment_file" <<EOF
DEPLOYED_AT=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
DEPLOYED_BY=$USER
WORKFLOW_FILE=$workflow_file
STATUS=deployed
EOF
    
    echo -e "${GREEN}  ✓ Deployment record created${NC}"
    ((deployed++))
    echo ""
    
    # Small delay between deployments
    sleep 1
done

# Summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  DEPLOYMENT COMPLETE${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Successfully deployed: $deployed${NC}"
if [ $skipped -gt 0 ]; then
    echo -e "${YELLOW}Skipped: $skipped${NC}"
fi
if [ $failed -gt 0 ]; then
    echo -e "${RED}Failed: $failed${NC}"
fi
echo ""

# Next steps
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. Import workflows into n8n:"
echo "   - Open n8n: http://localhost:5678"
echo "   - Go to Workflows → Import from File"
echo "   - Import each workflow.json from channel directories"
echo ""
echo "2. Configure credentials in n8n:"
echo "   - Add API keys for all services"
echo "   - Link credentials to workflow nodes"
echo ""
echo "3. Activate workflows:"
echo "   - Toggle 'Active' switch for each workflow"
echo ""
echo "4. Monitor dashboard:"
echo "   - Open: http://localhost:8080"
echo ""
echo -e "${GREEN}All channels are ready to start generating revenue! 💰${NC}"
echo ""

# Create deployment summary file
summary_file="$SCRIPT_DIR/../deployment_summary_$(date +%Y%m%d_%H%M%S).txt"
cat > "$summary_file" <<EOF
DEPLOYMENT SUMMARY
==================
Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
User: $USER

Channels Deployed: $deployed
Channels Skipped: $skipped
Channels Failed: $failed

Deployed Channels:
EOF

for item in "${deploy_list[@]}"; do
    IFS='|' read -r channel_dir channel_name <<< "$item"
    if [ -f "$CHANNELS_DIR/$channel_dir/.deployed" ]; then
        echo "  - $channel_name ($channel_dir)" >> "$summary_file"
    fi
done

echo ""
echo -e "${CYAN}Deployment summary saved to: $summary_file${NC}"
echo ""
