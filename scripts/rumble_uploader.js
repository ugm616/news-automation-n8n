/**
 * Rumble Video Uploader
 * Automates video upload to Rumble using Puppeteer
 */

const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

// Configuration
const RUMBLE_URL = 'https://rumble.com';
const UPLOAD_URL = 'https://rumble.com/upload.php';
const TIMEOUT = 300000; // 5 minutes

// Get credentials from environment
const RUMBLE_EMAIL = process.env.RUMBLE_EMAIL;
const RUMBLE_PASSWORD = process.env.RUMBLE_PASSWORD;

if (!RUMBLE_EMAIL || !RUMBLE_PASSWORD) {
    console.error('[ERROR] RUMBLE_EMAIL and RUMBLE_PASSWORD must be set');
    process.exit(1);
}

// Parse input JSON
const inputJson = process.argv[2];
if (!inputJson) {
    console.error('[ERROR] Usage: node rumble_uploader.js <json>');
    process.exit(1);
}

const uploadData = JSON.parse(inputJson);
const {
    video_path,
    title,
    description,
    tags = [],
    license = 'video_management' // or 'rumble_only'
} = uploadData;

// Validate inputs
if (!video_path || !title) {
    console.error('[ERROR] video_path and title are required');
    process.exit(1);
}

if (!fs.existsSync(video_path)) {
    console.error(`[ERROR] Video file not found: ${video_path}`);
    process.exit(1);
}

/**
 * Upload video to Rumble
 */
async function uploadToRumble() {
    console.log('[INFO] Launching browser...');
    
    const browser = await puppeteer.launch({
        headless: false, // Set to true in production
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const page = await browser.newPage();
    await page.setViewport({ width: 1920, height: 1080 });
    
    try {
        // Go to Rumble
        console.log('[INFO] Navigating to Rumble...');
        await page.goto(RUMBLE_URL, { waitUntil: 'networkidle2' });
        
        // Click login button
        console.log('[INFO] Logging in...');
        await page.waitForSelector('a[href*="login"]', { timeout: 10000 });
        await page.click('a[href*="login"]');
        
        // Wait for login form
        await page.waitForSelector('input[name="username"], input[type="email"]', { timeout: 10000 });
        
        // Enter credentials
        await page.type('input[name="username"], input[type="email"]', RUMBLE_EMAIL);
        await page.type('input[name="password"], input[type="password"]', RUMBLE_PASSWORD);
        
        // Submit login
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle2' }),
            page.click('button[type="submit"]')
        ]);
        
        console.log('[INFO] Logged in successfully');
        
        // Navigate to upload page
        console.log('[INFO] Navigating to upload page...');
        await page.goto(UPLOAD_URL, { waitUntil: 'networkidle2' });
        
        // Wait for file input
        await page.waitForSelector('input[type="file"]', { timeout: 10000 });
        
        // Upload video file
        console.log(`[INFO] Uploading video: ${path.basename(video_path)}`);
        const fileInput = await page.$('input[type="file"]');
        await fileInput.uploadFile(video_path);
        
        // Wait for upload to complete (look for title input to appear)
        console.log('[INFO] Waiting for upload to complete...');
        await page.waitForSelector('input[name="title"]', { timeout: TIMEOUT });
        
        console.log('[INFO] Upload complete, filling details...');
        
        // Fill in title
        await page.type('input[name="title"]', title);
        
        // Fill in description
        if (description) {
            await page.type('textarea[name="description"]', description);
        }
        
        // Add tags
        if (tags.length > 0) {
            const tagInput = await page.$('input[name="tags"]');
            if (tagInput) {
                await page.type('input[name="tags"]', tags.join(', '));
            }
        }
        
        // Select license/rights
        console.log(`[INFO] Setting license to: ${license}`);
        const licenseSelect = await page.$('select[name="rights"]');
        if (licenseSelect) {
            await page.select('select[name="rights"]', license);
        }
        
        // Submit upload
        console.log('[INFO] Submitting video...');
        await Promise.all([
            page.waitForNavigation({ waitUntil: 'networkidle2', timeout: TIMEOUT }),
            page.click('button[type="submit"], input[type="submit"]')
        ]);
        
        // Wait a moment for redirect
        await page.waitForTimeout(3000);
        
        // Get video URL from current page
        const videoUrl = page.url();
        
        console.log('[INFO] Video uploaded successfully!');
        console.log(`[INFO] Video URL: ${videoUrl}`);
        
        // Output JSON result
        const result = {
            success: true,
            video_url: videoUrl,
            title: title,
            uploaded_at: new Date().toISOString()
        };
        
        console.log(JSON.stringify(result));
        
        await browser.close();
        return result;
        
    } catch (error) {
        console.error('[ERROR] Upload failed:', error.message);
        
        // Take screenshot for debugging
        const screenshotPath = path.join(__dirname, `error_${Date.now()}.png`);
        await page.screenshot({ path: screenshotPath });
        console.error(`[ERROR] Screenshot saved: ${screenshotPath}`);
        
        await browser.close();
        
        // Output error JSON
        const result = {
            success: false,
            error: error.message
        };
        console.log(JSON.stringify(result));
        
        process.exit(1);
    }
}

// Run upload
uploadToRumble();
