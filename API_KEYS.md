# API Keys Acquisition Guide

Complete step-by-step guide for obtaining all API keys and credentials needed for the news automation system.

## 📋 Overview of Required APIs

| Service | Purpose | Cost | Required |
|---------|---------|------|----------|
| OpenAI | Script generation (GPT-4) | Pay-per-use ($36-90/mo) | ✅ Yes |
| ElevenLabs / Google TTS | Text-to-speech voiceover | $22/mo or $4/mo | ✅ Yes |
| Pexels | Royalty-free images | FREE | ✅ Yes |
| Unsplash | Royalty-free images | FREE | ✅ Yes |
| Rumble | Video upload (monetization) | FREE (earns money!) | ✅ Yes |
| YouTube Data API v3 | Shorts upload | FREE (with quotas) | ✅ Yes |
| Instagram Graph API | Reels upload | FREE | ✅ Yes |
| Facebook Graph API | Reels upload | FREE | ✅ Yes |
| TikTok | Video upload | Varies | ⚠️ Limited |
| PostgreSQL / Airtable | Database | FREE / $10/mo | ✅ Yes |

**Total Monthly Cost: $82-187** | **Expected Revenue: $10,000+**

---

## 1. OpenAI API (GPT-4) 🤖

### Purpose
Generate AI-powered news scripts for both long-form and short-form videos

### Sign Up Process
1. Go to https://platform.openai.com/signup
2. Create account with email or Google/Microsoft
3. Verify your email address
4. Add payment method (required for GPT-4 access)

