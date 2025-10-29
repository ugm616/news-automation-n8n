# News Automation System with n8n

> 🤖 Automated news video generation and distribution system powered by n8n, AI, and multi-platform monetization

## 🎯 Overview

This system automatically creates and distributes news content every 2 hours:

1. **Scrapes RSS feeds** for top celebrity/entertainment news stories
2. **Generates AI-powered scripts** using OpenAI GPT-4
3. **Creates long-form compilation videos** (10-15 min) for Rumble
4. **Uploads to Rumble** for primary monetization (exclusive content)
5. **Creates 30-second teaser videos** for each story
6. **Distributes teasers** across 5 platforms to drive traffic
7. **Tracks performance** and prevents duplicate stories

## ✨ Key Features

- ✅ **Fully Automated**: Runs every 2 hours with zero manual intervention
- ✅ **AI-Powered**: GPT-4 scripts, ElevenLabs voiceover, automated subtitles
- ✅ **Multi-Platform**: YouTube Shorts, TikTok, Instagram Reels, Facebook Reels, Snapchat
- ✅ **Smart Monetization**: Long-form on Rumble ($1.40-$20 CPM), teasers drive traffic
- ✅ **Duplicate Prevention**: Database tracking ensures no repeated stories
- ✅ **Professional Quality**: FFmpeg-generated videos with transitions, subtitles, branding
- ✅ **Scalable**: Add more feeds, stories, or platforms easily

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────┐
│          SCHEDULE TRIGGER (Every 2 Hours)               │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│   RSS SCRAPING + DUPLICATE CHECK → Top 5 Stories        │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  AI CONTENT GENERATION (Scripts, Images, Voice, Subs)   │
└─────────────────────┬───────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌──────────────────┐       ┌──────────────────┐
│  LONG-FORM VIDEO │       │  SHORT-FORM      │
│  (10-15 minutes) │       │  TEASERS         │
│  16:9, 1920x1080 │       │  (30 seconds)    │
│                  │       │  9:16, 1080x1920 │
└────────┬─────────┘       └────────┬─────────┘
         │                          │
         ▼                          │
┌──────────────────┐                │
│  UPLOAD RUMBLE   │                │
│  Get Video URL   │                │
└────────┬─────────┘                │
         │                          │
         └──────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  DISTRIBUTE TEASERS (with Rumble deep links)            │
│  → YouTube Shorts, TikTok, Instagram, Facebook, Snap    │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│         DATABASE LOGGING (Performance Tracking)          │
└─────────────────────────────────────────────────────────┘
```

## 💰 Revenue Model

### Primary: Rumble Long-Form Videos
- **CPM**: $1.40-$20 per 1,000 views (avg $7.50)
- **Revenue Share**: Up to 90% for exclusive, syndicated content
- **No Requirements**: Monetize from day one (no subscriber minimums)

### Secondary: Short-Form Platforms
- YouTube Shorts, TikTok, Instagram Reels, Facebook Reels
- Lower CPM ($0.02-$0.33) but free traffic generation
- **Strategy**: Teasers act as ads driving viewers to high-CPM Rumble content

### Projected Revenue (Example)
```
Per 2-hour cycle:
- 5 stories × 5 platforms = 25 teaser videos
- 1 long-form Rumble compilation
- Avg 50,000 Rumble views (from teaser traffic)
- 50,000 × $7.50 / 1,000 = $375 per cycle

