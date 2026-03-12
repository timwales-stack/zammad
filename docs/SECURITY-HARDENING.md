# Security Hardening Guide — Black Raven Service Desk

## Overview

This document covers all security hardening measures for the Black Raven Service Desk deployment. The Security agent leads implementation; QA validates all items.

**Threat Model:** MSP ticketing system handling sensitive client infrastructure data (passwords, network diagrams, IP addresses). Must protect against unauthorized access, data exfiltration, and supply chain attacks.

---

## 1. Network Security

### Container Network Isolation
The `docker-compose.yml` defines two networks:
- **`frontend`** — Only Nginx is exposed (ports 80/443)
- **`backend`** — Internal only. PostgreSQL, Redis, Elasticsearch, ClamAV, Zammad, and ninja-bridge communicate here

**No backend service has external port mappings.** All database, cache, and search traffic stays internal.

### Firewall (DigitalOcean Cloud Firewall)
```
Inbound Rules:
  - TCP 443 (HTTPS)    → 0.0.0.0/0
  - TCP 80  (HTTP)     → 0.0.0.0/0 (redirects to 443)
  - TCP 22  (SSH)      → [Tim's IP only]

Outbound Rules:
  - All TCP/UDP        → 0.0.0.0/0 (for updates, NinjaOne API, ClamAV updates)
```

### SSH Hardening
- Key-based auth only (disable password auth)
- Root login disabled (use sudo user)
- Fail2ban installed for brute force protection
- SSH port optionally changed from 22

---

## 2. Authentication Security

