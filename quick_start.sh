#!/bin/bash

#==============================================================================
# Quick Start - Multi-Niche Channel Creator
# Interactive setup for new news automation channels
#==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANNELS_DIR="${SCRIPT_DIR}/channels"
TEMPLATE_DIR="${SCRIPT_DIR}/template"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Banner
clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   📰 NEWS AUTOMATION SYSTEM - QUICK START                ║
║   Multi-Channel Creator for Any Niche                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    
    local missing_deps=0
    
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}✗ jq is not installed${NC}"
        missing_deps=1
    else
        echo -e "${GREEN}✓ jq${NC}"
    fi
    
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}✗ FFmpeg is not installed${NC}"
        missing_deps=1
    else
        echo -e "${GREEN}✓ FFmpeg${NC}"
    fi
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}✗ Node.js is not installed${NC}"
        missing_deps=1
    else
        echo -e "${GREEN}✓ Node.js${NC}"
    fi
    
    if [ $missing_deps -eq 1 ]; then
        echo ""
        echo -e "${RED}Please install missing dependencies and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All dependencies satisfied!${NC}"
    echo ""
}

# Select niche
select_niche() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  SELECT YOUR NICHE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    echo "Choose a content niche for your channel:"
    echo ""
    echo -e "${PURPLE}1)${NC} 🌟 Celebrity News     ${YELLOW}(High engagement, broad appeal)${NC}"
    echo -e "${PURPLE}2)${NC} ⚽ Sports News        ${YELLOW}(Passionate audience, consistent traffic)${NC}"
    echo -e "${PURPLE}3)${NC} 🏛️  Political News     ${YELLOW}(Controversial, high views)${NC}"
    echo -e "${PURPLE}4)${NC} 🎵 Music News         ${YELLOW}(Young audience, trending topics)${NC}"
    echo -e "${PURPLE}5)${NC} 💻 Tech News          ${YELLOW}(Tech-savvy, affluent audience)${NC}"
    echo -e "${PURPLE}6)${NC} 💰 Finance News       ${YELLOW}(High CPM, professional audience)${NC}"
    echo -e "${PURPLE}7)${NC} 🎮 Gaming News        ${YELLOW}(Engaged gamers, young demographic)${NC}"
    echo -e "${PURPLE}8)${NC} ₿  Crypto News        ${YELLOW}(Volatile, high interest)${NC}"
    echo -e "${PURPLE}9)${NC} 🎬 Movie/TV News      ${YELLOW}(Entertainment lovers)${NC}"
    echo -e "${PURPLE}10)${NC} 🍔 Food News         ${YELLOW}(Foodies, lifestyle audience)${NC}"
    echo -e "${PURPLE}11)${NC} ✈️  Travel News       ${YELLOW}(Wanderlust, aspirational)${NC}"
    echo -e "${PURPLE}12)${NC} 🎨 Custom Niche      ${YELLOW}(Define your own)${NC}"
    echo ""
    read -p "$(echo -e ${BLUE}Select option [1-12]:${NC} )" option
    
    case $option in
        1) NICHE="celebrity"; NICHE_NAME="Celebrity News" ;;
        2) NICHE="sports"; NICHE_NAME="Sports News" ;;
        3) NICHE="politics"; NICHE_NAME="Political News" ;;
        4) NICHE="music"; NICHE_NAME="Music News" ;;
        5) NICHE="tech"; NICHE_NAME="Tech News" ;;
        6) NICHE="finance"; NICHE_NAME="Finance News" ;;
        7) NICHE="gaming"; NICHE_NAME="Gaming News" ;;
        8) NICHE="crypto"; NICHE_NAME="Crypto News" ;;
        9) NICHE="entertainment"; NICHE_NAME="Movie/TV News" ;;
        10) NICHE="food"; NICHE_NAME="Food News" ;;
        11) NICHE="travel"; NICHE_NAME="Travel News" ;;
        12) 
            read -p "$(echo -e ${BLUE}Enter custom niche name:${NC} )" NICHE
            NICHE_NAME="$NICHE News"
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}✓ Selected niche: $NICHE_NAME${NC}"
    echo ""
}

