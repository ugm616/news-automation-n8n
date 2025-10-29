/**
 * News Automation Dashboard - Client-Side JavaScript
 */

// Configuration
const API_BASE_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:3000/api'
    : '/api';

const REFRESH_INTERVAL = 60000; // 60 seconds
let refreshTimer = null;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
    console.log('🚀 News Automation Dashboard initialized');
    loadDashboard();
    startAutoRefresh();
});

// Load all dashboard data
async function loadDashboard() {
    try {
        await Promise.all([
            loadSystemOverview(),
            loadChannels(),
            loadRecentActivity(),
            loadTopPerformers()
        ]);
    } catch (error) {
        console.error('Error loading dashboard:', error);
        showError('Failed to load dashboard data');
    }
}

// Load system overview stats
async function loadSystemOverview() {
    try {
        const response = await fetch(`${API_BASE_URL}/dashboard/summary`);
        const data = await response.json();
        
        if (data.success) {
            const summary = data.summary;
            
            // Update stats
            document.getElementById('total-channels').textContent = summary.active_channels || 0;
            document.getElementById('videos-today').textContent = summary.videos_24h || 0;
            document.getElementById('total-views').textContent = formatNumber(summary.total_views || 0);
            document.getElementById('revenue-today').textContent = '$' + formatNumber(summary.revenue_24h || 0);
            
            // Update change indicators
            document.getElementById('channels-change').textContent = `${summary.active_channels} active`;
            document.getElementById('videos-change').textContent = `in last 24h`;
            document.getElementById('views-change').textContent = `${formatNumber(summary.views_24h || 0)} today`;
            document.getElementById('revenue-change').textContent = `+${((summary.revenue_24h / summary.total_revenue) * 100).toFixed(1)}%`;
        }
    } catch (error) {
        console.error('Error loading overview:', error);
    }
}

// Load channels
async function loadChannels() {
    try {
        const response = await fetch(`${API_BASE_URL}/channels`);
        const data = await response.json();
        
        if (data.success && data.channels) {
            displayChannels(data.channels);
        }
    } catch (error) {
        console.error('Error loading channels:', error);
    }
}

// Display channels in grid
function displayChannels(channels) {
    const grid = document.getElementById('channels-grid');
    
    if (channels.length === 0) {
        grid.innerHTML = `
            <div class="loading-spinner">
                <p>No channels found. Create your first channel!</p>
                <button class="btn btn-primary" onclick="showCreateChannel()">
                    <span class="icon">➕</span> Create Channel
                </button>
            </div>
        `;
        return;
    }
    
    grid.innerHTML = channels.map(channel => `
        <div class="channel-card" data-status="${channel.active ? 'active' : 'inactive'}">
            <div class="channel-header">
                <div class="channel-info">
                    <h3>${channel.name}</h3>
                    <span class="channel-niche">${channel.niche}</span>
                </div>
                <div class="channel-status ${channel.active ? 'active' : 'inactive'}"></div>
            </div>
            
            <div class="channel-stats">
                <div class="channel-stat">
                    <div class="channel-stat-value">${formatNumber(channel.total_videos)}</div>
                    <div class="channel-stat-label">Videos</div>
                </div>
                <div class="channel-stat">
                    <div class="channel-stat-value">${formatNumber(channel.total_views)}</div>
                    <div class="channel-stat-label">Views</div>
                </div>
                <div class="channel-stat">
                    <div class="channel-stat-value">$${formatNumber(channel.total_revenue)}</div>
                    <div class="channel-stat-label">Revenue</div>
                </div>
            </div>
            
            <div class="channel-actions">
                <button class="btn btn-outline" onclick="viewChannel('${channel.slug}')">
                    <span class="icon">📊</span> View
                </button>
                <button class="btn btn-secondary" onclick="manageChannel('${channel.slug}')">
                    <span class="icon">⚙️</span> Manage
                </button>
            </div>
        </div>
    `).join('');
}

// Load recent activity
async function loadRecentActivity() {
    try {
        const response = await fetch(`${API_BASE_URL}/executions?limit=10`);
        const data = await response.json();
        
        if (data.success && data.executions) {
            displayActivity(data.executions);
        }
    } catch (error) {
        console.error('Error loading activity:', error);
    }
}

