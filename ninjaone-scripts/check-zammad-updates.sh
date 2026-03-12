#!/bin/bash
# Black Raven Service Desk — Check for Zammad Updates
# Deployed as a NinjaOne scheduled script (runs daily)
#
# This script checks if a newer Zammad Docker image is available
# and reports back to NinjaOne. Does NOT auto-apply.
#
# NinjaOne Setup:
#   1. Administration → Scripting → Add Script
#   2. Name: "Check Zammad Updates"
#   3. Type: Bash
#   4. Paste this script
#   5. Schedule: Daily at 06:00 UTC
#   6. Assign to: blackraven-servicedesk device

set -e

COMPOSE_DIR="/opt/zammad"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"
LOG_DIR="$COMPOSE_DIR/logs/patching"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).log"

mkdir -p "$LOG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "=== Zammad Update Check Started ==="

# Get current running image
CURRENT_IMAGE=$(docker inspect br-zammad-rails --format '{{.Config.Image}}' 2>/dev/null || echo "unknown")
CURRENT_DIGEST=$(docker inspect br-zammad-rails --format '{{.Image}}' 2>/dev/null | cut -c1-12 || echo "unknown")

log "Current image: $CURRENT_IMAGE"
log "Current digest: $CURRENT_DIGEST"

# Pull latest image metadata (does not download layers)
docker pull ghcr.io/zammad/zammad:latest --quiet > /dev/null 2>&1
LATEST_DIGEST=$(docker inspect ghcr.io/zammad/zammad:latest --format '{{.Id}}' 2>/dev/null | cut -c1-12 || echo "unknown")

log "Latest digest: $LATEST_DIGEST"

if [ "$CURRENT_DIGEST" = "$LATEST_DIGEST" ]; then
  log "STATUS: UP TO DATE — No update available"
  echo "Zammad is up to date ($CURRENT_IMAGE)"
  exit 0
else
  log "STATUS: UPDATE AVAILABLE"
  log "Current: $CURRENT_DIGEST"
  log "Latest:  $LATEST_DIGEST"
  echo "UPDATE AVAILABLE: New Zammad image detected"
  echo "Current: $CURRENT_DIGEST"
  echo "Latest:  $LATEST_DIGEST"
  echo ""
  echo "To stage the update, run: /opt/zammad/ninjaone-scripts/stage-update.sh"
  echo "To apply to production:   /opt/zammad/ninjaone-scripts/apply-update.sh"
  # Exit code 1 triggers NinjaOne alert
  exit 1
fi