### Microsoft OAuth (Primary)
See `docs/MICROSOFT-OAUTH-SETUP.md` for full configuration.
- Single-tenant app registration (Black Raven's Azure AD only)
- MFA enforced via Conditional Access
- Admin consent granted for API permissions

### Two-Factor Authentication
- Zammad 2FA enabled (TOTP + FIDO2)
- All agents required to configure 2FA
- Recovery codes generated per user (10 codes)

### Password Policy (for local accounts)
- Minimum 16 characters
- Requires uppercase, lowercase, number, special character
- All SSO accounts get random 64-character passwords (prevents bypass)

### Session Security
- Session timeout: Configure via Zammad admin
- Force re-authentication after password change
- Device logging enabled — monitor for unknown devices

---

## 3. Data Protection

### Encryption at Rest
Zammad does NOT encrypt the database natively. Implement at infrastructure level:

**Option A: DigitalOcean Encrypted Volumes**
- Create encrypted block storage volume for `/var/lib/docker/volumes/`
- DigitalOcean manages encryption keys (AES-256)
- Transparent to applications

**Option B: LUKS (Linux Unified Key Setup)**
```bash
# During initial setup (before Docker data exists)
cryptsetup luksFormat /dev/sda2
cryptsetup open /dev/sda2 encrypted-data
mkfs.ext4 /dev/mapper/encrypted-data
mount /dev/mapper/encrypted-data /var/lib/docker/volumes/
```

**Recommendation:** Option A (simpler, managed, no key management burden)

### Encryption in Transit
- Nginx terminates TLS 1.2+ with strong ciphers
- HSTS header: `max-age=31536000; includeSubDomains; preload`
- PostgreSQL connections within Docker network (internal, unencrypted but isolated)
- LDAP connections: STARTTLS or SSL required

### Backup Encryption
- Database dumps encrypted before upload to DigitalOcean Spaces
- Use `gpg --symmetric --cipher-algo AES256` for backup files
- Backup encryption key stored separately from backups

---

## 4. Elasticsearch Security

**CRITICAL:** Elasticsearch contains all searchable ticket data. Default configuration is a major risk.

### Required Hardening
1. **Set password:** `ELASTICSEARCH_PASS` must be strong and unique
2. **Network isolation:** ES is on `backend` network only — no external port mapping
3. **Disable dynamic scripting:** Prevents code injection
4. **Memory limits:** `ELASTICSEARCH_HEAP_SIZE=1g` prevents OOM
5. **Index access:** Only Zammad application should access ES — no direct queries

### Verification
```bash
# Should fail from outside Docker network
curl http://localhost:9200  # Should refuse connection

# Should only work from within backend network
docker exec br-zammad-rails curl http://elasticsearch:9200/_cluster/health
```

---

## 5. Attachment Security

### ClamAV Integration
- ClamAV container runs alongside Zammad
- Scans all uploaded attachments via clamd socket
- Virus definition updates run automatically (freshclam)
- Quarantine infected files — do not deliver to tickets

### File Type Restrictions
Configure via Nginx or application-level rules:
- Block: `.exe`, `.bat`, `.cmd`, `.ps1`, `.vbs`, `.js`, `.msi`, `.scr`
- Allow: `.pdf`, `.doc`, `.docx`, `.xls`, `.xlsx`, `.png`, `.jpg`, `.csv`, `.txt`, `.zip`

### Attachment Serving
- Attachments served as downloads (Content-Disposition: attachment)
- Never render inline to prevent XSS via uploaded HTML/SVG
- CSP frame-ancestors: 'self' prevents embedding

---

## 6. API Security

### Token Management
- Use scoped API tokens (minimum required permissions)
- ninja-bridge has its own dedicated token with only ticket create/update permissions
- Rotate API tokens every 12 months
- Disable API token auth globally if not needed for external integrations

### Rate Limiting
Configure in Nginx:
```nginx
# In http block
limit_req_zone $binary_remote_addr zone=login:10m rate=5r/m;
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;

# In location blocks
location /api/v1/signin { limit_req zone=login burst=3 nodelay; }
location /api/ { limit_req zone=api burst=20 nodelay; }
```

### Webhook Security (NinjaOne)
- Verify webhook signatures using `NINJAONE_WEBHOOK_SECRET`
- Reject requests without valid signature
- Log all webhook payloads (redact sensitive fields)
- Rate limit webhook endpoint

---

## 7. Monitoring & Logging

### Log Collection
- Zammad application logs: `/opt/zammad/log/production.log`
- Nginx access/error logs: `/var/log/nginx/`
- Container logs: `docker compose logs`
- Ship to centralized logging (future: integrate with Morpheus monitoring)

### Security Monitoring
- Monitor failed login attempts (threshold: 5 failures → alert)
- Monitor API token usage patterns
- Monitor Elasticsearch query patterns
- Alert on admin-level configuration changes
- Device log review: flag unknown devices

### Health Checks
All containers have health checks defined in `docker-compose.yml`:
- PostgreSQL: `pg_isready`
- Redis: `redis-cli ping`
- Elasticsearch: `/_cluster/health`
- Zammad: `/api/v1/monitoring/health_check`
- Nginx: `/health`
- ClamAV: `clamdcheck`
- ninja-bridge: `/health`

---

## 8. CVE Monitoring & Patching

### Advisory Sources
- Zammad: `https://zammad.com/en/advisories`
- PostgreSQL: `https://www.postgresql.org/support/security/`
- Elasticsearch: `https://www.elastic.co/community/security`
- Redis: `https://github.com/redis/redis/security/advisories`
- Nginx: `https://nginx.org/en/security_advisories.html`
- Docker: `https://docs.docker.com/security/`

### Patching Process (via NinjaOne RMM)
See `docs/PATCHING-VIA-NINJAONE.md` for the full RMM-managed patching workflow.

1. NinjaOne agent installed on droplet monitors OS and services
2. OS patches: auto-approved via NinjaOne patch policy (Ubuntu security updates)
3. Docker/Zammad updates: NinjaOne scripted task checks for new images, alerts team
4. Critical CVEs: NinjaOne high-priority alert → webhook → Zammad ticket for triage
5. All application patches tested in staging before production
6. Rollback plan for every patch (Docker image tag pinning)

---

## 9. AGPL Compliance Security Notes

- Custom security patches are subject to AGPL source disclosure
- **Mitigation:** Keep security fixes as configuration changes, not source modifications
- If source changes required, document in `docs/AGPL-MODIFICATIONS.md`
- Practical risk is low for internal MSP tool (limited user base)

---

## 10. Hardening Checklist

### Pre-Deployment
- [ ] Strong unique passwords set for PostgreSQL, Redis, Elasticsearch
- [ ] SSL certificates obtained and installed
- [ ] DigitalOcean Cloud Firewall configured
- [ ] SSH key-based auth only
- [ ] Fail2ban installed and configured
- [ ] Disk encryption enabled
- [ ] `.env` file permissions set to 600

### Post-Deployment
- [ ] Microsoft OAuth configured and tested
- [ ] MFA enforced via Conditional Access
- [ ] 2FA enabled in Zammad for all agents
- [ ] ClamAV running and updating definitions
- [ ] Rate limiting configured in Nginx
- [ ] All health checks passing
- [ ] Backup schedule configured and tested
- [ ] Security headers verified (use securityheaders.com)
- [ ] HSTS preload submitted
- [ ] Admin default password changed

### Ongoing
- [ ] Weekly: Review failed login attempts
- [ ] Monthly: Check for security advisories (automated by patching agent)
- [ ] Quarterly: Rotate API tokens, review user permissions
- [ ] Annually: Rotate Microsoft app secret, review firewall rules
- [ ] Per incident: Post-mortem + lesson capture
