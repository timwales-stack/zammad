#!/bin/bash
# Black Raven Service Desk — Apply Update to Production
# Applies a staged update to production containers
# REQUIRES HUMAN APPROVAL — only run after staging validation
#
# Usage: ./ninjaone-scripts/apply-update.sh

set -e

COMPOSE_DIR="/opt/zammad"
LOG_DIR="$COMPOSE_DIR/logs/patching"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d)-production.log"

mkdir -p "$LOG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "=== Production Update Started ==="

cd "$COMPOSE_DIR"

# Step 1: Record current state for rollback
CURRENT_IMAGE=$(docker inspect br-zammad-rails --format '{{.Config.Image}}' 2>/dev/null)
CURRENT_DIGEST=$(docker inspect br-zammad-rails --format '{{.Image}}' 2>/dev/null | cut -c1-12)
log "Pre-update image: $CURRENT_IMAGE (digest: $CURRENT_DIGEST)"

# Step 2: Final backup before apply
log "Step 1: Running pre-apply backup..."
if [ -f scripts/backup.sh ]; then
  ./scripts/backup.sh >> "$LOG_FILE" 2>&1
  log "Backup complete"
fi

# Step 3: Stop staging if running
if [ -f docker-compose.staging.yml ]; then
  log "Step 2: Stopping staging environment..."
  docker compose -f docker-compose.staging.yml down >> "$LOG_FILE" 2>&1 || true
fi

# Step 4: Apply update to production
log "Step 3: Applying update to production..."
docker compose up -d >> "$LOG_FILE" 2>&1

# Step 5: Wait for health checks
log "Step 4: Waiting for production health checks (180s max)..."
ATTEMPTS=0
MAX_ATTEMPTS=18
while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
  sleep 10
  ATTEMPTS=$((ATTEMPTS + 1))
  HEALTH=$(docker inspect br-zammad-rails --format '{{.State.Health.Status}}' 2>/dev/null || echo "starting")
  log "  Health check attempt $ATTEMPTS/$MAX_ATTEMPTS: $HEALTH"
  if [ "$HEALTH" = "healthy" ]; then
    break
  fi
done

NEW_DIGEST=$(docker inspect br-zammad-rails --format '{{.Image}}' 2>/dev/null | cut -c1-12)

if [ "$HEALTH" = "healthy" ]; then
  log "=== Production Update SUCCESSFUL ==="
  log "Previous digest: $CURRENT_DIGEST"
  log "New digest: $NEW_DIGEST"
  echo "UPDATE SUCCESSFUL"
  echo "Previous: $CURRENT_DIGEST"
  echo "Current:  $NEW_DIGEST"
  exit 0
else
  log "ERROR: Production health checks failed!"
  log "ROLLBACK REQUIRED"
  echo "UPDATE FAILED: Health checks did not pass after update"
  echo ""
  echo "To rollback:"
  echo "  1. Edit docker-compose.yml — set image tag to previous version"
  echo "  2. Run: docker compose up -d"
  echo "  3. Verify: curl https://support.blackravenit.com/api/v1/monitoring/health_check"
  echo ""
  echo "Previous digest was: $CURRENT_DIGEST"
  echo "Check logs: $LOG_FILE"
  exit 1
fi
