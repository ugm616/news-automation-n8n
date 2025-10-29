#!/bin/bash

#==============================================================================
# Upload Video to Rumble
# Automates Rumble video upload using Puppeteer
#==============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_SCRIPT="${SCRIPT_DIR}/rumble_uploader.js"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed"
    exit 1
fi

# Check if puppeteer is installed
if [ ! -d "${SCRIPT_DIR}/node_modules/puppeteer" ]; then
    log_info "Installing Puppeteer..."
    cd "$SCRIPT_DIR"
    npm install puppeteer
fi

# Parse input
if [ -z "$1" ]; then
    log_error "Usage: $0 <upload_json>"
    exit 1
fi

# Call Node.js script
log_info "Uploading to Rumble..."
node "$NODE_SCRIPT" "$1"