# Get channel details
get_channel_details() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  CHANNEL CONFIGURATION${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    # Channel name
    read -p "$(echo -e ${BLUE}Channel name [e.g., 'Tech News Daily']:${NC} )" CHANNEL_NAME
    if [ -z "$CHANNEL_NAME" ]; then
        CHANNEL_NAME="$NICHE_NAME Daily"
    fi
    
    # Safe directory name
    CHANNEL_DIR=$(echo "$CHANNEL_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    
    # Branding
    echo ""
    read -p "$(echo -e ${BLUE}Primary brand color [hex, e.g., #FF0000]:${NC} )" PRIMARY_COLOR
    if [ -z "$PRIMARY_COLOR" ]; then
        PRIMARY_COLOR="#FF0000"
    fi
    
    read -p "$(echo -e ${BLUE}Secondary brand color [hex, e.g., #000000]:${NC} )" SECONDARY_COLOR
    if [ -z "$SECONDARY_COLOR" ]; then
        SECONDARY_COLOR="#000000"
    fi
    
    # Platforms
    echo ""
    read -p "$(echo -e ${BLUE}Rumble username:${NC} )" RUMBLE_USERNAME
    read -p "$(echo -e ${BLUE}YouTube channel ID [optional]:${NC} )" YOUTUBE_CHANNEL
    read -p "$(echo -e ${BLUE}TikTok username [optional]:${NC} )" TIKTOK_USERNAME
    read -p "$(echo -e ${BLUE}Instagram username [optional]:${NC} )" INSTAGRAM_USERNAME
    
    # Target
    echo ""
    read -p "$(echo -e ${BLUE}Monthly revenue goal [\$10000]:${NC} )" REVENUE_GOAL
    if [ -z "$REVENUE_GOAL" ]; then
        REVENUE_GOAL="10000"
    fi
    
    echo ""
}

# Create channel structure
create_channel_structure() {
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${CYAN}  CREATING CHANNEL STRUCTURE${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo ""
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    
    echo -e "${YELLOW}Creating directory structure...${NC}"
    
    # Create directories
    mkdir -p "$channel_path"/{config,assets/{logos,watermarks,intros,outros,thumbnails},output/{videos,images,audio,subtitles},logs}
    
    echo -e "${GREEN}✓ Directories created${NC}"
    
    # Copy template files
    echo -e "${YELLOW}Copying template files...${NC}"
    cp -r "$TEMPLATE_DIR/scripts" "$channel_path/"
    cp -r "$TEMPLATE_DIR/prompts" "$channel_path/"
    
    echo -e "${GREEN}✓ Template files copied${NC}"
}

# Generate channel config
generate_config() {
    echo -e "${YELLOW}Generating channel configuration...${NC}"
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    local config_file="$channel_path/config/channel_config.json"
    
    cat > "$config_file" <<EOF
{
  "channel": {
    "id": "$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "ch_$(date +%s)")",
    "name": "$CHANNEL_NAME",
    "niche": "$NICHE",
    "description": "Automated $NICHE_NAME updates every 2 hours",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "branding": {
      "primary_color": "$PRIMARY_COLOR",
      "secondary_color": "$SECONDARY_COLOR",
      "logo_path": "./assets/logos/logo.png",
      "watermark_path": "./assets/watermarks/watermark.png",
      "intro_video": "./assets/intros/intro.mp4",
      "outro_video": "./assets/outros/outro.mp4"
    },
    "voice": {
      "provider": "elevenlabs",
      "voice_id": "21m00Tcm4TlvDq8ikWAM",
      "style": "professional_news",
      "speed": 1.0,
      "stability": 0.75,
      "similarity_boost": 0.75
    }
  },
  "content": {
    "stories_per_cycle": 5,
    "schedule_interval_hours": 2,
    "longform_duration": {
      "min": 600,
      "max": 900
    },
    "teaser_duration": 30,
    "keywords": $(jq -n --arg niche "$NICHE" '[$niche, "breaking", "news", "update"]'),
    "exclude_keywords": ["opinion", "review", "sponsored"],
    "target_audience": "18-45",
    "tone": "engaging_professional"
  },
  "platforms": {
    "rumble": {
      "enabled": true,
      "username": "$RUMBLE_USERNAME",
      "license": "video_management",
      "primary": true
    },
    "youtube": {
      "enabled": $([ -n "$YOUTUBE_CHANNEL" ] && echo "true" || echo "false"),
      "channel_id": "$YOUTUBE_CHANNEL",
      "category": "News"
    },
    "tiktok": {
      "enabled": $([ -n "$TIKTOK_USERNAME" ] && echo "true" || echo "false"),
      "username": "$TIKTOK_USERNAME"
    },
    "instagram": {
      "enabled": $([ -n "$INSTAGRAM_USERNAME" ] && echo "true" || echo "false"),
      "username": "$INSTAGRAM_USERNAME"
    },
    "facebook": {
      "enabled": false
    }
  },
  "monetization": {
    "primary_platform": "rumble",
    "target_cpm": 7.50,
    "revenue_goal_monthly": $REVENUE_GOAL,
    "revenue_goal_daily": $(echo "$REVENUE_GOAL / 30" | bc)
  }
}
EOF
    
    echo -e "${GREEN}✓ Configuration generated${NC}"
}

# Load RSS feeds for niche
load_rss_feeds() {
    echo -e "${YELLOW}Loading RSS feeds for $NICHE niche...${NC}"
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    local rss_file="$channel_path/config/rss_feeds.json"
    local library_file="$CONFIG_DIR/rss_library.json"
    
    if [ -f "$library_file" ]; then
        # Extract feeds for this niche
        jq --arg niche "$NICHE" '.niches[$niche] // []' "$library_file" > "$rss_file"
        
        local feed_count=$(jq '. | length' "$rss_file")
        echo -e "${GREEN}✓ Loaded $feed_count RSS feeds${NC}"
    else
        echo -e "${YELLOW}⚠ RSS library not found, creating empty feed list${NC}"
        echo '[]' > "$rss_file"
    fi
}

# Copy niche-specific prompts
copy_prompts() {
    echo -e "${YELLOW}Setting up AI prompts for $NICHE...${NC}"
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    local niche_prompt="$SCRIPT_DIR/prompts/niches/${NICHE}.txt"
    
    if [ -f "$niche_prompt" ]; then
        cp "$niche_prompt" "$channel_path/prompts/longform_script_template.txt"
        echo -e "${GREEN}✓ Niche-specific prompts configured${NC}"
    else
        echo -e "${YELLOW}⚠ No specific prompt for $NICHE, using generic template${NC}"
        cp "$SCRIPT_DIR/prompts/longform_script_template.txt" "$channel_path/prompts/"
    fi
    
    # Copy universal prompts
    cp "$SCRIPT_DIR/prompts/teaser_script_template.txt" "$channel_path/prompts/"
    cp "$SCRIPT_DIR/prompts/voice_instructions.txt" "$channel_path/prompts/"
}

# Generate branding assets
generate_branding() {
    echo -e "${YELLOW}Generating branding assets...${NC}"
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    
    # Generate intro
    ffmpeg -f lavfi -i color=c=${PRIMARY_COLOR}:s=1920x1080:d=5 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='$CHANNEL_NAME':fontcolor=${SECONDARY_COLOR}:fontsize=80:x=(w-text_w)/2:y=(h-text_h)/2-100,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='Breaking News Every 2 Hours':fontcolor=white:fontsize=40:x=(w-text_w)/2:y=(h-text_h)/2+100" \
        -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
        -y "$channel_path/assets/intros/intro.mp4" 2>&1 | grep -v "frame=" || true
    
    # Generate outro
    ffmpeg -f lavfi -i color=c=${PRIMARY_COLOR}:s=1920x1080:d=10 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='SUBSCRIBE FOR UPDATES':fontcolor=white:fontsize=60:x=(w-text_w)/2:y=(h-text_h)/2-100,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='$CHANNEL_NAME':fontcolor=${SECONDARY_COLOR}:fontsize=50:x=(w-text_w)/2:y=(h-text_h)/2+50,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='Every 2 Hours':fontcolor=white:fontsize=40:x=(w-text_w)/2:y=(h-text_h)/2+150" \
        -c:v libx264 -preset fast -crf 23 -pix_fmt yuv420p \
        -y "$channel_path/assets/outros/outro.mp4" 2>&1 | grep -v "frame=" || true
    
    # Generate thumbnail template
    ffmpeg -f lavfi -i color=c=${PRIMARY_COLOR}:s=1280x720:d=0.1 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='$CHANNEL_NAME':fontcolor=${SECONDARY_COLOR}:fontsize=60:x=(w-text_w)/2:y=50,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='BREAKING NEWS':fontcolor=white:fontsize=80:x=(w-text_w)/2:y=(h-text_h)/2" \
        -frames:v 1 \
        -y "$channel_path/assets/thumbnails/template.png" 2>&1 | grep -v "frame=" || true
    
    echo -e "${GREEN}✓ Branding assets generated${NC}"
}

# Create .env file
create_env_file() {
    echo -e "${YELLOW}Creating environment configuration...${NC}"
    
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    local env_file="$channel_path/.env"
    
    cp "$CONFIG_DIR/.env.example" "$env_file"
    
    # Update with channel-specific values
    sed -i.bak "s|CHANNEL_NAME=.*|CHANNEL_NAME=\"$CHANNEL_NAME\"|" "$env_file"
    sed -i.bak "s|NICHE=.*|NICHE=$NICHE|" "$env_file"
    sed -i.bak "s|RUMBLE_USERNAME=.*|RUMBLE_USERNAME=$RUMBLE_USERNAME|" "$env_file"
    sed -i.bak "s|YOUTUBE_CHANNEL_ID=.*|YOUTUBE_CHANNEL_ID=$YOUTUBE_CHANNEL|" "$env_file"
    sed -i.bak "s|TIKTOK_USERNAME=.*|TIKTOK_USERNAME=$TIKTOK_USERNAME|" "$env_file"
    sed -i.bak "s|INSTAGRAM_USERNAME=.*|INSTAGRAM_USERNAME=$INSTAGRAM_USERNAME|" "$env_file"
    sed -i.bak "s|BRAND_COLOR_PRIMARY=.*|BRAND_COLOR_PRIMARY=$PRIMARY_COLOR|" "$env_file"
    sed -i.bak "s|BRAND_COLOR_SECONDARY=.*|BRAND_COLOR_SECONDARY=$SECONDARY_COLOR|" "$env_file"
    
    rm -f "$env_file.bak"
    
    echo -e "${GREEN}✓ Environment file created${NC}"
}

# Create gitignore for channel
create_channel_gitignore() {
    local channel_path="$CHANNELS_DIR/$CHANNEL_DIR"
    
    cat > "$channel_path/.gitignore" <<'EOF'
# Environment
.env

# Output files
output/
*.mp4
*.mp3
*.jpg
*.png
*.srt

# Logs
logs/
*.log

# Temp
temp/
tmp/
EOF
}

# Summary
show_summary() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ✅ CHANNEL CREATED SUCCESSFULLY!${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}Channel Details:${NC}"
    echo -e "  Name: ${BLUE}$CHANNEL_NAME${NC}"
    echo -e "  Niche: ${BLUE}$NICHE${NC}"
    echo -e "  Location: ${BLUE}$CHANNELS_DIR/$CHANNEL_DIR${NC}"
    echo ""
    echo -e "${GREEN}Revenue Projection:${NC}"
    echo -e "  Monthly Goal: ${BLUE}\$$REVENUE_GOAL${NC}"
    echo -e "  Daily Goal: ${BLUE}\$$(echo "$REVENUE_GOAL / 30" | bc)${NC}"
    echo -e "  Per Cycle (2h): ${BLUE}\$$(echo "$REVENUE_GOAL / 360" | bc)${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo -e "  1️⃣  Add your API keys:"
    echo -e "     ${BLUE}nano $CHANNELS_DIR/$CHANNEL_DIR/.env${NC}"
    echo ""
    echo -e "  2️⃣  Review RSS feeds:"
    echo -e "     ${BLUE}nano $CHANNELS_DIR/$CHANNEL_DIR/config/rss_feeds.json${NC}"
    echo ""
    echo -e "  3️⃣  Customize channel config:"
    echo -e "     ${BLUE}nano $CHANNELS_DIR/$CHANNEL_DIR/config/channel_config.json${NC}"
    echo ""
    echo -e "  4️⃣  Deploy to n8n:"
    echo -e "     ${BLUE}./scripts/channel_manager.sh deploy $CHANNEL_DIR${NC}"
    echo ""
    echo -e "  5️⃣  Test workflow:"
    echo -e "     ${BLUE}./scripts/channel_manager.sh test $CHANNEL_DIR${NC}"
    echo ""
    echo -e "${GREEN}Estimated Setup Time: ${BLUE}15 minutes${NC}"
    echo -e "${GREEN}Expected First Video: ${BLUE}Next 2-hour cycle${NC}"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${PURPLE}🚀 Ready to automate your news channel!${NC}"
    echo ""
}

# Main execution
main() {
    check_dependencies
    select_niche
    get_channel_details
    create_channel_structure
    generate_config
    load_rss_feeds
    copy_prompts
    generate_branding
    create_env_file
    create_channel_gitignore
    show_summary
}

# Run
main
