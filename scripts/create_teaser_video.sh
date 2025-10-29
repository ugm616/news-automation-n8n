#!/bin/bash

#==============================================================================
# Create 30-Second Teaser Video
# Creates short-form teaser with CTA linking to Rumble
#==============================================================================

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../output/videos}"
IMAGE_DIR="${IMAGE_DIR:-$SCRIPT_DIR/../output/images}"
AUDIO_DIR="${AUDIO_DIR:-$SCRIPT_DIR/../output/audio}"
SUBTITLE_DIR="${SUBTITLE_DIR:-$SCRIPT_DIR/../output/subtitles}"

# Video settings (9:16 vertical)
WIDTH=1080
HEIGHT=1920
FPS=30
QUALITY=23
PRESET="fast"
DURATION=30

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check FFmpeg
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        log_error "FFmpeg is not installed"
        exit 1
    fi
}

# Create directories
create_directories() {
    mkdir -p "$OUTPUT_DIR" "$IMAGE_DIR" "$AUDIO_DIR" "$SUBTITLE_DIR"
}

# Create CTA end screen
create_cta_screen() {
    local rumble_url="$1"
    local output_file="$2"
    
    log_info "Creating CTA screen..."
    
    # Extract short URL display (e.g., rumble.com/v12345)
    local display_url=$(echo "$rumble_url" | sed 's|https://||' | cut -d'?' -f1)
    
    # Create CTA screen
    ffmpeg -f lavfi -i color=c=black:s=${WIDTH}x${HEIGHT}:d=5 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='WATCH FULL STORY':fontcolor=white:fontsize=56:x=(w-text_w)/2:y=h/3,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='↓ CLICK LINK BELOW ↓':fontcolor=yellow:fontsize=44:x=(w-text_w)/2:y=h/2,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='$display_url':fontcolor=cyan:fontsize=36:x=(w-text_w)/2:y=2*h/3" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "CTA screen created"
}

# Create teaser video
create_teaser() {
    local story_title="$1"
    local images_json="$2"
    local audio_file="$3"
    local subtitle_file="$4"
    local rumble_url="$5"
    local output_file="$6"
    
    log_info "Creating teaser video for: $story_title"
    
    # Parse images
    local images=($(echo "$images_json" | jq -r '.[]'))
    
    if [ ${#images[@]} -lt 3 ]; then
        log_error "Need at least 3 images for teaser"
        return 1
    fi
    
    # Use only first 4 images
    images=("${images[@]:0:4}")
    
    # Calculate timings (25s content + 5s CTA)
    local content_duration=25
    local cta_duration=5
    local duration_per_image=$(echo "$content_duration / ${#images[@]}" | bc -l)
    
    log_info "Creating content section (${content_duration}s with ${#images[@]} images)..."
    
    # Build filter for images with Ken Burns effect
    local filter_complex=""
    local inputs=""
    
    for i in "${!images[@]}"; do
        inputs="$inputs -loop 1 -t $duration_per_image -i ${images[$i]}"
        
        # More dramatic zoom for teasers
        filter_complex="$filter_complex[$i:v]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},zoompan=z='min(zoom+0.002,1.4)':d=$(echo "$duration_per_image * $FPS" | bc):s=${WIDTH}x${HEIGHT}:fps=${FPS}"
        
        # Add fade out except for last image
        if [ $i -lt $((${#images[@]} - 1)) ]; then
            filter_complex="$filter_complex,fade=out:st=$(echo "$duration_per_image - 0.3" | bc):d=0.3[v$i];"
        else
            filter_complex="$filter_complex[v$i];"
        fi
    done
    
    # Concatenate video segments
    for i in $(seq 0 $((${#images[@]} - 1))); do
        filter_complex="$filter_complex[v$i]"
    done
    filter_complex="$filter_complex concat=n=${#images[@]}:v=1:a=0[video]"
    
    # Add subtitles with word-by-word highlighting
    if [ -f "$subtitle_file" ]; then
        filter_complex="$filter_complex;[video]subtitles='$subtitle_file':force_style='FontSize=32,PrimaryColour=&H00FFFF00,OutlineColour=&H00000000,Outline=3,Bold=1,Alignment=2'[video_with_subs]"
        local video_output="[video_with_subs]"
    else
        local video_output="[video]"
    fi
    
    # Add CTA text overlay for last 5 seconds
    filter_complex="$filter_complex;${video_output}drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:text='CLICK LINK BELOW ↓':fontcolor=white:fontsize=42:box=1:boxcolor=black@0.7:boxborderw=10:x=(w-text_w)/2:y=h-180:enable='gte(t,20)'[final_video]"
    
    # Create temp content video
    local temp_content="${OUTPUT_DIR}/temp_content_$(date +%s).mp4"
    
    ffmpeg $inputs -i "$audio_file" \
        -filter_complex "$filter_complex" \
        -map "[final_video]" -map "$((${#images[@]})):a" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -c:a aac -b:a 128k -ar 44100 \
        -t $DURATION \
        -y "$temp_content" 2>&1 | grep -v "frame="
    
    log_info "Content section created"
    
    # Create CTA screen
    local temp_cta="${OUTPUT_DIR}/temp_cta_$(date +%s).mp4"
    create_cta_screen "$rumble_url" "$temp_cta"
    
    # Concatenate content + CTA (optional - already has text overlay)
    # For now, just use the content video with CTA overlay
    mv "$temp_content" "$output_file"
    rm -f "$temp_cta"  # Remove if not using
    
    # Get video stats
    local file_size=$(du -h "$output_file" | cut -f1)
    
    log_info "Teaser created: $output_file"
    log_info "Size: $file_size"
    
    echo "$output_file"
}

# Main function
main() {
    log_info "=== Starting Teaser Video Creation ==="
    
    check_ffmpeg
    create_directories
    
    # Parse input (expects JSON)
    # Example: {"title": "...", "images": [...], "audio": "...", "subtitles": "...", "rumble_url": "..."}
    if [ -z "$1" ]; then
        log_error "Usage: $0 <story_json>"
        exit 1
    fi
    
    local input_json="$1"
    
    local title=$(echo "$input_json" | jq -r '.title')
    local images=$(echo "$input_json" | jq -c '.images')
    local audio=$(echo "$input_json" | jq -r '.audio')
    local subtitles=$(echo "$input_json" | jq -r '.subtitles')
    local rumble_url=$(echo "$input_json" | jq -r '.rumble_url')
    
    # Generate output filename
    local safe_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '_' | cut -c1-30)
    local output_file="${OUTPUT_DIR}/teaser_${safe_title}_$(date +%Y%m%d_%H%M%S).mp4"
    
    # Create teaser
    local result=$(create_teaser "$title" "$images" "$audio" "$subtitles" "$rumble_url" "$output_file")
    
    log_info "=== Teaser Creation Complete ==="
    
    # Return JSON result
    echo "{\"video_path\": \"$output_file\", \"duration\": $DURATION, \"rumble_url\": \"$rumble_url\"}"
}

# Run main
main "$@"
