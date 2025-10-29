#!/bin/bash

#==============================================================================
# Create Long-Form Video for Rumble
# Compiles 5 news stories into a 10-15 minute compilation video
#==============================================================================

set -e  # Exit on error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$SCRIPT_DIR/../output/videos}"
IMAGE_DIR="${IMAGE_DIR:-$SCRIPT_DIR/../output/images}"
AUDIO_DIR="${AUDIO_DIR:-$SCRIPT_DIR/../output/audio}"
SUBTITLE_DIR="${SUBTITLE_DIR:-$SCRIPT_DIR/../output/subtitles}"
TEMPLATE_DIR="${TEMPLATE_DIR:-$SCRIPT_DIR/../templates}"

# Video settings
WIDTH=1920
HEIGHT=1080
FPS=30
QUALITY=22
PRESET="medium"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if FFmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        log_error "FFmpeg is not installed. Please install it first."
        exit 1
    fi
    log_info "FFmpeg found: $(ffmpeg -version | head -n 1)"
}

# Create necessary directories
create_directories() {
    mkdir -p "$OUTPUT_DIR" "$IMAGE_DIR" "$AUDIO_DIR" "$SUBTITLE_DIR"
    log_info "Directories created"
}

# Generate intro video
create_intro() {
    local date_str="$1"
    local output_file="$2"
    
    log_info "Creating intro segment..."
    
    # Create intro with text overlay
    ffmpeg -f lavfi -i color=c=black:s=${WIDTH}x${HEIGHT}:d=5 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='TOP 5 STORIES':fontcolor=white:fontsize=80:x=(w-text_w)/2:y=(h-text_h)/2-100,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='$date_str':fontcolor=gray:fontsize=40:x=(w-text_w)/2:y=(h-text_h)/2+100" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "Intro created: $output_file"
}

# Generate transition video
create_transition() {
    local story_num="$1"
    local output_file="$2"
    
    log_info "Creating transition for story $story_num..."
    
    ffmpeg -f lavfi -i color=c=black:s=${WIDTH}x${HEIGHT}:d=3 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='STORY $story_num':fontcolor=white:fontsize=60:x=(w-text_w)/2:y=(h-text_h)/2" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "Transition created: $output_file"
}

# Generate outro video
create_outro() {
    local output_file="$1"
    
    log_info "Creating outro segment..."
    
    ffmpeg -f lavfi -i color=c=black:s=${WIDTH}x${HEIGHT}:d=10 \
        -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='SUBSCRIBE FOR UPDATES':fontcolor=white:fontsize=60:x=(w-text_w)/2:y=(h-text_h)/2-100,\
drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf:\
text='Every 2 Hours':fontcolor=gray:fontsize=40:x=(w-text_w)/2:y=(h-text_h)/2+50" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "Outro created: $output_file"
}

