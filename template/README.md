# Channel Template

This is the master template for all news automation channels. When creating a new channel, this template is copied and customized.

## Template Structure

template/ ├── config/ │ ├── .env.example # Environment variables template │ └── channel_config.json # Channel configuration template ├── scripts/ │ ├── create_longform_video.sh │ ├── create_teaser_video.sh │ ├── upload_to_rumble.sh │ └── generate_subtitles.py ├── prompts/ │ ├── longform_script_template.txt │ ├── teaser_script_template.txt │ └── voice_instructions.txt └── workflows/ └── main-workflow.json

## Usage

### Automated (Recommended)
```bash
./quick_start.sh

./scripts/channel_manager.sh create <niche> "Channel Name"

Customization
After creating a channel from this template:

Edit config/channel_config.json with channel-specific settings
Update .env with your API keys
Customize prompts/ for niche-specific language
Adjust branding in assets/ directory
Do Not Modify
This template directory should not be modified directly. Instead:

Make changes to individual channel instances
Or update the template and recreate channels
Version
Template Version: 1.0.0 Last Updated: 2025-01-29

