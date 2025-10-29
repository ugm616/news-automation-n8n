const express = require('express');
const app = express();
const { Pool } = require('pg');

const pool = new Pool({
    connectionString: process.env.DATABASE_URL
});

// Get all channels
app.get('/api/channels', async (req, res) => {
    const result = await pool.query(`
        SELECT * FROM channel_performance
    `);
    res.json(result.rows);
});

// Get channel details
app.get('/api/channels/:id', async (req, res) => {
    const { id } = req.params;
    const result = await pool.query(`
        SELECT * FROM channels WHERE id = $1
    `, [id]);
    res.json(result.rows[0]);
});

// Create new channel
app.post('/api/channels', async (req, res) => {
    const { name, niche, config } = req.body;
    const result = await pool.query(`
        INSERT INTO channels (name, niche, config)
        VALUES ($1, $2, $3)
        RETURNING *
    `, [name, niche, JSON.stringify(config)]);
    res.json(result.rows[0]);
});

// Get channel stats
app.get('/api/channels/:id/stats', async (req, res) => {
    const { id } = req.params;
    const result = await pool.query(`
        SELECT 
            COUNT(*) FILTER (WHERE DATE(processed_date) = CURRENT_DATE) as videos_today,
            SUM(views_total) as total_views,
            SUM(revenue_earned) FILTER (WHERE DATE(processed_date) = CURRENT_DATE) as revenue_today,
            AVG(ctr_rate) as ctr
        FROM processed_stories
        WHERE channel_id = $1
    `, [id]);
    res.json(result.rows[0]);
});

app.listen(3000, () => {
    console.log('Multi-channel API running on port 3000');
});
