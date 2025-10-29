-- Multi-Channel News Automation Database Schema
-- PostgreSQL 12+
-- Updated: 2025-01-29

-- Extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- ============================================
-- CHANNELS TABLE
-- ============================================
CREATE TABLE channels (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL UNIQUE,
    slug VARCHAR(255) NOT NULL UNIQUE,
    niche VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Configuration (stored as JSONB)
    config JSONB NOT NULL DEFAULT '{}'::jsonb,
    
    -- Status
    active BOOLEAN DEFAULT true,
    last_run_at TIMESTAMP,
    next_run_at TIMESTAMP,
    
    -- Statistics
    total_videos INTEGER DEFAULT 0,
    total_views INTEGER DEFAULT 0,
    total_revenue DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by VARCHAR(255),
    
    -- Indexes
    CONSTRAINT channels_slug_check CHECK (slug ~ '^[a-z0-9-]+$')
);

-- Indexes for channels
CREATE INDEX idx_channels_niche ON channels(niche);
CREATE INDEX idx_channels_active ON channels(active);
CREATE INDEX idx_channels_slug ON channels(slug);
CREATE INDEX idx_channels_config ON channels USING GIN(config);

-- ============================================
-- PROCESSED STORIES TABLE (Enhanced)
-- ============================================
CREATE TABLE processed_stories (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    
    -- Channel association
    channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    
    -- Story identification
    story_hash VARCHAR(64) UNIQUE NOT NULL,
    story_url TEXT NOT NULL,
    story_title TEXT NOT NULL,
    story_content TEXT,
    story_keywords TEXT[],
    story_summary TEXT,
    
    -- Source information
    rss_feed_name VARCHAR(255),
    rss_feed_url TEXT,
    source_domain VARCHAR(255),
    
    -- Timestamps
    published_date TIMESTAMP,
    processed_date TIMESTAMP DEFAULT NOW(),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Video URLs
    rumble_video_url TEXT,
    rumble_video_id VARCHAR(255),
    youtube_shorts_url TEXT,
    tiktok_url TEXT,
    instagram_reel_url TEXT,
    facebook_reel_url TEXT,
    snapchat_url TEXT,
    
    -- Platform metadata (JSONB for flexibility)
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
    
    -- Engagement rates
    engagement_rate DECIMAL(5, 2),
    watch_time_seconds INTEGER,
    avg_watch_percentage DECIMAL(5, 2),
    
    -- Revenue tracking
    revenue_earned DECIMAL(10, 2) DEFAULT 0.00,
    revenue_currency VARCHAR(3) DEFAULT 'USD',
    rpm DECIMAL(6, 2), -- Revenue per mille (thousand views)
    
    -- Click-through tracking
    ctr_rate DECIMAL(5, 2),
    rumble_clicks INTEGER DEFAULT 0,
    
    -- Processing status
    status VARCHAR(50) DEFAULT 'processing',
    processing_duration_seconds INTEGER,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- AI generation metadata
    ai_script_tokens INTEGER,
    ai_script_cost DECIMAL(6, 4),
    tts_characters INTEGER,
    tts_cost DECIMAL(6, 4),
    
    -- Video file info
    longform_file_path TEXT,
    longform_file_size_mb DECIMAL(8, 2),
    longform_duration_seconds INTEGER,
    teaser_file_paths JSONB,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for processed_stories
CREATE INDEX idx_stories_channel_id ON processed_stories(channel_id);
CREATE INDEX idx_stories_hash ON processed_stories(story_hash);
CREATE INDEX idx_stories_published_date ON processed_stories(published_date DESC);
CREATE INDEX idx_stories_processed_date ON processed_stories(processed_date DESC);
CREATE INDEX idx_stories_status ON processed_stories(status);
CREATE INDEX idx_stories_views ON processed_stories(views_total DESC);
CREATE INDEX idx_stories_revenue ON processed_stories(revenue_earned DESC);
CREATE INDEX idx_stories_channel_date ON processed_stories(channel_id, processed_date DESC);
CREATE INDEX idx_stories_platform_meta ON processed_stories USING GIN(platform_metadata);
CREATE INDEX idx_stories_metadata ON processed_stories USING GIN(metadata);

-- Full-text search index
CREATE INDEX idx_stories_search ON processed_stories USING GIN(
    to_tsvector('english', 
        COALESCE(story_title, '') || ' ' || 
        COALESCE(story_content, '') || ' ' ||
        COALESCE(array_to_string(story_keywords, ' '), '')
    )
);

-- ============================================
-- API USAGE TABLE
-- ============================================
CREATE TABLE api_usage (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER REFERENCES channels(id) ON DELETE SET NULL,
    service_name VARCHAR(100) NOT NULL,
    endpoint VARCHAR(255),
    request_count INTEGER DEFAULT 1,
    tokens_used INTEGER DEFAULT 0,
    characters_used INTEGER DEFAULT 0,
    cost_usd DECIMAL(10, 4) DEFAULT 0.00,
    execution_time_ms INTEGER,
    status_code INTEGER,
    error_message TEXT,
    request_metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for api_usage
CREATE INDEX idx_api_channel ON api_usage(channel_id);
CREATE INDEX idx_api_service ON api_usage(service_name, created_at DESC);
CREATE INDEX idx_api_created ON api_usage(created_at DESC);

-- ============================================
-- WORKFLOW EXECUTIONS TABLE
-- ============================================
CREATE TABLE workflow_executions (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE NOT NULL,
    channel_id INTEGER REFERENCES channels(id) ON DELETE CASCADE,
    execution_id VARCHAR(255) UNIQUE,
    workflow_name VARCHAR(255),
    
    -- Status
    status VARCHAR(50) NOT NULL, -- success, error, running, cancelled
    started_at TIMESTAMP DEFAULT NOW(),
    finished_at TIMESTAMP,
    duration_seconds INTEGER,
    
    -- Metrics
    stories_processed INTEGER DEFAULT 0,
    videos_created INTEGER DEFAULT 0,
    videos_uploaded INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    
    -- Details
    error_details JSONB,
    performance_metrics JSONB,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Indexes for workflow_executions
CREATE INDEX idx_exec_channel ON workflow_executions(channel_id);
CREATE INDEX idx_exec_id ON workflow_executions(execution_id);
CREATE INDEX idx_exec_status ON workflow_executions(status);
CREATE INDEX idx_exec_started ON workflow_executions(started_at DESC);

-- ============================================
-- RSS FEEDS TABLE
-- ============================================
CREATE TABLE rss_feeds (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER REFERENCES channels(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    url TEXT NOT NULL,
    category VARCHAR(100),
    priority INTEGER DEFAULT 2,
    active BOOLEAN DEFAULT true,
    
    -- Fetch history
    last_checked TIMESTAMP,
    last_successful_fetch TIMESTAMP,
    fetch_count INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    last_error TEXT,
    
    -- Stats
    stories_found_total INTEGER DEFAULT 0,
    stories_used_total INTEGER DEFAULT 0,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(channel_id, url)
);

-- Indexes for rss_feeds
CREATE INDEX idx_feeds_channel ON rss_feeds(channel_id);
CREATE INDEX idx_feeds_active ON rss_feeds(active);
CREATE INDEX idx_feeds_priority ON rss_feeds(priority);
CREATE INDEX idx_feeds_last_checked ON rss_feeds(last_checked DESC);

-- ============================================
-- PERFORMANCE METRICS TABLE (Time-series)
-- ============================================
CREATE TABLE performance_metrics (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    metric_date DATE NOT NULL,
    metric_hour INTEGER CHECK (metric_hour >= 0 AND metric_hour <= 23),
    
    -- Video metrics
    videos_created INTEGER DEFAULT 0,
    videos_uploaded INTEGER DEFAULT 0,
    
    -- View metrics
    views_total INTEGER DEFAULT 0,
    views_rumble INTEGER DEFAULT 0,
    views_youtube INTEGER DEFAULT 0,
    views_tiktok INTEGER DEFAULT 0,
    views_instagram INTEGER DEFAULT 0,
    views_facebook INTEGER DEFAULT 0,
    
    -- Engagement metrics
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    avg_ctr DECIMAL(5, 2),
    avg_watch_time INTEGER,
    
    -- Revenue metrics
    revenue_total DECIMAL(10, 2) DEFAULT 0.00,
    revenue_rumble DECIMAL(10, 2) DEFAULT 0.00,
    avg_rpm DECIMAL(6, 2),
    
    -- Cost metrics
    cost_total DECIMAL(10, 4) DEFAULT 0.00,
    cost_openai DECIMAL(10, 4) DEFAULT 0.00,
    cost_tts DECIMAL(10, 4) DEFAULT 0.00,
    cost_other DECIMAL(10, 4) DEFAULT 0.00,
    
    -- Profit
    net_profit DECIMAL(10, 2) DEFAULT 0.00,
    
    created_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(channel_id, metric_date, metric_hour)
);

-- Indexes for performance_metrics
CREATE INDEX idx_metrics_channel_date ON performance_metrics(channel_id, metric_date DESC);
CREATE INDEX idx_metrics_date ON performance_metrics(metric_date DESC);

-- ============================================
-- VIEWS
-- ============================================

-- Daily performance per channel
CREATE OR REPLACE VIEW daily_channel_performance AS
SELECT 
    c.id as channel_id,
    c.name as channel_name,
    c.niche,
    ps.processed_date::date as date,
    COUNT(*) as stories_processed,
    SUM(ps.views_total) as total_views,
    SUM(ps.views_rumble) as rumble_views,
    SUM(ps.revenue_earned) as total_revenue,
    AVG(ps.ctr_rate) as avg_ctr,
    SUM(ps.rumble_clicks) as total_clicks,
    SUM(ps.ai_script_cost + ps.tts_cost) as ai_costs
FROM channels c
LEFT JOIN processed_stories ps ON ps.channel_id = c.id
GROUP BY c.id, c.name, c.niche, ps.processed_date::date
ORDER BY date DESC, channel_name;

-- Monthly revenue summary per channel
CREATE OR REPLACE VIEW monthly_channel_revenue AS
SELECT 
    c.id as channel_id,
    c.name as channel_name,
    c.niche,
    DATE_TRUNC('month', ps.processed_date) as month,
    COUNT(*) as stories_processed,
    SUM(ps.views_total) as total_views,
    SUM(ps.revenue_earned) as total_revenue,
    AVG(ps.revenue_earned) as avg_revenue_per_story,
    SUM(ps.ai_script_cost + ps.tts_cost) as total_costs,
    SUM(ps.revenue_earned) - SUM(ps.ai_script_cost + ps.tts_cost) as net_profit,
    (SUM(ps.revenue_earned) - SUM(ps.ai_script_cost + ps.tts_cost)) / NULLIF(SUM(ps.ai_script_cost + ps.tts_cost), 0) * 100 as roi_percentage
FROM channels c
LEFT JOIN processed_stories ps ON ps.channel_id = c.id
WHERE ps.revenue_earned > 0
GROUP BY c.id, c.name, c.niche, DATE_TRUNC('month', ps.processed_date)
ORDER BY month DESC, total_revenue DESC;

-- Channel comparison view
CREATE OR REPLACE VIEW channel_comparison AS
SELECT 
    c.id,
    c.name,
    c.niche,
    c.active,
    c.total_videos,
    c.total_views,
    c.total_revenue,
    COUNT(ps.id) as stories_last_30_days,
    AVG(ps.views_total) as avg_views_per_video,
    AVG(ps.revenue_earned) as avg_revenue_per_video,
    MAX(ps.processed_date) as last_video_date
FROM channels c
LEFT JOIN processed_stories ps ON ps.channel_id = c.id 
    AND ps.processed_date >= NOW() - INTERVAL '30 days'
GROUP BY c.id, c.name, c.niche, c.active, c.total_videos, c.total_views, c.total_revenue
ORDER BY c.total_revenue DESC;

-- Platform performance comparison
CREATE OR REPLACE VIEW platform_performance_by_channel AS
SELECT 
    c.name as channel_name,
    'rumble' as platform,
    SUM(ps.views_rumble) as total_views,
    AVG(ps.views_rumble) as avg_views,
    SUM(ps.revenue_earned) as total_revenue
FROM channels c
JOIN processed_stories ps ON ps.channel_id = c.id
GROUP BY c.name
UNION ALL
SELECT 
    c.name,
    'youtube' as platform,
    SUM(ps.views_youtube),
    AVG(ps.views_youtube),
    0
FROM channels c
JOIN processed_stories ps ON ps.channel_id = c.id
GROUP BY c.name
UNION ALL
SELECT 
    c.name,
    'tiktok' as platform,
    SUM(ps.views_tiktok),
    AVG(ps.views_tiktok),
    0
FROM channels c
JOIN processed_stories ps ON ps.channel_id = c.id
GROUP BY c.name
UNION ALL
SELECT 
    c.name,
    'instagram' as platform,
    SUM(ps.views_instagram),
    AVG(ps.views_instagram),
    0
FROM channels c
JOIN processed_stories ps ON ps.channel_id = c.id
GROUP BY c.name
ORDER BY channel_name, platform;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_channels_updated_at BEFORE UPDATE ON channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rss_feeds_updated_at BEFORE UPDATE ON rss_feeds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Generate story hash function
CREATE OR REPLACE FUNCTION generate_story_hash(story_url TEXT, story_title TEXT)
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(digest(story_url || story_title, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update channel statistics function
CREATE OR REPLACE FUNCTION update_channel_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE channels 
    SET 
        total_videos = (SELECT COUNT(*) FROM processed_stories WHERE channel_id = NEW.channel_id),
        total_views = (SELECT COALESCE(SUM(views_total), 0) FROM processed_stories WHERE channel_id = NEW.channel_id),
        total_revenue = (SELECT COALESCE(SUM(revenue_earned), 0) FROM processed_stories WHERE channel_id = NEW.channel_id),
        updated_at = NOW()
    WHERE id = NEW.channel_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update channel stats when story is updated
CREATE TRIGGER update_channel_stats_on_story_change
AFTER INSERT OR UPDATE OF views_total, revenue_earned ON processed_stories
FOR EACH ROW EXECUTE FUNCTION update_channel_stats();

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Insert sample channel (commented out for production)
/*
INSERT INTO channels (name, slug, niche, config) VALUES
('Celebrity News Daily', 'celebrity-news-daily', 'celebrity', 
 '{"branding": {"primary_color": "#FF0000"}, "monetization": {"target_cpm": 7.5}}'::jsonb);
*/

-- ============================================
-- USEFUL QUERIES (commented)
-- ============================================

-- Get today's performance for all channels
-- SELECT * FROM daily_channel_performance WHERE date = CURRENT_DATE;

-- Get top performing channels this month
-- SELECT * FROM monthly_channel_revenue WHERE month = DATE_TRUNC('month', NOW()) ORDER BY total_revenue DESC;

-- Find channels that haven't run recently
-- SELECT name, last_run_at FROM channels WHERE active = true AND (last_run_at IS NULL OR last_run_at < NOW() - INTERVAL '4 hours');

-- Get total system revenue
-- SELECT SUM(total_revenue) as system_revenue FROM channels;

-- Find duplicate stories
-- SELECT story_hash, COUNT(*) FROM processed_stories GROUP BY story_hash HAVING COUNT(*) > 1;

-- API costs in last 30 days
-- SELECT service_name, SUM(cost_usd) as total_cost, COUNT(*) as requests FROM api_usage WHERE created_at >= NOW() - INTERVAL '30 days' GROUP BY service_name ORDER BY total_cost DESC;

-- Channel ROI analysis
-- SELECT channel_name, roi_percentage FROM monthly_channel_revenue WHERE month = DATE_TRUNC('month', NOW());

COMMENT ON TABLE channels IS 'Stores configuration and metadata for each news channel';
COMMENT ON TABLE processed_stories IS 'Tracks all processed news stories across all channels';
COMMENT ON TABLE api_usage IS 'Monitors API usage and costs per channel';
COMMENT ON TABLE workflow_executions IS 'Logs n8n workflow execution history';
COMMENT ON TABLE rss_feeds IS 'Manages RSS feed sources per channel';
COMMENT ON TABLE performance_metrics IS 'Time-series performance data for analytics';
