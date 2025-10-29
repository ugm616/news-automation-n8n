#!/bin/bash
# Generate channel-specific branding assets

CHANNEL_NAME=$1
NICHE=$2
PRIMARY_COLOR=$3
SECONDARY_COLOR=$4

echo "Setting up branding for: $CHANNEL_NAME"

# Create directories
mkdir -p "channels/$CHANNEL_NAME/assets/{logos,watermarks,intros,outros,thumbnails}"

# Generate intro video with channel name
ffmpeg -f lavfi -i color=c=$PRIMARY_COLOR:s=1920x1080:d=5 \
  -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='$CHANNEL_NAME':fontcolor=$SECONDARY_COLOR:fontsize=80:x=(w-text_w)/2:y=(h-text_h)/2" \
  -y "channels/$CHANNEL_NAME/assets/intros/intro.mp4"

# Generate thumbnail template
ffmpeg -f lavfi -i color=c=$PRIMARY_COLOR:s=1280x720:d=0.1 \
  -vf "drawtext=fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf:\
text='$CHANNEL_NAME':fontcolor=$SECONDARY_COLOR:fontsize=60:x=(w-text_w)/2:y=50" \
  -frames:v 1 \
  -y "channels/$CHANNEL_NAME/assets/thumbnails/template.png"

echo "✅ Branding assets created"
