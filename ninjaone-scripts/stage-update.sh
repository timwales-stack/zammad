#!/bin/bash
# Black Raven Service Desk — Stage Update
# Pulls new Zammad image and starts staging environment for testing
# Run manually or via NinjaOne after update check alerts
#
# Usage: ./ninjaone-scripts/stage-update.sh

set -e

COMPOSE_DIR="/opt/zammad"
LOG_DIR="$COMPOSE_DIR/logs/patching"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d)-staging.log"

mkdir -p "$LOG_DIR"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "=== Staging Update Started ==="

# Step 1: Backup current database
log "Step 1: Running pre-update backup..."
cd "$COMPOSE_DIR"
if [ -f scripts/backup.sh ]; then
  ./scripts/backup.sh >> "$LOG_FILE" 2>&1
  log "Backup complete"
else
  log "WARNING: backup.sh not found, skipping backup"
fi

# Step 2: Pull latest images
log "Step 2: Pulling latest Docker images..."
docker compose pull >> "$LOG_FILE" 2>&1
log "Images pulled"

# Step 3: Start staging stack (if staging compose exists)
if [ -f docker-compose.staging.yml ]; then
  log "Step 3: Starting staging environment..."
  docker compose -f docker-compose.staging.yml up -d >> "$LOG_FILE" 2>&1

  # Step 4: Wait for health checks
  log "Step 4: Waiting for staging health checks (120s max)..."
  ATTEMPTS=0
  MAX_ATTEMPTS=12
  while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
    sleep 10
    ATTEMPTS=$((ATTEMPTS + 1))
    HEALTH=$(docker inspect br-staging-zammad-rails --format '{{.State.Health.Status}}' 2>/dev/null || echo "starting")
    log "  Health check attempt $ATTEMPTS/$MAX_ATTEMPTS: $HEALTH"
    if [ "$HEALTH" = "healthy" ]; then
      log "Staging is healthy!"
      break
    fi
  done

  if [ "$HEALTH" != "healthy" ]; then
    log "ERROR: Staging did not become healthy after $MAX_ATTEMPTS attempts"
    echo "STAGING FAILED: Health checks did not pass. Check logs at $LOG_FILE"
    exit 1
  fi

  log "Step 5: Staging environment is running and healthy"
  echo "STAGING SUCCESS: New Zammad version is running in staging"
  echo "Test at: http://localhost:3080 (staging port)"
  echo ""
  echo "If everything looks good, apply to production:"
  echo "  /opt/zammad/ninjaone-scripts/apply-update.sh"
else
  log "No staging compose file found — images pulled but not started"
  echo "Images pulled. No staging compose file. Apply directly with:"
  echo "  /opt/zammad/ninjaone-scripts/apply-update.sh"
fi

log "=== Staging Update Complete ==="
