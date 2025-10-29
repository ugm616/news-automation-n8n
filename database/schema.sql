-- News Automation Database Schema
-- PostgreSQL 12+

-- Extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Main table for tracking processed stories
CREATE TABLE processed_stories (
    id SERIAL PRIMARY KEY,
    story_hash VARCHAR(64) UNIQUE NOT NULL,
    story_url TEXT NOT NULL,
    story_title TEXT NOT NULL,
    story_content TEXT,
    story_keywords TEXT[],
    
    -- Source information
    rss_feed_name VARCHAR(255),
    rss_feed_url TEXT,
    
    -- Timestamps
    published_date TIMESTAMP,
    processed_date TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Video information
    rumble_video_url TEXT,
    rumble_video_id VARCHAR(255),
    
    -- Short-form video URLs (JSON)
    youtube_shorts_url TEXT,
    tiktok_url TEXT,
    instagram_reel_url TEXT,
    facebook_reel_url TEXT,
    snapchat_url TEXT,
    
    -- Platform metadata (JSON)
    platform_metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Performance metrics
    views_total INTEGER DEFAULT 0,
    views_rumble INTEGER DEFAULT 0,
    views_youtube INTEGER DEFAULT 0,
    views_tiktok INTEGER DEFAULT 0,
    views_instagram INTEGER DEFAULT 0,
    views_facebook INTEGER DEFAULT 0,
    
    likes_total INTEGER DEFAULT 0,
    comments_total INTEGER DEFAULT 0,
    shares_total INTEGER DEFAULT 0,
    
    -- Revenue tracking
    revenue_earned DECIMAL(10, 2) DEFAULT 0.00,
    revenue_currency VARCHAR(3) DEFAULT 'USD',
    
    -- Click-through tracking
    ctr_rate DECIMAL(5, 2), -- Click-through rate percentage
    rumble_clicks INTEGER DEFAULT 0,
    
    -- Processing status
    status VARCHAR(50) DEFAULT 'processing',
    error_message TEXT,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Index for fast duplicate checking
CREATE INDEX idx_story_hash ON processed_stories(story_hash);

-- Index for date-based queries
CREATE INDEX idx_published_date ON processed_stories(published_date DESC);
CREATE INDEX idx_processed_date ON processed_stories(processed_date DESC);

-- Index for performance queries
CREATE INDEX idx_views_total ON processed_stories(views_total DESC);
CREATE INDEX idx_revenue ON processed_stories(revenue_earned DESC);

-- Index for status queries
CREATE INDEX idx_status ON processed_stories(status);

-- GIN index for JSONB columns
CREATE INDEX idx_platform_metadata ON processed_stories USING GIN(platform_metadata);
CREATE INDEX idx_metadata ON processed_stories USING GIN(metadata);

-- Full-text search index on title and content
CREATE INDEX idx_story_search ON processed_stories USING GIN(
    to_tsvector('english', story_title || ' ' || COALESCE(story_content, ''))
);

-- Table for tracking API usage and costs
CREATE TABLE api_usage (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255),
    request_count INTEGER DEFAULT 1,
    tokens_used INTEGER DEFAULT 0,
    cost_usd DECIMAL(10, 4) DEFAULT 0.00,
    execution_time_ms INTEGER,
    status_code INTEGER,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Index for API usage queries
CREATE INDEX idx_api_service ON api_usage(service_name, created_at DESC);
CREATE INDEX idx_api_created ON api_usage(created_at DESC);

-- Table for workflow execution tracking
CREATE TABLE workflow_executions (
    id SERIAL PRIMARY KEY,
    execution_id VARCHAR(255) UNIQUE,
    workflow_name VARCHAR(255),
    status VARCHAR(50), -- success, error, running
    started_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP,
    duration_seconds INTEGER,
    stories_processed INTEGER DEFAULT 0,
    videos_created INTEGER DEFAULT 0,
    videos_uploaded INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    error_details JSONB,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Index for execution tracking
CREATE INDEX idx_execution_id ON workflow_executions(execution_id);
CREATE INDEX idx_execution_status ON workflow_executions(status);
CREATE INDEX idx_execution_started ON workflow_executions(started_at DESC);

-- Table for RSS feed management
CREATE TABLE rss_feeds (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL UNIQUE,
    category VARCHAR(100),
    active BOOLEAN DEFAULT true,
    last_checked TIMESTAMP,
    last_successful_fetch TIMESTAMP,
    fetch_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for RSS feed queries
CREATE INDEX idx_rss_active ON rss_feeds(active);
CREATE INDEX idx_rss_last_checked ON rss_feeds(last_checked DESC);

-- View for daily performance summary
CREATE VIEW daily_performance AS
SELECT 
    processed_date::date as date,
    COUNT(*) as stories_processed,
    SUM(views_total) as total_views,
    SUM(views_rumble) as rumble_views,
    SUM(revenue_earned) as total_revenue,
    AVG(ctr_rate) as avg_ctr,
    SUM(rumble_clicks) as total_clicks
FROM processed_stories
GROUP BY processed_date::date
ORDER BY date DESC;

-- View for monthly revenue summary
CREATE VIEW monthly_revenue AS
SELECT 
    DATE_TRUNC('month', processed_date) as month,
    COUNT(*) as stories_processed,
    SUM(views_total) as total_views,
    SUM(revenue_earned) as total_revenue,
    AVG(revenue_earned) as avg_revenue_per_story,
    MIN(revenue_earned) as min_revenue,
    MAX(revenue_earned) as max_revenue
FROM processed_stories
WHERE revenue_earned > 0
GROUP BY DATE_TRUNC('month', processed_date)
ORDER BY month DESC;

-- View for platform comparison
CREATE VIEW platform_performance AS
SELECT 
    'rumble' as platform,
    SUM(views_rumble) as total_views,
    AVG(views_rumble) as avg_views_per_video,
    SUM(revenue_earned) as total_revenue
FROM processed_stories
UNION ALL
SELECT 
    'youtube' as platform,
    SUM(views_youtube) as total_views,
    AVG(views_youtube) as avg_views_per_video,
    0 as total_revenue
FROM processed_stories
UNION ALL
SELECT 
    'tiktok' as platform,
    SUM(views_tiktok) as total_views,
    AVG(views_tiktok) as avg_views_per_video,
    0 as total_revenue
FROM processed_stories
UNION ALL
SELECT 
    'instagram' as platform,
    SUM(views_instagram) as total_views,
    AVG(views_instagram) as avg_views_per_video,
    0 as total_revenue
FROM processed_stories
UNION ALL
SELECT 
    'facebook' as platform,
    SUM(views_facebook) as total_views,
    AVG(views_facebook) as avg_views_per_video,
    0 as total_revenue
FROM processed_stories;

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_rss_feeds_updated_at BEFORE UPDATE ON rss_feeds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate story hash (for duplicate detection)
CREATE OR REPLACE FUNCTION generate_story_hash(story_url TEXT, story_title TEXT)
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(digest(story_url || story_title, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

-- Sample data (optional - for testing)
-- INSERT INTO rss_feeds (name, url, category) VALUES
-- ('E! News', 'https://www.eonline.com/syndication/feeds/rssfeeds/topstories.xml', 'celebrity'),
-- ('TMZ', 'https://www.tmz.com/rss.xml', 'celebrity'),
-- ('People', 'https://people.com/feed/', 'celebrity');

-- Helpful queries for monitoring

-- Check today's performance
-- SELECT * FROM daily_performance WHERE date = CURRENT_DATE;

-- Check this month's revenue
-- SELECT * FROM monthly_revenue WHERE month = DATE_TRUNC('month', NOW());

-- Find top performing stories
-- SELECT story_title, views_total, revenue_earned 
-- FROM processed_stories 
-- ORDER BY revenue_earned DESC 
-- LIMIT 10;

-- Check for recent errors
-- SELECT story_title, error_message, processed_date 
-- FROM processed_stories 
-- WHERE status = 'error' 
-- ORDER BY processed_date DESC 
-- LIMIT 10;

-- API cost tracking
-- SELECT service_name, SUM(cost_usd) as total_cost, COUNT(*) as requests
-- FROM api_usage
-- WHERE created_at >= NOW() - INTERVAL '30 days'
-- GROUP BY service_name
-- ORDER BY total_cost DESC;

COMMENT ON TABLE processed_stories IS 'Tracks all processed news stories and their performance metrics';
COMMENT ON TABLE api_usage IS 'Tracks API usage and costs for monitoring';
COMMENT ON TABLE workflow_executions IS 'Tracks n8n workflow execution history';
COMMENT ON TABLE rss_feeds IS 'Manages RSS feed sources';
