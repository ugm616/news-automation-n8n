#!/bin/bash

echo "🚀 News Automation - Quick Start"
echo "================================"
echo ""
echo "What niche would you like to create?"
echo "1) Celebrity News"
echo "2) Sports News"
echo "3) Political News"
echo "4) Music News"
echo "5) Tech News"
echo "6) Finance News"
echo "7) Gaming News"
echo "8) Crypto News"
echo "9) Custom (specify your own)"
echo ""
read -p "Select option (1-9): " option

case $option in
    1) NICHE="celebrity" ;;
    2) NICHE="sports" ;;
    3) NICHE="politics" ;;
    4) NICHE="music" ;;
    5) NICHE="tech" ;;
    6) NICHE="finance" ;;
    7) NICHE="gaming" ;;
    8) NICHE="crypto" ;;
    9) 
        read -p "Enter niche name: " NICHE
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

read -p "Channel name (e.g., 'Tech News Daily'): " CHANNEL_NAME
read -p "Primary brand color (hex, e.g., #FF0000): " PRIMARY_COLOR
read -p "Rumble username: " RUMBLE_USERNAME

echo ""
echo "Creating channel: $CHANNEL_NAME"
echo "Niche: $NICHE"
echo ""

# Create channel structure
./scripts/channel_manager.sh create "$NICHE" "$CHANNEL_NAME"

# Copy RSS feeds for niche
jq ".niches.$NICHE" config/rss_library.json > "channels/$CHANNEL_NAME/config/rss_feeds.json"

# Copy niche-specific prompts
cp "prompts/niches/$NICHE.txt" "channels/$CHANNEL_NAME/prompts/script_template.txt"

# Setup branding
./scripts/setup_branding.sh "$CHANNEL_NAME" "$NICHE" "$PRIMARY_COLOR" "#FFFFFF"

# Generate .env from template
cp config/.env.example "channels/$CHANNEL_NAME/.env"
sed -i "s/RUMBLE_USERNAME=.*/RUMBLE_USERNAME=$RUMBLE_USERNAME/" "channels/$CHANNEL_NAME/.env"

echo ""
echo "✅ Channel setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit channels/$CHANNEL_NAME/.env with your API keys"
echo "2. Review channels/$CHANNEL_NAME/config/channel_config.json"
echo "3. Deploy: ./scripts/channel_manager.sh deploy '$CHANNEL_NAME'"
echo ""
echo "Estimated setup time: 15 minutes"
echo "Expected monthly revenue: \$10,000+"
