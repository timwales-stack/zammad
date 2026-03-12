# Maintenance Runbook — Black Raven Service Desk

## Overview

Day-to-day operations guide for the Black Raven Service Desk. Covers updates, backups, troubleshooting, and integration maintenance.

---

## 1. Daily Operations

### Health Check
```bash
# Quick health status of all containers
docker compose ps

# Detailed health check
./scripts/health-check.sh

# Check Zammad application health
curl -s https://support.blackravenit.com/api/v1/monitoring/health_check | jq .
```

### Log Review
```bash
# Zammad application logs (last 100 lines)
docker compose logs --tail=100 zammad-railsserver

# Nginx access logs
docker compose logs --tail=100 nginx

# All services
docker compose logs --tail=50

# Follow logs in real-time
docker compose logs -f zammad-railsserver
```

---

## 2. Backups

### Automated Backups
The backup script runs daily via cron and stores encrypted backups in DigitalOcean Spaces.

```bash
# Manual backup
./scripts/backup.sh

# Verify latest backup
./scripts/backup.sh --verify

# List backups in Spaces
s3cmd ls s3://blackraven-backups/
```

### What Gets Backed Up
| Component | Method | Frequency |
|-----------|--------|-----------|
| PostgreSQL database | `pg_dump` | Daily |
| Zammad attachments | Volume snapshot | Daily |
| Elasticsearch index | Snapshot API | Weekly |
| Configuration (.env, nginx) | File copy | Daily |
| ClamAV definitions | Not backed up (re-downloaded) | — |

### Restore Procedure
```bash
# Stop services
docker compose down

# Restore from backup
./scripts/restore.sh --date 2026-03-10

# Restart services
docker compose up -d

# Verify
curl -s https://support.blackravenit.com/api/v1/monitoring/health_check
```

### Backup Retention
- Daily backups: 30 days
- Weekly backups: 12 weeks
- Monthly backups: 12 months

---

## 3. Updating Zammad

### Standard Update Process
```bash
# 1. Backup first (always!)
./scripts/backup.sh

# 2. Pull latest images to staging
docker compose -f docker-compose.staging.yml pull

# 3. Start staging
docker compose -f docker-compose.staging.yml up -d

# 4. Wait for health checks to pass (may take 2-3 min for migrations)
docker compose -f docker-compose.staging.yml ps

# 5. Test staging manually
#    - Login works
#    - Tickets visible
#    - Search works
#    - Microsoft OAuth works

# 6. If staging passes, update production
docker compose pull
docker compose up -d

# 7. Verify production
curl -s https://support.blackravenit.com/api/v1/monitoring/health_check
```

### Version Pinning (Recommended for Production)
Instead of `latest`, pin to specific versions in `docker-compose.yml`:
```yaml
image: ghcr.io/zammad/zammad:6.4.1
```
Update the tag explicitly after staging validation.

### Rollback
```bash
# If update fails, rollback to previous image
docker compose down
# Edit docker-compose.yml to previous version tag
docker compose up -d
```

---

## 4. Managing Users & Agents

### Add New Agent
1. Have user sign in with Microsoft OAuth (auto-creates account)
2. In Zammad admin → **Users** → find user → change Role to **Agent**
3. Assign to appropriate Groups (e.g., Support, Network, Security)

### Remove Agent
1. Zammad admin → **Users** → find user → set **Active** to `false`
2. This preserves ticket history but prevents login

### LDAP Sync Issues
```bash
# Check LDAP sync status
docker exec br-zammad-rails rails runner "puts Ldap.all.map { |l| [l.name, l.last_sync_at] }"

# Force LDAP sync
docker exec br-zammad-rails rails runner "Ldap.all.each(&:perform)"
```

---

## 5. Microsoft OAuth Maintenance

### Rotate App Secret (Every 24 Months)
1. Azure Portal → App registrations → Black Raven Service Desk
2. Certificates & secrets → New client secret
3. Copy new secret value
4. Update `.env` file: `MICROSOFT_APP_SECRET=new_value`
5. Restart Zammad:
   ```bash
   docker compose restart zammad-railsserver zammad-websocket zammad-scheduler
   ```
6. Test login immediately
7. Delete old secret from Azure Portal after confirming new one works

### Conditional Access Policy Changes
- Changes in Azure AD Conditional Access take effect immediately
- No Zammad restart needed
- Test after any policy changes

---

## 6. NinjaOne Integration Maintenance

### Verify Integration Health
```bash
# Check ninja-bridge status
curl -s https://support.blackravenit.com/api/ninja-health | jq .

# Check bridge logs
docker compose logs --tail=50 ninja-bridge
```

### Rotate NinjaOne Credentials
1. Generate new client secret in NinjaOne admin
2. Update `.env`:
   ```
   NINJAONE_CLIENT_SECRET=new_value
   ```
3. Restart bridge:
   ```bash
   docker compose restart ninja-bridge
   ```

### Common Issues

