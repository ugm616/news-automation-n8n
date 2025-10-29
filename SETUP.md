# Setup Guide - News Automation System

Complete installation and configuration guide for the n8n news automation system.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Option A: n8n Cloud Setup](#option-a-n8n-cloud-setup-easiest)
3. [Option B: Self-Hosted n8n](#option-b-self-hosted-n8n)
4. [FFmpeg Installation](#ffmpeg-installation)
5. [Database Setup](#database-setup)
6. [Import Workflow](#import-workflow)
7. [Configure Credentials](#configure-credentials)
8. [Configure RSS Feeds](#configure-rss-feeds)
9. [Test the System](#test-the-system)
10. [Enable Automation](#enable-automation)
11. [Monitoring & Maintenance](#monitoring--maintenance)

---

## Prerequisites

### Required
- **Computer/Server**: Linux, macOS, or Windows
- **Node.js**: v18.0.0 or higher
- **Storage**: 10GB+ free space
- **Internet**: Stable connection for uploads
- **API Keys**: All services from API-KEYS.md

### Recommended Specs
- **RAM**: 4GB minimum, 8GB recommended
- **CPU**: 2 cores minimum, 4 cores recommended
- **Bandwidth**: Unlimited or high cap (uploads ~50GB/day)

---

## Option A: n8n Cloud Setup (Easiest)

### Step 1: Create n8n Cloud Account

1. Go to https://n8n.io/cloud
2. Click "Start Free"
3. Create account (email or Google)
4. Choose plan:
   - **Starter**: $20/month - 2,500 executions
   - **Pro**: $50/month - 10,000 executions
   - **Recommended**: Pro plan for 12 cycles/day

### Step 2: Access Your Instance

1. After signup, you'll get a URL: `https://YOUR-INSTANCE.app.n8n.cloud`
2. Bookmark this URL
3. Log in with your credentials

### Step 3: Enable Execution Data

1. In n8n, go to Settings → General
2. Enable "Save Execution Data"
3. Set retention to at least 7 days

### Step 4: Skip to [Import Workflow](#import-workflow)

---

## Option B: Self-Hosted n8n

### Step 1: Install Node.js

**Ubuntu/Debian:**
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
node --version  # Should show v18.x or higher
```

**macOS:**
```bash
brew install node@18
node --version
```

**Windows:**
Download from https://nodejs.org/ and install

### Step 2: Install n8n Globally

```bash
npm install -g n8n
```

### Step 3: Create n8n Working Directory

```bash
mkdir -p ~/n8n-data
cd ~/n8n-data
```

### Step 4: Configure Environment Variables

Create `.env` file:
```bash
nano .env
```

Add:
```bash
# n8n Configuration
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=your_secure_password_here

# Execution Settings
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true

# Storage
N8N_USER_FOLDER=~/n8n-data
```

### Step 5: Start n8n

**Development:**
```bash
n8n
```

**Production (with PM2):**
```bash
# Install PM2
npm install -g pm2

# Start n8n with PM2
pm2 start n8n

# Set to auto-start on boot
pm2 startup
pm2 save
```

### Step 6: Access n8n

Open browser: http://localhost:5678

---

## FFmpeg Installation

FFmpeg is required for video generation.

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y ffmpeg

# Verify installation
ffmpeg -version
```

### macOS

```bash
brew install ffmpeg

# Verify installation
ffmpeg -version
```

### Windows

1. Download from https://ffmpeg.org/download.html
2. Extract to `C:\ffmpeg`
3. Add to PATH:
   - Search "Environment Variables"
   - Edit "Path" variable
   - Add `C:\ffmpeg\bin`
4. Restart terminal and verify:
   ```cmd
   ffmpeg -version
   ```

### Verify Required Codecs

```bash
ffmpeg -codecs | grep h264  # Should show libx264
ffmpeg -codecs | grep aac   # Should show AAC encoder
```

---

## Database Setup

Choose either PostgreSQL or Airtable.

### Option A: PostgreSQL (Recommended)

#### Install PostgreSQL

**Ubuntu/Debian:**
```bash
sudo apt-get install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

#### Create Database

```bash
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE DATABASE news_automation;
CREATE USER newsbot WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE news_automation TO newsbot;

# Exit
\q
```

#### Load Schema

```bash
# Clone this repository first
git clone https://github.com/ugm616/news-automation-n8n.git
cd news-automation-n8n

# Load schema
psql -U newsbot -d news_automation -f database/schema.sql
```

#### Test Connection

```bash
psql -U newsbot -d news_automation -c "SELECT * FROM processed_stories LIMIT 5;"
```

#### Connection String

```
postgresql://newsbot:your_secure_password@localhost:5432/news_automation
```

Store this in n8n credentials as `DATABASE_URL`

### Option B: Airtable (Easier Setup)

1. Sign up at https://airtable.com/
2. Create new base: "News Automation"
3. Create table: "processed_stories"
4. Add fields:
   - `story_hash` (Single line text)
   - `story_url` (URL)
   - `story_title` (Single line text)
   - `published_date` (Date)
   - `processed_date` (Date)
   - `rumble_video_url` (URL)
   - `short_video_urls` (Long text)
   - `platforms` (Multiple select)
   - `views_total` (Number)
   - `revenue_earned` (Currency)
5. Get API key from https://airtable.com/account
6. Get Base ID from your base URL: `app...`

---

## Import Workflow

### Step 1: Download Workflow

```bash
# Clone repository
git clone https://github.com/ugm616/news-automation-n8n.git
cd news-automation-n8n
```

### Step 2: Import into n8n

1. Open n8n interface
2. Click "Workflows" in left sidebar
3. Click "Import from File"
4. Select `workflows/main-workflow.json`
5. Workflow will load with all nodes

### Step 3: Review Workflow

The workflow contains these main sections:
- **Trigger**: Schedule node (every 2 hours)
- **RSS Scraping**: Multiple RSS Feed nodes
- **Duplicate Check**: PostgreSQL/Airtable query
- **Content Generation**: OpenAI, ElevenLabs, Pexels
- **Video Creation**: Execute Command nodes (FFmpeg)
- **Rumble Upload**: HTTP Request or Execute Command
- **Multi-Platform Upload**: YouTube, Instagram, Facebook, TikTok
- **Logging**: Database insert

---

## Configure Credentials

### Step 1: Add Credentials in n8n

1. Click "Credentials" in left sidebar
2. Click "Add Credential" for each service

### Step 2: OpenAI Credentials

- Type: "OpenAI"
- API Key: Your `sk-...` key from API-KEYS.md
- Save as: "OpenAI - News Automation"

### Step 3: HTTP Header Auth (for Pexels, Unsplash, etc.)

For each API:
- Type: "Header Auth"
- Name: "Authorization"
- Value: Your API key
- Save with descriptive name

**Pexels:**
- Name: "Authorization"
- Value: `YOUR_PEXELS_KEY`

**Unsplash:**
- Name: "Authorization"
- Value: `Client-ID YOUR_UNSPLASH_KEY`

### Step 4: PostgreSQL Credentials

- Type: "Postgres"
- Host: `localhost` (or remote host)
- Database: `news_automation`
- User: `newsbot`
- Password: Your password
- Port: `5432`
- SSL: `disable` (or `require` for remote)

### Step 5: YouTube OAuth2

- Type: "Google OAuth2 API"
- Auth URI: `https://accounts.google.com/o/oauth2/auth`
- Token URI: `https://oauth2.googleapis.com/token`
- Client ID: From Google Cloud Console
- Client Secret: From Google Cloud Console
- Scope: `https://www.googleapis.com/auth/youtube.upload`

Click "Connect my account" and authorize

### Step 6: Instagram/Facebook

- Type: "HTTP Request"
- Authentication: "Generic Credential Type"
- Add header:
  - Name: "Authorization"
  - Value: `Bearer YOUR_ACCESS_TOKEN`

### Step 7: Link Credentials to Nodes

1. Open workflow
2. Click each node that needs credentials
3. Select appropriate credential from dropdown
4. Save

---

## Configure RSS Feeds

### Step 1: Edit RSS Feed Configuration

Edit `config/rss_feeds.example.json` and rename to `rss_feeds.json`:

```json
{
  "feeds": [
    {
      "name": "E! News",
      "url": "https://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml",
      "category": "celebrity"
    },
    {
      "name": "TMZ",
      "url": "https://www.tmz.com/rss.xml",
      "category": "celebrity"
    },
    {
      "name": "People Magazine",
      "url": "https://people.com/feed/",
      "category": "celebrity"
    },
    {
      "name": "Entertainment Weekly",
      "url": "https://ew.com/feed/",
      "category": "entertainment"
    },
    {
      "name": "Hollywood Reporter",
      "url": "https://www.hollywoodreporter.com/feed/",
      "category": "entertainment"
    }
  ]
}
```

### Step 2: Update RSS Nodes in Workflow

For each RSS Feed node:
1. Click node
2. Set "URL" to feed URL
3. Set "Options" → "Limit" to 10 items

---

## Test the System

### Step 1: Test Individual Nodes

Test each section separately:

**1. Test RSS Scraping:**
- Click RSS Feed node
- Click "Execute Node"
- Verify you get news items

**2. Test Database Connection:**
- Click PostgreSQL node (duplicate check)
- Click "Execute Node"
- Should return empty result (no duplicates yet)

**3. Test OpenAI:**
- Click OpenAI node
- Add test input: `{"title": "Test Story"}`
- Click "Execute Node"
- Should return generated script

**4. Test Image Download:**
- Click Pexels node
- Add test query: `{"query": "celebrity"}`
- Click "Execute Node"
- Should return image URLs

**5. Test TTS:**
- Click ElevenLabs node
- Add test text: `{"text": "Test voiceover"}`
- Click "Execute Node"
- Should return audio file

### Step 2: Test Video Generation

```bash
# Navigate to scripts directory
cd scripts

# Test long-form video script
./create_longform_video.sh test

# Check output
ls -lh output/
```

### Step 3: Test Complete Workflow

1. In n8n workflow editor
2. Click "Execute Workflow" button (top right)
3. Watch nodes execute in sequence
4. Check for errors (red nodes)
5. Review output data

**Expected Results:**
- ✅ 5 stories scraped
- ✅ Duplicates filtered out
- ✅ Scripts generated for all 5
- ✅ Images downloaded
- ✅ Voiceovers created
- ✅ 1 long-form video created
- ✅ Uploaded to Rumble
- ✅ 5 teaser videos created
- ✅ Uploaded to all platforms
- ✅ Logged to database

### Step 4: Verify Uploads

Check each platform:
- **Rumble**: https://rumble.com/user/YOUR_USERNAME
- **YouTube**: https://studio.youtube.com/
- **Instagram**: Check your profile
- **Facebook**: Check your page
- **TikTok**: Check your profile

---

## Enable Automation

### Step 1: Configure Schedule

1. Click "Schedule Trigger" node
2. Set trigger rules:
   - **Mode**: "Interval"
   - **Interval**: 2 hours
   - **Or use Cron**: `0 */2 * * *`

### Step 2: Activate Workflow

1. Toggle "Active" switch (top right)
2. Workflow will now run every 2 hours automatically

### Step 3: Monitor First Run

- Wait for next scheduled time
- Check "Executions" tab to see it run
- Verify all nodes complete successfully

---

## Monitoring & Maintenance

### Daily Monitoring

**Check n8n Executions:**
1. Go to "Executions" tab
2. Review latest runs
3. Check for errors (red status)

**Check Platform Performance:**
- Rumble views and revenue
- Short-form engagement
- Click-through rates

**Database Queries:**
```sql
-- Today's processed stories
SELECT * FROM processed_stories 
WHERE processed_date::date = CURRENT_DATE;

-- Total views this week
SELECT SUM(views_total) as total_views 
FROM processed_stories 
WHERE processed_date >= NOW() - INTERVAL '7 days';

-- Revenue this month
SELECT SUM(revenue_earned) as total_revenue 
FROM processed_stories 
WHERE processed_date >= DATE_TRUNC('month', NOW());
```

### Weekly Maintenance

- Review and remove old video files
- Check API usage and costs
- Rotate API keys if needed
- Update RSS feeds if any are broken
- Review error logs

### Storage Management

```bash
# Delete videos older than 7 days
find ~/n8n-data/videos -name "*.mp4" -mtime +7 -delete

# Check disk usage
df -h
```

### Backup Strategy

**Database Backup:**
```bash
# PostgreSQL
pg_dump -U newsbot news_automation > backup_$(date +%Y%m%d).sql

# Airtable
# Manual export from Airtable interface
```

**Workflow Backup:**
1. In n8n, go to workflow
2. Click "..." menu → "Download"
3. Save JSON file weekly

---

## Troubleshooting

### n8n Won't Start

```bash
# Check if port is in use
lsof -i :5678

# Kill process if needed
kill -9 PID

# Restart n8n
n8n
```

### FFmpeg Not Found

```bash
# Check installation
which ffmpeg

# If not found, reinstall
# Ubuntu:
sudo apt-get install ffmpeg

# macOS:
brew install ffmpeg
```

### Database Connection Failed

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -U newsbot -d news_automation -c "SELECT 1;"
```

### API Rate Limits

If you hit rate limits:
- **OpenAI**: Upgrade tier or reduce requests
- **Pexels**: Cache images, reduce unique searches
- **YouTube**: Create multiple Google Cloud projects
- **Instagram/Facebook**: Implement token refresh

### Video Upload Fails

- Check file size (< 5GB for most platforms)
- Verify video format (MP4, H.264, AAC audio)
- Test manual upload first
- Check API credentials are valid

### Out of Disk Space

```bash
# Find large files
du -sh ~/n8n-data/*

# Clean old videos
rm -rf ~/n8n-data/videos/*.mp4

# Clean old logs
journalctl --vacuum-time=7d
```

---

## Optimization Tips

### Reduce Costs

1. **Use Google TTS instead of ElevenLabs** - Saves $18/month
2. **Cache downloaded images** - Reduce API calls
3. **Self-host n8n** - Saves $20-50/month
4. **Use Airtable free tier** - Saves $10/month

### Improve Performance

1. **Run on faster server** - Better video encoding
2. **Use SSD storage** - Faster file operations
3. **Increase FFmpeg threads** - Add `-threads 4` to scripts
4. **Parallel processing** - Split workflow into sub-workflows

### Scale Up

1. **Increase to 10 stories per cycle** - More content
2. **Run every hour instead of 2 hours** - 2x output
3. **Add more RSS feeds** - Better story selection
4. **Add more platforms** - Wider distribution

---

## Next Steps

Once everything is running:

1. **Monitor performance** for first week
2. **Adjust RSS feeds** based on story quality
3. **Optimize video generation** (thumbnails, titles)
4. **A/B test CTAs** in teaser videos
5. **Scale up gradually** as revenue grows

---

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PM2 Process Manager](https://pm2.keymetrics.io/)

---

## Getting Help

- **GitHub Issues**: Report bugs at https://github.com/ugm616/news-automation-n8n/issues
- **n8n Community**: https://community.n8n.io/
- **Documentation**: Check docs/ folder in this repo

---

**🎉 Setup Complete! Your automation is ready to generate revenue 24/7!**

*Last updated: 2025-10-29*
