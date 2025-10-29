#!/bin/bash

#==============================================================================
# Channel Manager - Manage multiple news automation channels
#==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANNELS_DIR="${SCRIPT_DIR}/../channels"
TEMPLATE_DIR="${SCRIPT_DIR}/../template"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# List all channels
list_channels() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  ACTIVE CHANNELS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    if [ ! -d "$CHANNELS_DIR" ] || [ -z "$(ls -A $CHANNELS_DIR 2>/dev/null)" ]; then
        echo -e "${YELLOW}No channels found.${NC}"
        echo ""
        echo "Create a new channel with:"
        echo "  ./quick_start.sh"
        echo ""
        return
    fi
    
    for dir in "$CHANNELS_DIR"/*; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            local config="$dir/config/channel_config.json"
            
            if [ -f "$config" ]; then
                local channel_name=$(jq -r '.channel.name' "$config")
                local niche=$(jq -r '.channel.niche' "$config")
                local enabled=$(jq -r '.platforms.rumble.enabled' "$config")
                local status="inactive"
                [ "$enabled" = "true" ] && status="active"
                
                echo -e "${GREEN}●${NC} ${CYAN}$channel_name${NC}"
                echo "   Directory: $name"
                echo "   Niche: $niche"
                echo "   Status: $status"
                echo ""
            fi
        fi
    done
}

# Deploy channel to n8n
deploy_channel() {
    local channel_dir=$1
    
    if [ -z "$channel_dir" ]; then
        echo -e "${RED}Error: Channel directory required${NC}"
        echo "Usage: $0 deploy <channel-directory>"
        exit 1
    fi
    
    local channel_path="$CHANNELS_DIR/$channel_dir"
    
    if [ ! -d "$channel_path" ]; then
        echo -e "${RED}Error: Channel not found: $channel_dir${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Deploying channel: $channel_dir${NC}"
    echo ""
    
    # Check if .env exists
    if [ ! -f "$channel_path/.env" ]; then
        echo -e "${RED}Error: .env file not found${NC}"
        echo "Please configure your API keys first:"
        echo "  nano $channel_path/.env"
        exit 1
    fi
    
    # Load config
    local config="$channel_path/config/channel_config.json"
    local channel_name=$(jq -r '.channel.name' "$config")
    
    echo -e "${YELLOW}Channel: $channel_name${NC}"
    echo ""
    
    # Generate n8n workflow
    echo -e "${YELLOW}Generating n8n workflow...${NC}"
    
    # This would generate a channel-specific workflow
    # For now, we'll create a placeholder
    local workflow_file="$channel_path/workflow.json"
    
    # Copy base workflow and inject channel config
    cp "$TEMPLATE_DIR/workflows/main-workflow.json" "$workflow_file.tmp"
    
    # Inject channel-specific variables
    jq --arg channel_dir "$channel_dir" \
       --arg channel_name "$channel_name" \
       '.name = $channel_name | .settings.channelDir = $channel_dir' \
       "$workflow_file.tmp" > "$workflow_file"
    
    rm "$workflow_file.tmp"
    
    echo -e "${GREEN}✓ Workflow generated${NC}"
    echo ""
    
    # Instructions for n8n import
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  DEPLOYMENT INSTRUCTIONS${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo "1. Open your n8n instance:"
    echo "   http://localhost:5678"
    echo ""
    echo "2. Click 'Workflows' → 'Import from File'"
    echo ""
    echo "3. Select the workflow file:"
    echo "   $workflow_file"
    echo ""
    echo "4. Configure credentials in n8n for:"
    echo "   - OpenAI"
    echo "   - ElevenLabs"
    echo "   - Pexels"
    echo "   - Rumble"
    echo "   - YouTube"
    echo "   - Instagram"
    echo "   - Facebook"
    echo ""
    echo "5. Activate the workflow"
    echo ""
    echo -e "${GREEN}✓ Ready to deploy!${NC}"
    echo ""
}

# Test channel
test_channel() {
    local channel_dir=$1
    
    if [ -z "$channel_dir" ]; then
        echo -e "${RED}Error: Channel directory required${NC}"
        echo "Usage: $0 test <channel-directory>"
        exit 1
    fi
    
    local channel_path="$CHANNELS_DIR/$channel_dir"
    
    if [ ! -d "$channel_path" ]; then
        echo -e "${RED}Error: Channel not found: $channel_dir${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Testing channel: $channel_dir${NC}"
    echo ""
    
    # Check configuration
    echo -e "${YELLOW}Checking configuration...${NC}"
    
    local config="$channel_path/config/channel_config.json"
    if [ ! -f "$config" ]; then
        echo -e "${RED}✗ Config file missing${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Config file found${NC}"
    
    # Check RSS feeds
    local rss_file="$channel_path/config/rss_feeds.json"
    if [ ! -f "$rss_file" ]; then
        echo -e "${RED}✗ RSS feeds file missing${NC}"
        exit 1
    fi
    local feed_count=$(jq '. | length' "$rss_file")
    echo -e "${GREEN}✓ RSS feeds: $feed_count configured${NC}"
    
    # Check .env
    if [ ! -f "$channel_path/.env" ]; then
        echo -e "${YELLOW}⚠ .env file missing (required for production)${NC}"
    else
        echo -e "${GREEN}✓ Environment file found${NC}"
    fi
    
    # Check assets
    if [ -f "$channel_path/assets/intros/intro.mp4" ]; then
        echo -e "${GREEN}✓ Intro video exists${NC}"
    else
        echo -e "${YELLOW}⚠ Intro video missing${NC}"
    fi
    
    if [ -f "$channel_path/assets/outros/outro.mp4" ]; then
        echo -e "${GREEN}✓ Outro video exists${NC}"
    else
        echo -e "${YELLOW}⚠ Outro video missing${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Channel test complete!${NC}"
    echo ""
}

# Delete channel
delete_channel() {
    local channel_dir=$1
    
    if [ -z "$channel_dir" ]; then
        echo -e "${RED}Error: Channel directory required${NC}"
        echo "Usage: $0 delete <channel-directory>"
        exit 1
    fi
    
    local channel_path="$CHANNELS_DIR/$channel_dir"
    
    if [ ! -d "$channel_path" ]; then
        echo -e "${RED}Error: Channel not found: $channel_dir${NC}"
        exit 1
    fi
    
    local config="$channel_path/config/channel_config.json"
    local channel_name=$(jq -r '.channel.name' "$config")
    
    echo -e "${RED}WARNING: This will permanently delete the channel!${NC}"
    echo ""
    echo "Channel: $channel_name"
    echo "Directory: $channel_path"
    echo ""
    read -p "Are you sure? Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        rm -rf "$channel_path"
        echo -e "${GREEN}✓ Channel deleted${NC}"
    else
        echo "Cancelled"
    fi
}

# Clone channel
clone_channel() {
    local source_dir=$1
    local new_name=$2
    
    if [ -z "$source_dir" ] || [ -z "$new_name" ]; then
        echo -e "${RED}Error: Source and new name required${NC}"
        echo "Usage: $0 clone <source-channel> <new-channel-name>"
        exit 1
    fi
    
    local source_path="$CHANNELS_DIR/$source_dir"
    local new_dir=$(echo "$new_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    local new_path="$CHANNELS_DIR/$new_dir"
    
    if [ ! -d "$source_path" ]; then
        echo -e "${RED}Error: Source channel not found${NC}"
        exit 1
    fi
    
    if [ -d "$new_path" ]; then
        echo -e "${RED}Error: Channel already exists: $new_dir${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}Cloning channel...${NC}"
    
    # Copy directory
    cp -r "$source_path" "$new_path"
    
    # Update config
    local config="$new_path/config/channel_config.json"
    jq --arg name "$new_name" '.channel.name = $name' "$config" > "$config.tmp"
    mv "$config.tmp" "$config"
    
    # Clear outputs
    rm -rf "$new_path/output"/*
    rm -rf "$new_path/logs"/*
    
    echo -e "${GREEN}✓ Channel cloned: $new_dir${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update .env file"
    echo "2. Customize configuration"
    echo "3. Deploy: $0 deploy $new_dir"
}

# Show stats
show_stats() {
    local channel_dir=$1
    
    if [ -z "$channel_dir" ]; then
        # Show all channels
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${CYAN}  CHANNEL STATISTICS${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo ""
        
        for dir in "$CHANNELS_DIR"/*; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                local config="$dir/config/channel_config.json"
                
                if [ -f "$config" ]; then
                    local channel_name=$(jq -r '.channel.name' "$config")
                    local niche=$(jq -r '.channel.niche' "$config")
                    
                    echo -e "${GREEN}$channel_name${NC} ($niche)"
                    
                    # Count videos
                    local video_count=$(find "$dir/output/videos" -name "*.mp4" 2>/dev/null | wc -l)
                    echo "  Videos: $video_count"
                    
                    # Get directory size
                    local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                    echo "  Storage: $size"
                    
                    echo ""
                fi
            fi
        done
    else
        # Show specific channel
        local channel_path="$CHANNELS_DIR/$channel_dir"
        local config="$channel_path/config/channel_config.json"
        
        if [ ! -f "$config" ]; then
            echo -e "${RED}Channel not found${NC}"
            exit 1
        fi
        
        local channel_name=$(jq -r '.channel.name' "$config")
        
        echo -e "${CYAN}Statistics for: $channel_name${NC}"
        echo ""
        
        # Detailed stats would go here
        echo "Feature coming soon..."
    fi
}

# Main menu
case "$1" in
    list)
        list_channels
        ;;
    deploy)
        deploy_channel "$2"
        ;;
    test)
        test_channel "$2"
        ;;
    delete)
        delete_channel "$2"
        ;;
    clone)
        clone_channel "$2" "$3"
        ;;
    stats)
        show_stats "$2"
        ;;
    *)
        echo "Channel Manager - Multi-Niche News Automation"
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  list                        List all channels"
        echo "  deploy <channel-dir>        Deploy channel to n8n"
        echo "  test <channel-dir>          Test channel configuration"
        echo "  clone <source> <new-name>   Clone existing channel"
        echo "  delete <channel-dir>        Delete channel"
        echo "  stats [channel-dir]         Show statistics"
        echo ""
        echo "Examples:"
        echo "  $0 list"
        echo "  $0 deploy celebrity-news-daily"
        echo "  $0 test sports-news-network"
        echo "  $0 clone tech-today ai-news-daily"
        echo ""
        ;;
esac