**Webhooks not arriving:**
- Check NinjaOne → Administration → Notification Channels
- Verify webhook URL: `https://support.blackravenit.com/api/ninja-webhook`
- Check nginx logs for 4xx/5xx responses
- Verify `NINJAONE_WEBHOOK_SECRET` matches in both NinjaOne and `.env`

**Tickets not creating:**
- Check `ZAMMAD_API_TOKEN` is valid and has ticket create permissions
- Check bridge logs: `docker compose logs ninja-bridge`
- Verify Zammad API is accessible from bridge: `docker exec br-ninja-bridge wget -q -O- http://zammad-railsserver:3000/api/v1/tickets`

**Status sync not working:**
- Verify Zammad webhook is configured (Settings → Webhooks)
- Check NinjaOne API credentials haven't expired
- Review bridge logs for sync errors

---

## 7. ClamAV Maintenance

### Verify Scanning
```bash
# Check ClamAV status
docker exec br-clamav clamdcheck

# Check virus definition date
docker exec br-clamav clamscan --version

# Force definition update
docker exec br-clamav freshclam
```

### ClamAV Not Starting
- Initial startup takes 2-5 minutes (downloading definitions)
- Check logs: `docker compose logs clamav`
- Ensure container has internet access for freshclam updates

---

## 8. Elasticsearch Maintenance

### Check Cluster Health
```bash
docker exec br-zammad-rails curl -s http://elasticsearch:9200/_cluster/health | jq .
```

### Rebuild Index (If Search Broken)
```bash
docker exec br-zammad-rails rails runner "SearchIndexBackend.reindex"
```
This can take several minutes depending on ticket volume.

### Disk Space
Elasticsearch data grows with ticket volume. Monitor:
```bash
docker exec br-elasticsearch df -h /bitnami/elasticsearch/data
```

---

## 9. Troubleshooting

### Service Won't Start
```bash
# Check which service is failing
docker compose ps

# Check logs for the failing service
docker compose logs [service-name]

# Common fix: restart the service
docker compose restart [service-name]

# Nuclear option: recreate all containers
docker compose down && docker compose up -d
```

### Database Connection Issues
```bash
# Test PostgreSQL connectivity
docker exec br-postgresql pg_isready -U zammad

# Check PostgreSQL logs
docker compose logs postgresql
```

### Out of Memory
```bash
# Check memory usage per container
docker stats --no-stream

# If Elasticsearch is consuming too much:
# Reduce heap in docker-compose.yml: ELASTICSEARCH_HEAP_SIZE=512m
```

### SSL Certificate Renewal
```bash
# If using Let's Encrypt with certbot:
certbot renew --deploy-hook "docker compose restart nginx"

# Manual certificate replacement:
# 1. Place new certs in nginx/ssl/
# 2. docker compose restart nginx
```

---

## 10. Emergency Procedures

### Complete System Restore
```bash
# 1. Provision new droplet (if needed)
# 2. Install Docker
# 3. Clone repo
git clone https://github.com/timwales-stack/zammad.git
cd zammad

# 4. Restore .env from secure backup
# 5. Restore data
./scripts/restore.sh --date [latest]

# 6. Start services
docker compose up -d

# 7. Update DNS to new IP (if needed)
# 8. Verify
```

### Data Breach Response
1. **Contain:** Immediately isolate the service (`docker compose down`)
2. **Assess:** Review logs for scope of access
3. **Notify:** Alert Black Raven IT leadership
4. **Remediate:** Rotate all credentials (DB, Redis, ES, API tokens, OAuth secrets)
5. **Document:** Full incident report
6. **Prevent:** Update security controls based on findings

---

## 11. Patching via NinjaOne RMM

All patching is managed through Black Raven's existing NinjaOne RMM platform.

### OS Patches
- NinjaOne agent on the droplet handles Ubuntu security updates
- Policy: security patches auto-approved, feature updates require manual approval
- View patch status in NinjaOne dashboard

### Zammad / Docker Updates
NinjaOne runs a scheduled script (`ninjaone-scripts/check-zammad-updates.sh`) that:
1. Checks for new Zammad Docker image tags
2. Alerts if a new version is available
3. On approval: pulls to staging, runs health checks, then applies to production

### Advisory Monitoring
- NinjaOne custom monitor watches `zammad.com/en/advisories` RSS
- New advisory → NinjaOne alert → webhook → Zammad ticket
- Team triages priority and schedules patch window

### Rollback
```bash
# If an update causes issues:
# 1. Edit docker-compose.yml — revert image tag to previous version
# 2. Apply
docker compose up -d
# 3. Verify
curl -s https://support.blackravenit.com/api/v1/monitoring/health_check
```

---

## 12. Monitoring Integration (Morpheus Platform)

The Black Raven Service Desk can be monitored via the Morpheus hosting platform:
- Health endpoint: `https://support.blackravenit.com/api/v1/monitoring/health_check`
- Uptime monitoring: Standard HTTP check on port 443
- Alert on: 5xx responses, health check failures, certificate expiry
- Integration: Add as a monitored service in Morpheus platform dashboard
