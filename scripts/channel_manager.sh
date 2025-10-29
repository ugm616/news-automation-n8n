#!/bin/bash
# Multi-Channel Manager - Deploy and manage multiple niche channels

CHANNELS_DIR="./channels"
TEMPLATE_DIR="./template"

# Create new channel from template
create_channel() {
    local niche=$1
    local channel_name=$2
    
    echo "Creating new channel: $channel_name ($niche)"
    
    # Create channel directory
    mkdir -p "$CHANNELS_DIR/$channel_name"
    
    # Copy template files
    cp -r "$TEMPLATE_DIR/"* "$CHANNELS_DIR/$channel_name/"
    
    # Generate channel-specific config
    cat > "$CHANNELS_DIR/$channel_name/config/channel_config.json" <<EOF
{
  "channel": {
    "name": "$channel_name",
    "niche": "$niche"
  }
}
EOF
    
    echo "✅ Channel created: $CHANNELS_DIR/$channel_name"
    echo "Next steps:"
    echo "1. Edit config/channel_config.json"
    echo "2. Add RSS feeds"
    echo "3. Configure API keys"
    echo "4. Deploy workflow: ./deploy.sh $channel_name"
}

# Deploy channel to n8n
deploy_channel() {
    local channel_name=$1
    echo "Deploying channel: $channel_name"
    
    # Import workflow with channel-specific config
    # Generate workflow JSON with channel variables
    # Upload to n8n
}

# List all channels
list_channels() {
    echo "Active Channels:"
    for dir in "$CHANNELS_DIR"/*; do
        if [ -d "$dir" ]; then
            local name=$(basename "$dir")
            local config="$dir/config/channel_config.json"
            if [ -f "$config" ]; then
                local niche=$(jq -r '.channel.niche' "$config")
                echo "  - $name ($niche)"
            fi
        fi
    done
}

# Main menu
case "$1" in
    create)
        create_channel "$2" "$3"
        ;;
    deploy)
        deploy_channel "$2"
        ;;
    list)
        list_channels
        ;;
    *)
        echo "Usage: $0 {create|deploy|list} [args]"
        echo ""
        echo "Examples:"
        echo "  $0 create sports 'Sports News Network'"
        echo "  $0 create politics 'Political Updates Daily'"
        echo "  $0 create music 'Music Industry News'"
        echo "  $0 deploy 'Sports News Network'"
        echo "  $0 list"
        ;;
esac