# Create story segment from images and audio
create_story_segment() {
    local story_num="$1"
    local images_json="$2"
    local audio_file="$3"
    local subtitle_file="$4"
    local output_file="$5"
    
    log_info "Creating story segment $story_num..."
    
    # Parse image paths from JSON (assumes array of paths)
    # Example: ["image1.jpg", "image2.jpg", "image3.jpg"]
    local images=($(echo "$images_json" | jq -r '.[]'))
    
    if [ ${#images[@]} -eq 0 ]; then
        log_error "No images provided for story $story_num"
        return 1
    fi
    
    # Get audio duration
    local audio_duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$audio_file")
    
    # Calculate duration per image
    local duration_per_image=$(echo "$audio_duration / ${#images[@]}" | bc -l)
    
    log_info "Audio duration: ${audio_duration}s, Images: ${#images[@]}, Duration per image: ${duration_per_image}s"
    
    # Create video from images with Ken Burns effect
    local filter_complex=""
    local inputs=""
    
    for i in "${!images[@]}"; do
        inputs="$inputs -loop 1 -t $duration_per_image -i ${images[$i]}"
        
        # Ken Burns effect (zoom and pan)
        filter_complex="$filter_complex[$i:v]scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},zoompan=z='min(zoom+0.0015,1.3)':d=$(echo "$duration_per_image * $FPS" | bc):s=${WIDTH}x${HEIGHT}:fps=${FPS}"
        
        if [ $i -lt $((${#images[@]} - 1)) ]; then
            filter_complex="$filter_complex,fade=out:st=$(echo "$duration_per_image - 0.5" | bc):d=0.5[v$i];"
        else
            filter_complex="$filter_complex[v$i];"
        fi
    done
    
    # Concatenate all video segments
    for i in $(seq 0 $((${#images[@]} - 1))); do
        filter_complex="$filter_complex[v$i]"
    done
    filter_complex="$filter_complex concat=n=${#images[@]}:v=1:a=0[video]"
    
    # Add subtitles if provided
    if [ -f "$subtitle_file" ]; then
        filter_complex="$filter_complex;[video]subtitles='$subtitle_file':force_style='FontSize=24,PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,Outline=2,Bold=1,Alignment=2'[video_with_subs]"
        local video_output="[video_with_subs]"
    else
        local video_output="[video]"
    fi
    
    # Create video with audio
    ffmpeg $inputs -i "$audio_file" \
        -filter_complex "$filter_complex" \
        -map "$video_output" -map "$((${#images[@]})):a" \
        -c:v libx264 -preset $PRESET -crf $QUALITY -pix_fmt yuv420p \
        -c:a aac -b:a 192k -ar 44100 \
        -shortest \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "Story segment $story_num created: $output_file"
}

# Concatenate all segments into final video
concatenate_videos() {
    local segments=("$@")
    local concat_file="${OUTPUT_DIR}/concat_list.txt"
    
    log_info "Concatenating ${#segments[@]} segments..."
    
    # Create concat file
    > "$concat_file"
    for segment in "${segments[@]}"; do
        echo "file '$segment'" >> "$concat_file"
    done
    
    # Concatenate videos
    local output_file="${OUTPUT_DIR}/longform_$(date +%Y%m%d_%H%M%S).mp4"
    
    ffmpeg -f concat -safe 0 -i "$concat_file" \
        -c copy \
        -movflags +faststart \
        -y "$output_file" 2>&1 | grep -v "frame="
    
    log_info "Final video created: $output_file"
    
    # Cleanup concat file
    rm "$concat_file"
    
    # Output result
    echo "$output_file"
}

# Main function
main() {
    log_info "=== Starting Long-Form Video Creation ==="
    
    check_ffmpeg
    create_directories
    
    # Parse input arguments (expects JSON)
    # Example: {"date": "January 29, 2025", "stories": [...]}
    if [ -z "$1" ]; then
        log_error "Usage: $0 <stories_json>"
        exit 1
    fi
    
    local input_json="$1"
    local date_str=$(echo "$input_json" | jq -r '.date')
    local stories=$(echo "$input_json" | jq -c '.stories[]')
    
    log_info "Processing date: $date_str"
    
    # Create temp directory for segments
    local temp_dir="${OUTPUT_DIR}/temp_$(date +%s)"
    mkdir -p "$temp_dir"
    
    local segments=()
    
    # Create intro
    local intro_file="${temp_dir}/00_intro.mp4"
    create_intro "$date_str" "$intro_file"
    segments+=("$intro_file")
    
    # Process each story
    local story_num=1
    while IFS= read -r story; do
        log_info "Processing story $story_num..."
        
        # Create transition
        local transition_file="${temp_dir}/0${story_num}_transition.mp4"
        create_transition "$story_num" "$transition_file"
        segments+=("$transition_file")
        
        # Get story data
        local images=$(echo "$story" | jq -c '.images')
        local audio=$(echo "$story" | jq -r '.audio')
        local subtitles=$(echo "$story" | jq -r '.subtitles')
        
        # Create story segment
        local story_file="${temp_dir}/0${story_num}_story.mp4"
        create_story_segment "$story_num" "$images" "$audio" "$subtitles" "$story_file"
        segments+=("$story_file")
        
        ((story_num++))
    done <<< "$stories"
    
    # Create outro
    local outro_file="${temp_dir}/99_outro.mp4"
    create_outro "$outro_file"
    segments+=("$outro_file")
    
    # Concatenate all segments
    local final_video=$(concatenate_videos "${segments[@]}")
    
    # Get final video stats
    local file_size=$(du -h "$final_video" | cut -f1)
    local duration=$(ffprobe -v error -show_entries format=duration \
        -of default=noprint_wrappers=1:nokey=1 "$final_video" | awk '{printf "%.0f", $1}')
    local duration_formatted=$(printf '%dm %ds' $((duration/60)) $((duration%60)))
    
    log_info "=== Video Creation Complete ==="
    log_info "Output: $final_video"
    log_info "Size: $file_size"
    log_info "Duration: $duration_formatted"
    
    # Cleanup temp directory
    rm -rf "$temp_dir"
    log_info "Temporary files cleaned up"
    
    # Return path to final video
    echo "{\"video_path\": \"$final_video\", \"duration\": $duration, \"size\": \"$file_size\"}"
}

# Run main function
main "$@"
