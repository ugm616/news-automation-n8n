news-automation-n8n/
├── README.md
├── API-KEYS.md
├── SETUP.md
├── docker-compose.yml
├── quick_start.sh
│
├── template/                    # Master template for all channels
│   ├── config/
│   │   ├── .env.example
│   │   └── channel_config.json
│   ├── workflows/
│   │   └── main-workflow.json
│   └── scripts/
│       ├── create_longform_video.sh
│       └── create_teaser_video.sh
│
├── channels/                    # Individual channel instances
│   ├── celebrity-news-daily/
│   │   ├── .env
│   │   ├── config/
│   │   ├── output/
│   │   └── assets/
│   ├── sports-news-network/
│   ├── tech-today/
│   └── ...
│
├── config/
│   ├── rss_library.json        # RSS feeds for all niches
│   └── niche_configs/           # Pre-made configs
│       ├── celebrity.json
│       ├── sports.json
│       ├── politics.json
│       └── ...
│
├── prompts/
│   ├── niches/                  # Niche-specific prompts
│   │   ├── celebrity.txt
│   │   ├── sports.txt
│   │   ├── politics.txt
│   │   └── ...
│   └── universal/               # Universal prompts
│       ├── teaser_cta.txt
│       └── voice_instructions.txt
│
├── scripts/
│   ├── channel_manager.sh       # Create/deploy channels
│   ├── setup_branding.sh        # Generate branding
│   └── bulk_deploy.sh           # Deploy multiple channels
│
├── api/                         # Multi-channel API
│   ├── server.js
│   ├── package.json
│   └── routes/
│
├── dashboard/                   # Web dashboard
│   ├── index.html
│   ├── css/
│   └── js/
│
└── database/
    └── schema.sql
