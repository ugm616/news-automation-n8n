/**
 * Multi-Channel News Automation API
 * Provides REST API for managing channels and monitoring performance
 */

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const morgan = require('morgan');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection pool
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

// Test database connection
pool.on('connect', () => {
    console.log('✓ Database connected');
});

pool.on('error', (err) => {
    console.error('Database error:', err);
});

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true
}));
app.use(express.json());
app.use(morgan('combined'));

// Health check endpoint
app.get('/health', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            database: 'connected'
        });
    } catch (error) {
        res.status(500).json({
            status: 'unhealthy',
            error: error.message
        });
    }
});

// ============================================
// CHANNELS ENDPOINTS
// ============================================

// Get all channels
app.get('/api/channels', async (req, res) => {
    try {
        const result = await pool.query(`
            SELECT 
                id,
                uuid,
                name,
                slug,
                niche,
                description,
                active,
                total_videos,
                total_views,
                total_revenue,
                last_run_at,
                next_run_at,
                created_at,
                config
            FROM channels
            ORDER BY total_revenue DESC
        `);
        
        res.json({
            success: true,
            count: result.rows.length,
            channels: result.rows
        });
    } catch (error) {
        console.error('Error fetching channels:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get single channel by slug
app.get('/api/channels/:slug', async (req, res) => {
    try {
        const { slug } = req.params;
        
        const result = await pool.query(`
            SELECT * FROM channels WHERE slug = $1
        `, [slug]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Channel not found'
            });
        }
        
        res.json({
            success: true,
            channel: result.rows[0]
        });
    } catch (error) {
        console.error('Error fetching channel:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Create new channel
app.post('/api/channels', async (req, res) => {
    try {
        const { name, slug, niche, description, config } = req.body;
        
        // Validate required fields
        if (!name || !slug || !niche) {
            return res.status(400).json({
                success: false,
                error: 'Missing required fields: name, slug, niche'
            });
        }
        
        const result = await pool.query(`
            INSERT INTO channels (name, slug, niche, description, config)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING *
        `, [name, slug, niche, description || '', JSON.stringify(config || {})]);
        
        res.status(201).json({
            success: true,
            channel: result.rows[0]
        });
    } catch (error) {
        console.error('Error creating channel:', error);
        
        if (error.code === '23505') { // Unique violation
            return res.status(409).json({
                success: false,
                error: 'Channel with this name or slug already exists'
            });
        }
        
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Update channel
app.put('/api/channels/:slug', async (req, res) => {
    try {
        const { slug } = req.params;
        const { name, niche, description, config, active } = req.body;
        
        const result = await pool.query(`
            UPDATE channels
            SET 
                name = COALESCE($1, name),
                niche = COALESCE($2, niche),
                description = COALESCE($3, description),
                config = COALESCE($4, config),
                active = COALESCE($5, active),
                updated_at = NOW()
            WHERE slug = $6
            RETURNING *
        `, [name, niche, description, config ? JSON.stringify(config) : null, active, slug]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Channel not found'
            });
        }
        
        res.json({
            success: true,
            channel: result.rows[0]
        });
    } catch (error) {
        console.error('Error updating channel:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Delete channel
app.delete('/api/channels/:slug', async (req, res) => {
    try {
        const { slug } = req.params;
        
        const result = await pool.query(`
            DELETE FROM channels WHERE slug = $1 RETURNING id, name
        `, [slug]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Channel not found'
            });
        }
        
        res.json({
            success: true,
            message: `Channel "${result.rows[0].name}" deleted successfully`
        });
    } catch (error) {
        console.error('Error deleting channel:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============================================
// CHANNEL STATISTICS ENDPOINTS
// ============================================

// Get channel statistics
app.get('/api/channels/:slug/stats', async (req, res) => {
    try {
        const { slug } = req.params;
        const { period = '30d' } = req.query;
        
        // Determine date range
        let interval = '30 days';
        if (period === '7d') interval = '7 days';
        if (period === '24h') interval = '1 day';
        if (period === '1h') interval = '1 hour';
        
        const result = await pool.query(`
            SELECT 
                c.id,
                c.name,
                c.niche,
                COUNT(ps.id) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as videos_count,
                SUM(ps.views_total) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as total_views,
                SUM(ps.revenue_earned) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as revenue,
                AVG(ps.ctr_rate) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as avg_ctr,
                SUM(ps.rumble_clicks) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as rumble_clicks,
                SUM(ps.ai_script_cost + ps.tts_cost) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '${interval}') as ai_costs
            FROM channels c
            LEFT JOIN processed_stories ps ON ps.channel_id = c.id
            WHERE c.slug = $1
            GROUP BY c.id, c.name, c.niche
        `, [slug]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                error: 'Channel not found'
            });
        }
        
        const stats = result.rows[0];
        
        res.json({
            success: true,
            period,
            stats: {
                videos_count: parseInt(stats.videos_count) || 0,
                total_views: parseInt(stats.total_views) || 0,
                revenue: parseFloat(stats.revenue) || 0,
                avg_ctr: parseFloat(stats.avg_ctr) || 0,
                rumble_clicks: parseInt(stats.rumble_clicks) || 0,
                ai_costs: parseFloat(stats.ai_costs) || 0,
                net_profit: parseFloat(stats.revenue || 0) - parseFloat(stats.ai_costs || 0)
            }
        });
    } catch (error) {
        console.error('Error fetching channel stats:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get channel performance over time
app.get('/api/channels/:slug/performance', async (req, res) => {
    try {
        const { slug } = req.params;
        const { days = 30 } = req.query;
        
        const result = await pool.query(`
            SELECT 
                DATE(ps.processed_date) as date,
                COUNT(*) as videos,
                SUM(ps.views_total) as views,
                SUM(ps.revenue_earned) as revenue,
                AVG(ps.ctr_rate) as avg_ctr
            FROM channels c
            JOIN processed_stories ps ON ps.channel_id = c.id
            WHERE c.slug = $1
              AND ps.processed_date >= NOW() - INTERVAL '${parseInt(days)} days'
            GROUP BY DATE(ps.processed_date)
            ORDER BY date DESC
        `, [slug]);
        
        res.json({
            success: true,
            days: parseInt(days),
            data: result.rows
        });
    } catch (error) {
        console.error('Error fetching performance:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============================================
// STORIES ENDPOINTS
// ============================================

// Get stories for a channel
app.get('/api/channels/:slug/stories', async (req, res) => {
    try {
        const { slug } = req.params;
        const { limit = 50, offset = 0, status } = req.query;
        
        let statusFilter = '';
        if (status) {
            statusFilter = `AND ps.status = '${status}'`;
        }
        
        const result = await pool.query(`
            SELECT 
                ps.*
            FROM processed_stories ps
            JOIN channels c ON c.id = ps.channel_id
            WHERE c.slug = $1 ${statusFilter}
            ORDER BY ps.processed_date DESC
            LIMIT $2 OFFSET $3
        `, [slug, parseInt(limit), parseInt(offset)]);
        
        const countResult = await pool.query(`
            SELECT COUNT(*) as total
            FROM processed_stories ps
            JOIN channels c ON c.id = ps.channel_id
            WHERE c.slug = $1 ${statusFilter}
        `, [slug]);
        
        res.json({
            success: true,
            total: parseInt(countResult.rows[0].total),
            limit: parseInt(limit),
            offset: parseInt(offset),
            stories: result.rows
        });
    } catch (error) {
        console.error('Error fetching stories:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============================================
// DASHBOARD SUMMARY ENDPOINT
// ============================================

// Get overall system summary
app.get('/api/dashboard/summary', async (req, res) => {
    try {
        const summary = await pool.query(`
            SELECT 
                COUNT(DISTINCT c.id) as total_channels,
                COUNT(DISTINCT c.id) FILTER (WHERE c.active = true) as active_channels,
                SUM(c.total_videos) as total_videos,
                SUM(c.total_views) as total_views,
                SUM(c.total_revenue) as total_revenue,
                COUNT(ps.id) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '24 hours') as videos_24h,
                SUM(ps.views_total) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '24 hours') as views_24h,
                SUM(ps.revenue_earned) FILTER (WHERE ps.processed_date >= NOW() - INTERVAL '24 hours') as revenue_24h
            FROM channels c
            LEFT JOIN processed_stories ps ON ps.channel_id = c.id
        `);
        
        const topChannels = await pool.query(`
            SELECT 
                c.name,
                c.slug,
                c.niche,
                c.total_revenue,
                c.total_views
            FROM channels c
            WHERE c.active = true
            ORDER BY c.total_revenue DESC
            LIMIT 5
        `);
        
        res.json({
            success: true,
            summary: summary.rows[0],
            top_channels: topChannels.rows
        });
    } catch (error) {
        console.error('Error fetching dashboard summary:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============================================
// WORKFLOW EXECUTIONS
// ============================================

// Get recent workflow executions
app.get('/api/executions', async (req, res) => {
    try {
        const { limit = 20 } = req.query;
        
        const result = await pool.query(`
            SELECT 
                we.*,
                c.name as channel_name,
                c.slug as channel_slug
            FROM workflow_executions we
            LEFT JOIN channels c ON c.id = we.channel_id
            ORDER BY we.started_at DESC
            LIMIT $1
        `, [parseInt(limit)]);
        
        res.json({
            success: true,
            executions: result.rows
        });
    } catch (error) {
        console.error('Error fetching executions:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// ============================================
// START SERVER
// ============================================

const server = app.listen(PORT, () => {
    console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   📰 NEWS AUTOMATION API SERVER                          ║
║   Multi-Channel Management & Analytics                   ║
║                                                           ║
║   Server: http://localhost:${PORT}                        ║
║   Health: http://localhost:${PORT}/health                 ║
║   Docs:   http://localhost:${PORT}/api/docs               ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server...');
    server.close(() => {
        console.log('Server closed');
        pool.end(() => {
            console.log('Database pool closed');
            process.exit(0);
        });
    });
});