// Display recent activity
function displayActivity(executions) {
    const feed = document.getElementById('activity-feed');
    
    if (executions.length === 0) {
        feed.innerHTML = '<p class="text-center text-muted">No recent activity</p>';
        return;
    }
    
    feed.innerHTML = executions.map(exec => {
        const icon = exec.status === 'success' ? '✅' : exec.status === 'error' ? '❌' : '⏳';
        const time = formatTimeAgo(exec.started_at);
        
        return `
            <div class="activity-item">
                <div class="activity-icon">${icon}</div>
                <div class="activity-content">
                    <div class="activity-title">
                        ${exec.channel_name || 'Unknown Channel'}
                    </div>
                    <div class="activity-description">
                        ${exec.stories_processed || 0} stories processed, 
                        ${exec.videos_created || 0} videos created
                    </div>
                    <div class="activity-time">${time}</div>
                </div>
            </div>
        `;
    }).join('');
}

// Load top performers
async function loadTopPerformers() {
    try {
        const response = await fetch(`${API_BASE_URL}/dashboard/summary`);
        const data = await response.json();
        
        if (data.success && data.top_channels) {
            displayTopPerformers(data.top_channels);
        }
    } catch (error) {
        console.error('Error loading top performers:', error);
    }
}

// Display top performing channels
function displayTopPerformers(channels) {
    const list = document.getElementById('performers-list');
    
    if (channels.length === 0) {
        list.innerHTML = '<p class="text-center text-muted">No data available</p>';
        return;
    }
    
    list.innerHTML = channels.map((channel, index) => {
        const rankClass = index === 0 ? 'first' : index === 1 ? 'second' : index === 2 ? 'third' : 'other';
        const rankEmoji = index === 0 ? '🥇' : index === 1 ? '🥈' : index === 2 ? '🥉' : (index + 1);
        
        return `
            <div class="performer-item">
                <div class="performer-rank ${rankClass}">${rankEmoji}</div>
                <div class="performer-info">
                    <div class="performer-name">${channel.name}</div>
                    <div class="performer-niche">${channel.niche}</div>
                </div>
                <div class="performer-stats">
                    <div class="performer-stat">
                        <div class="performer-stat-value">${formatNumber(channel.total_views)}</div>
                        <div class="performer-stat-label">Views</div>
                    </div>
                    <div class="performer-stat">
                        <div class="performer-stat-value">$${formatNumber(channel.total_revenue)}</div>
                        <div class="performer-stat-label">Revenue</div>
                    </div>
                </div>
            </div>
        `;
    }).join('');
}

// Filter channels
function filterChannels(filter) {
    const cards = document.querySelectorAll('.channel-card');
    const buttons = document.querySelectorAll('.filter-btn');
    
    // Update button states
    buttons.forEach(btn => {
        btn.classList.remove('active');
        if (btn.textContent.toLowerCase().includes(filter)) {
            btn.classList.add('active');
        }
    });
    
    // Filter cards
    cards.forEach(card => {
        if (filter === 'all') {
            card.style.display = 'block';
        } else if (filter === 'active' && card.dataset.status === 'active') {
            card.style.display = 'block';
        } else if (filter === 'inactive' && card.dataset.status === 'inactive') {
            card.style.display = 'block';
        } else {
            card.style.display = 'none';
        }
    });
}

// Refresh dashboard
function refreshDashboard() {
    console.log('🔄 Refreshing dashboard...');
    loadDashboard();
}

// Auto-refresh
function startAutoRefresh() {
    if (refreshTimer) {
        clearInterval(refreshTimer);
    }
    refreshTimer = setInterval(refreshDashboard, REFRESH_INTERVAL);
}

// Modal functions
function showCreateChannel() {
    document.getElementById('create-channel-modal').classList.add('active');
}

function closeModal() {
    document.getElementById('create-channel-modal').classList.remove('active');
}

// Channel actions
function viewChannel(slug) {
    window.location.href = `/channel.html?slug=${slug}`;
}

function manageChannel(slug) {
    alert(`Channel management for "${slug}" coming soon!`);
}

function showDocs() {
    window.open('https://github.com/ugm616/news-automation-n8n', '_blank');
}

function showSettings() {
    alert('Settings panel coming soon!');
}

// Utility functions
function formatNumber(num) {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + 'M';
    } else if (num >= 1000) {
        return (num / 1000).toFixed(1) + 'K';
    }
    return num.toString();
}

function formatTimeAgo(timestamp) {
    const now = new Date();
    const then = new Date(timestamp);
    const diffMs = now - then;
    const diffMins = Math.floor(diffMs / 60000);
    
    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} minutes ago`;
    
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours} hours ago`;
    
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays} days ago`;
}

function showError(message) {
    console.error(message);
    // Could implement a toast notification here
}

// Close modal on outside click
window.onclick = function(event) {
    const modal = document.getElementById('create-channel-modal');
    if (event.target === modal) {
        closeModal();
    }
}