Daily (12 cycles): ~$4,500
Monthly potential: ~$135,000
```
*Results vary based on traffic, engagement, and niche*

## 🛠️ Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Automation** | n8n | Workflow orchestration |
| **Video Generation** | FFmpeg | Compile images, audio, subtitles |
| **AI Scripts** | OpenAI GPT-4 | Generate news narratives |
| **Voiceover** | ElevenLabs / Google TTS | Text-to-speech |
| **Images** | Pexels, Unsplash | Royalty-free visuals |
| **Primary Upload** | Rumble API | Exclusive long-form monetization |
| **Distribution** | YouTube, TikTok, Instagram, Facebook APIs | Short-form teasers |
| **Database** | PostgreSQL / Airtable | Story tracking, analytics |

## 🚀 Quick Start

### Prerequisites
- n8n instance (self-hosted or cloud.n8n.io)
- FFmpeg installed on server
- API keys for all services (see API-KEYS.md)
- 10GB+ storage for video files

### Installation

1. **Clone this repository**
```bash
git clone https://github.com/ugm616/news-automation-n8n.git
cd news-automation-n8n
```

2. **Install n8n** (if self-hosting)
```bash
npm install -g n8n
```

3. **Set up environment variables**
```bash
cp config/.env.example .env
# Edit .env with your API keys
```

4. **Import n8n workflow**
- Open n8n interface
- Go to Workflows → Import
- Upload `workflows/main-workflow.json`

5. **Configure credentials in n8n**
- Add all API keys in n8n Credentials manager
- Link credentials to workflow nodes

6. **Set up database**
```bash
psql -U postgres -f database/schema.sql
```

7. **Test the workflow**
- Click "Execute Workflow" in n8n
- Verify all nodes complete successfully

8. **Enable schedule**
- Activate the workflow
- System will run every 2 hours automatically

For detailed instructions, see SETUP.md

## 📚 Documentation

- **SETUP.md** - Complete installation and configuration guide
- **API-KEYS.md** - How to obtain API keys for all platforms
- **workflows/WORKFLOW-GUIDE.md** - n8n workflow explanation
- **docs/TROUBLESHOOTING.md** - Common issues and solutions
- **docs/OPTIMIZATION.md** - Performance tuning tips

## 📁 Repository Structure

```
news-automation-n8n/
├── README.md                          # This file
├── SETUP.md                           # Installation guide
├── API-KEYS.md                        # API key acquisition guide
├── workflows/
│   ├── main-workflow.json            # Complete n8n workflow (importable)
│   └── WORKFLOW-GUIDE.md             # Workflow documentation
├── scripts/
│   ├── create_longform_video.sh      # FFmpeg: Rumble compilation
│   ├── create_teaser_video.sh        # FFmpeg: 30-second teasers
│   ├── upload_to_rumble.sh           # Rumble API upload
│   └── generate_subtitles.py         # Subtitle generation
├── database/
│   ├── schema.sql                     # PostgreSQL schema
│   └── airtable-template.json        # Airtable alternative
├── config/
│   ├── .env.example                   # Environment variables template
│   └── rss_feeds.example.json        # RSS feed sources
├── prompts/
│   ├── longform_script_template.txt  # AI prompt for full scripts
│   ├── teaser_script_template.txt    # AI prompt for teasers
│   └── voice_instructions.txt        # TTS configuration
├── templates/
│   └── VIDEO-TEMPLATES.md            # Video template specs
└── docs/
    ├── TROUBLESHOOTING.md            # Common issues
    └── OPTIMIZATION.md               # Performance tips
```

## 🎬 Video Specifications

### Long-Form (Rumble)
- **Duration**: 10-15 minutes
- **Format**: 16:9 (1920×1080)
- **Structure**: Intro → 5 Stories → Outro
- **Elements**: Lower-thirds, transitions, background music, subtitles
- **Monetization**: Exclusive to Rumble (90% revenue share)

### Short-Form Teasers
- **Duration**: 30 seconds
- **Format**: 9:16 (1080×1920)
- **Structure**: 3s Hook + 22s Teaser + 5s CTA
- **CTA**: "Click link below for full story"
- **Platforms**: YouTube Shorts, TikTok, Instagram Reels, Facebook Reels, Snapchat

## 🔄 Workflow Process

1. **RSS Scraping** - Pull latest stories from configured feeds
2. **Duplicate Check** - Query database to filter out processed stories
3. **Story Selection** - Choose top 5 based on recency/engagement
4. **Script Generation** - Create long-form (90s) and teaser (25s) scripts
5. **Asset Collection** - Download images, generate voiceover and subtitles
6. **Long-Form Creation** - Compile 10-15 min video with all 5 stories
7. **Rumble Upload** - Upload and retrieve video URL
8. **Teaser Creation** - Generate 5×30s videos with Rumble deep links
9. **Multi-Platform Upload** - Distribute to all 5 platforms
10. **Logging** - Track URLs, views, performance metrics

## 🔐 Security & Best Practices

- Store all API keys in n8n Credentials (encrypted)
- Never commit `.env` files to version control
- Rotate API keys regularly
- Use read-only database credentials where possible
- Monitor API usage to avoid rate limits
- Set up error notifications (email, Slack, Discord)

## 📊 Performance Monitoring

The system tracks:
- Stories processed per cycle
- Video generation success rate
- Upload success by platform
- Views and engagement per video
- Click-through rate (teaser → Rumble)
- Revenue per cycle/day/month

## 🤝 Contributing

Contributions welcome! Areas for improvement:
- Additional platform integrations
- Video quality enhancements
- AI prompt optimization
- Performance improvements
- Documentation updates

## 📝 License

MIT License - See LICENSE for details

## ⚠️ Disclaimer

- Ensure you have rights to all RSS feed content used
- Follow each platform's terms of service
- Respect copyright and attribution requirements
- This system is for educational/commercial use - verify compliance with local laws
- API costs and monetization results will vary

## 🆘 Support

- **Issues**: Report bugs or request features via GitHub Issues
- **Discussions**: Ask questions in GitHub Discussions
- **Documentation**: Check docs/ folder for troubleshooting

## 🎓 Learning Resources

- [n8n Documentation](https://docs.n8n.io/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [OpenAI API Reference](https://platform.openai.com/docs)
- [Rumble Creator Guide](https://rumble.com/creator-program)

---

**Built with ❤️ for automated content creation and monetization**

*Last updated: 2025-10-29*