### Getting API Key
1. Navigate to https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Name it "news-automation-n8n"
4. **Copy the key immediately** (won't be shown again!)
5. Store in your `.env` file as `OPENAI_API_KEY=sk-...`

### Pricing (2025)
- **GPT-4 Turbo**: $0.01 per 1K input tokens, $0.03 per 1K output tokens
- **Estimated cost per script**: $0.02-$0.05
- **Monthly estimate** (360 cycles × 5 stories): ~$36-$90/month

### Rate Limits
- Tier 1 (new accounts): 500 requests per day
- Tier 2 ($50+ spent): 5,000 requests per day
- **This system uses**: ~60 requests per day (well within limits)

### Testing Your Key
```bash
curl https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "gpt-4-turbo",
    "messages": [{"role": "user", "content": "Test connection"}],
    "max_tokens": 10
  }'
```

✅ **Success response**: You'll get JSON with a text completion

---

## 2. ElevenLabs (Text-to-Speech) 🎙️

### Purpose
Generate natural-sounding AI voiceovers for videos

### Sign Up Process
1. Go to https://elevenlabs.io/
2. Click "Get Started Free"
3. Create account with email or Google
4. Choose a plan (Creator plan recommended)

### Getting API Key
1. Go to https://elevenlabs.io/app/settings/api-keys
2. Click "Generate API Key"
3. Name it "news-automation"
4. Copy and store as `ELEVENLABS_API_KEY=...`

### Pricing
- **Free**: 10,000 characters/month (~8 minutes audio)
- **Creator**: $22/month - 100,000 characters (~80 minutes) ⭐ **RECOMMENDED**
- **Pro**: $99/month - 500,000 characters

### Best Voices for News
- **"Rachel"** - Professional female news anchor
- **"Adam"** - Professional male news anchor
- **"Antoni"** - Authoritative male voice

Test voices at: https://elevenlabs.io/voice-library

### Testing
```bash
curl -X POST "https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM" \
  -H "xi-api-key: YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text": "Test voiceover", "model_id": "eleven_monolingual_v1"}' \
  --output test.mp3
```

---

## 3. Google Cloud Text-to-Speech (Alternative) 🗣️

### Purpose
Lower-cost alternative to ElevenLabs (less natural sounding)

### Setup Process
1. Go to https://console.cloud.google.com/
2. Create new project: "news-automation"
3. Enable "Cloud Text-to-Speech API"
4. Go to APIs & Services → Credentials
5. Create credentials → API key
6. Restrict key to Text-to-Speech API only

### Pricing
- **FREE**: 1 million characters/month for Standard voices
- **Paid**: $4 per 1 million characters (much cheaper than ElevenLabs)

### Testing
```bash
curl -X POST "https://texttospeech.googleapis.com/v1/text:synthesize" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: YOUR_API_KEY" \
  -d '{
    "input": {"text": "Test voiceover"},
    "voice": {"languageCode": "en-US", "name": "en-US-Neural2-D"},
    "audioConfig": {"audioEncoding": "MP3"}
  }'
```

---

## 4. Pexels API (Free Images) 📸

### Purpose
Download royalty-free images for video generation

### Sign Up Process
1. Go to https://www.pexels.com/api/
2. Click "Get Started"
3. Describe your use case: "Automated news video generation"
4. API key generated immediately

### Getting API Key
1. After signup, key is displayed on screen
2. Also available at https://www.pexels.com/api/
3. Store as `PEXELS_API_KEY=...`

### Pricing
- **COMPLETELY FREE** ✅
- No attribution required
- 200 requests per hour
- Perfect for this system

### Testing
```bash
curl -H "Authorization: YOUR_API_KEY" \
  "https://api.pexels.com/v1/search?query=celebrity&per_page=5"
```

---

## 5. Unsplash API (Free Images) 🖼️

### Purpose
Additional source for high-quality royalty-free images

### Sign Up Process
1. Go to https://unsplash.com/developers
2. Click "Register as a developer"
3. Create application: "News Automation System"
4. Description: "Automated news video generation"

### Getting API Key
1. After creating app, Access Key is displayed
2. Also available in your apps dashboard
3. Store as `UNSPLASH_ACCESS_KEY=...`

### Pricing
- **FREE**: 50 requests per hour
- No attribution required in development
- Production: Attribution recommended

### Testing
```bash
curl "https://api.unsplash.com/search/photos?query=news&client_id=YOUR_ACCESS_KEY"
```

---

## 6. Rumble (Video Upload - PRIMARY MONETIZATION) 💰

### Purpose
Upload long-form compilation videos for exclusive monetization

### Account Setup
1. Go to https://rumble.com/register
2. Create creator account
3. Verify email and complete profile
4. Apply for Creator Program at https://rumble.com/creator-program

### Getting API Access

⚠️ **Important**: Rumble doesn't have a public API yet

**Current Options**:

**Option A: Contact Rumble Support (Recommended)**
- Email: support@rumble.com
- Request: API access for automated uploads
- Mention: You're building a news automation system

**Option B: Browser Automation (Works Now)**
Use Puppeteer or Selenium to automate web uploads:

```javascript
// Example with Puppeteer
const puppeteer = require('puppeteer');

async function uploadToRumble(videoPath, title, description) {
  const browser = await puppeteer.launch({headless: false});
  const page = await browser.newPage();
  
  await page.goto('https://rumble.com/upload.php');
  
  // Login
  await page.type('input[name="login"]', process.env.RUMBLE_EMAIL);
  await page.type('input[name="password"]', process.env.RUMBLE_PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForNavigation();
  
  // Upload video
  const inputFile = await page.$('input[type="file"]');
  await inputFile.uploadFile(videoPath);
  
  // Fill details
  await page.type('input[name="title"]', title);
  await page.type('textarea[name="description"]', description);
  
  // Select licensing (IMPORTANT!)
  await page.select('select[name="rights"]', 'video_management'); // 90% revenue share
  
  // Submit
  await page.click('button[type="submit"]');
  
  // Wait for URL
  await page.waitForSelector('.video-url');
  const videoUrl = await page.$eval('.video-url', el => el.textContent);
  
  await browser.close();
  return videoUrl;
}
```

### Licensing Options (CRITICAL FOR REVENUE!)
When uploading to Rumble, choose:
- **"Video Management"** - Rumble can syndicate to partners (MSN, Yahoo, etc.)
  - **90% revenue share** ⭐ **CHOOSE THIS**
  - Best for maximum earnings
- **"Rumble Only"** - Only on Rumble platform
  - 60% revenue share
  - Lower earnings

### Store Credentials
```
RUMBLE_EMAIL=your@email.com
RUMBLE_PASSWORD=your_secure_password
```

---

## 7. YouTube Data API v3 (Shorts Upload) 📺

### Purpose
Upload 30-second teaser videos to YouTube Shorts

### Setup Process
1. Go to https://console.cloud.google.com/
2. Create new project: "news-automation-youtube"
3. Enable "YouTube Data API v3"
4. Configure OAuth consent screen:
   - Choose "External"
   - App name: "News Automation"
   - Add your email
   - Scopes: Add `https://www.googleapis.com/auth/youtube.upload`
5. Create OAuth 2.0 Client ID:
   - Application type: "Desktop app" or "Web application"
   - Download JSON credentials

### Getting OAuth Credentials
1. Download the credentials JSON file
2. Save as `youtube_credentials.json`
3. Run authentication flow (first time only):

```javascript
const {google} = require('googleapis');
const fs = require('fs');

const credentials = JSON.parse(fs.readFileSync('youtube_credentials.json'));
const {client_id, client_secret, redirect_uris} = credentials.installed;

const oauth2Client = new google.auth.OAuth2(
  client_id,
  client_secret,
  redirect_uris[0]
);

// Generate auth URL
const authUrl = oauth2Client.generateAuthUrl({
  access_type: 'offline',
  scope: ['https://www.googleapis.com/auth/youtube.upload']
});

console.log('Authorize this app by visiting:', authUrl);
// Visit URL, grant permission, copy the code
// Then exchange code for tokens:
// oauth2Client.getToken(code, (err, token) => {
//   oauth2Client.setCredentials(token);
//   fs.writeFileSync('youtube_token.json', JSON.stringify(token));
// });
```

### Pricing
- **FREE**: 10,000 quota units per day
- Upload video: 1,600 units per upload
- **Daily capacity**: ~6 uploads
- **This system**: 5 uploads per cycle = within limits ✅

### Store Tokens
```
YOUTUBE_CLIENT_ID=...
YOUTUBE_CLIENT_SECRET=...
YOUTUBE_REFRESH_TOKEN=...
```

---

## 8. Instagram Graph API (Reels) 📱

### Purpose
Upload teaser videos to Instagram Reels

### Setup Process
1. Go to https://developers.facebook.com/
2. Click "My Apps" → "Create App"
3. Choose "Business" type
4. App Display Name: "News Automation"
5. Add "Instagram" product
6. Configure Instagram Business Account connection

### Requirements
- Instagram Business or Creator account (convert in settings)
- Facebook Page linked to Instagram
- App approved for `instagram_content_publish` permission

### Getting Access Token
1. In App Dashboard → Instagram → Basic Display
2. Generate User Access Token
3. Token expires every 60 days - implement refresh logic

### Testing
```bash
curl -X POST "https://graph.facebook.com/v18.0/{ig-user-id}/media" \
  -F "video_url=YOUR_VIDEO_URL" \
  -F "caption=Test Reel #news" \
  -F "access_token=YOUR_ACCESS_TOKEN"
```

### Store Credentials
```
INSTAGRAM_USER_ID=...
INSTAGRAM_ACCESS_TOKEN=...
```

---

## 9. Facebook Graph API (Reels) 👥

### Purpose
Upload teaser videos to Facebook Reels

### Setup
Use same Facebook Developer app as Instagram (see above)

### Getting Page Access Token
1. In App Dashboard → Tools → Graph API Explorer
2. Select your Page
3. Generate token with permissions:
   - `pages_manage_posts`
   - `pages_read_engagement`
   - `publish_video`

### Testing
```bash
curl -X POST "https://graph.facebook.com/v18.0/{page-id}/videos" \
  -F "file_url=YOUR_VIDEO_URL" \
  -F "description=Test Reel - Full story on Rumble!" \
  -F "access_token=YOUR_PAGE_TOKEN"
```

### Store Credentials
```
FACEBOOK_PAGE_ID=...
FACEBOOK_PAGE_TOKEN=...
```

---

## 10. TikTok API ⚠️

### Purpose
Upload teaser videos to TikTok

### Challenge
TikTok's official API has very limited access for automated posting

### Options

**Option A: Official API (Difficult)**
1. Apply at https://developers.tiktok.com/
2. Business verification required
3. Approval process takes weeks-months
4. Limited to approved partners

**Option B: Third-Party Services (Easiest)**
- **Publer** (https://publer.io/) - $12/month, TikTok scheduling
- **Later** (https://later.com/) - Social media scheduler
- **SocialBee** (https://socialbee.com/) - TikTok automation

**Option C: Manual Upload (Recommended for now)**
1. System generates videos automatically
2. Upload manually via TikTok app or desktop
3. Takes 2-3 minutes per day

**Option D: Browser Automation (Advanced)**
```javascript
const puppeteer = require('puppeteer');

async function uploadToTikTok(videoPath, caption) {
  const browser = await puppeteer.launch({headless: false});
  const page = await browser.newPage();
  
  await page.goto('https://www.tiktok.com/upload');
  // Login and upload automation here
  
  await browser.close();
}
```

### Recommendation
Start with **manual uploads** or third-party service until you get official API access

---

## 11. PostgreSQL Database 🗄️

### Purpose
Track processed stories, video URLs, and performance metrics

### Option A: Self-Hosted (Free)

**Install PostgreSQL:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib

# macOS
brew install postgresql
brew services start postgresql
```

**Create Database:**
```bash
sudo -u postgres psql

CREATE DATABASE news_automation;
CREATE USER newsbot WITH PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE news_automation TO newsbot;
\q
```

**Connection String:**
```
postgresql://newsbot:your_secure_password_here@localhost:5432/news_automation
```

Store as: `DATABASE_URL=postgresql://...`

### Option B: Hosted Services (Free Tiers)

**Supabase** (Recommended)
- 500MB free database
- PostgreSQL-compatible
- Nice dashboard
- Sign up: https://supabase.com/

**Neon**
- 3GB free
- Serverless PostgreSQL
- Sign up: https://neon.tech/

**ElephantSQL**
- 20MB free (tiny but enough for testing)
- Sign up: https://www.elephantsql.com/

### Testing Connection
```bash
psql $DATABASE_URL -c "SELECT version();"
```

---

## 12. Airtable (Alternative to PostgreSQL) 📊

### Purpose
Easy-to-use database alternative with visual interface

### Setup
1. Go to https://airtable.com/signup
2. Create workspace: "News Automation"
3. Create base: "Story Tracking"
4. Create table with fields:
   - story_hash (Single line text)
   - story_url (URL)
   - story_title (Single line text)
   - published_date (Date)
   - processed_date (Date)
   - rumble_video_url (URL)
   - short_video_urls (Long text - JSON)
   - platforms (Multiple select)
   - views_total (Number)
   - revenue_earned (Currency)

### Getting API Key
1. Go to https://airtable.com/account
2. Click "Generate API key"
3. Copy and store as `AIRTABLE_API_KEY=...`

### Get Base ID
1. Open your base
2. URL contains Base ID: `https://airtable.com/app{BASE_ID}/...`
3. Store as `AIRTABLE_BASE_ID=app...`

### Pricing
- **Free**: 1,200 records per base (enough for testing)
- **Plus**: $10/user/month - 5,000 records

### Testing
```bash
curl "https://api.airtable.com/v0/YOUR_BASE_ID/Stories" \
  -H "Authorization: Bearer YOUR_API_KEY"
```

---

## 🔒 Storing API Keys Securely in n8n

### Method 1: n8n Credentials Manager (Recommended)

1. **Open n8n** → Go to "Credentials" in left sidebar
2. **Add Credentials** for each service:

**For OpenAI:**
- Credential Type: "OpenAI"
- API Key: Paste your `sk-...` key

**For HTTP APIs (Pexels, Unsplash, etc.):**
- Credential Type: "Header Auth"
- Name: "Authorization"
- Value: "YOUR_API_KEY"

**For PostgreSQL:**
- Credential Type: "Postgres"
- Host: localhost (or remote URL)
- Database: news_automation
- User: newsbot
- Password: your_password

### Method 2: Environment Variables

Create `.env` file in your project root:

```bash
# AI Services
OPENAI_API_KEY=sk-proj-...
ELEVENLABS_API_KEY=...

# OR Google TTS
GOOGLE_TTS_API_KEY=...

# Image APIs
PEXELS_API_KEY=...
UNSPLASH_ACCESS_KEY=...

# Social Platforms
YOUTUBE_CLIENT_ID=...
YOUTUBE_CLIENT_SECRET=...
YOUTUBE_REFRESH_TOKEN=...

INSTAGRAM_USER_ID=...
INSTAGRAM_ACCESS_TOKEN=...

FACEBOOK_PAGE_ID=...
FACEBOOK_PAGE_TOKEN=...

# Rumble (for browser automation)
RUMBLE_EMAIL=your@email.com
RUMBLE_PASSWORD=your_password

# Database
DATABASE_URL=postgresql://newsbot:password@localhost:5432/news_automation

# OR Airtable
AIRTABLE_API_KEY=key...
AIRTABLE_BASE_ID=app...
```

⚠️ **IMPORTANT**: Add `.env` to `.gitignore` - NEVER commit API keys to GitHub!

---

## 🔐 Security Best Practices

✅ **DO:**
- Use n8n Credentials for encrypted storage
- Rotate API keys every 3-6 months
- Set up billing alerts on paid APIs
- Use read-only database credentials where possible
- Enable 2FA on all accounts
- Monitor API usage regularly

❌ **DON'T:**
- Commit `.env` files to git
- Share API keys in screenshots
- Use the same password across services
- Store keys in plain text files
- Hard-code keys in scripts

---

## 📊 Cost Summary

| Service | Monthly Cost | Notes |
|---------|--------------|-------|
| OpenAI GPT-4 | $36-$90 | Pay-per-use |
| ElevenLabs | $22 | Creator plan (recommended) |
| Google TTS (alt) | $4 | Much cheaper alternative |
| Pexels | FREE | ✅ |
| Unsplash | FREE | ✅ |
| Rumble | FREE | **Earns money!** 💰 |
| YouTube API | FREE | ✅ |
| Instagram API | FREE | ✅ |
| Facebook API | FREE | ✅ |
| PostgreSQL | $0-$25 | Free self-hosted or free tiers |
| Airtable (alt) | $0-$10 | Free tier available |
| n8n Cloud | $20-$50 | Or self-host for free |
| **TOTAL** | **$82-$187/mo** | |

### Expected Revenue
- **Conservative**: $10,000+/month from Rumble
- **ROI**: 5,000%+ return on investment 🚀

---

## ✅ API Setup Checklist

Track your progress:

- [ ] OpenAI API key obtained and tested
- [ ] ElevenLabs API key obtained (or Google TTS)
- [ ] Pexels API key obtained and tested
- [ ] Unsplash API key obtained and tested
- [ ] Rumble creator account created
- [ ] Rumble monetization enabled
- [ ] YouTube OAuth credentials configured
- [ ] Instagram Business account connected
- [ ] Facebook Page Access Token generated
- [ ] TikTok upload method chosen
- [ ] Database created (PostgreSQL or Airtable)
- [ ] All credentials added to n8n
- [ ] `.env` file created and secured
- [ ] Test API calls successful for all services
- [ ] `.env` added to `.gitignore`

---

## 🆘 Troubleshooting Common Issues

### OpenAI: "Insufficient quota"
**Solution**: Add payment method to your account at https://platform.openai.com/account/billing

### YouTube: "Daily limit exceeded"
**Solution**: Create additional Google Cloud projects - each gets 10,000 quota units/day

### Instagram/Facebook: "Invalid access token"
**Solution**: Tokens expire every 60 days. Implement automatic refresh or manually regenerate.

### Pexels/Unsplash: Rate limit errors
**Solution**: 
- Implement image caching
- Reuse images for similar topics
- Spread requests across time

### Database connection failed
**Solution**:
- Check firewall allows connections
- Verify credentials are correct
- For PostgreSQL: ensure `pg_hba.conf` allows remote connections
- Test with: `psql $DATABASE_URL`

### Rumble upload fails
**Solution**:
- Verify account is approved for Creator Program
- Check video format (MP4, H.264 codec recommended)
- Ensure video is under size limit (usually 5GB)

---

## 📚 Additional Resources

- [n8n Credentials Documentation](https://docs.n8n.io/credentials/)
- [OpenAI Rate Limits Guide](https://platform.openai.com/docs/guides/rate-limits)
- [YouTube API Quota Calculator](https://developers.google.com/youtube/v3/determine_quota_cost)
- [Instagram API Documentation](https://developers.facebook.com/docs/instagram-api)
- [FFmpeg Installation Guide](https://ffmpeg.org/download.html)

---

**🎉 You now have everything needed to set up all API integrations!**

Next step: See SETUP.md for installing n8n and importing the workflow.

---

*Last updated: 2025-10-29*
