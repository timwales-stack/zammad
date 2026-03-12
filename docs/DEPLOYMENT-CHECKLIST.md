# Deployment Checklist — Black Raven Service Desk

## Who This Is For

This document is for the **human operator** (Tim or assigned team member) who needs to complete steps that cannot be automated. The AI agents handle code, configuration, and deployment — but these steps require human access, approval, or client coordination.

---

## Pre-Deployment: Things Only You Can Do

### 1. Get Info From Black Raven IT

You need the following from the client before deployment can proceed:

| Item | Who Provides | Status |
|------|-------------|--------|
| Microsoft Entra ID tenant ID | Black Raven IT admin | [ ] Received |
| Permission to register an app in their Azure AD | Black Raven IT admin | [ ] Granted |
| Desired domain (`support.blackravenit.com` or `tickets.blackravenit.com`) | Client decision | [ ] Confirmed |
| NinjaOne API credentials (client ID + secret) | Black Raven IT admin | [ ] Received |
| NinjaOne instance URL (usually `app.ninjarmm.com`) | Black Raven IT admin | [ ] Confirmed |
| Logo file (PNG/SVG, min 200x200px) | Black Raven IT | [ ] Received |
| Brand colors (confirm: black/red/dark gray?) | Black Raven IT | [ ] Confirmed |
| Product name preference ("Black Raven Service Desk"?) | Client decision | [ ] Confirmed |
| Support email (`support@blackravenit.com`?) | Client decision | [ ] Confirmed |
| List of initial agent users (names + emails) | Black Raven IT | [ ] Received |
| Which NinjaOne alert types should create tickets | Black Raven IT | [ ] Defined |
| Ticket priority mapping (which alerts = critical?) | Black Raven IT | [ ] Defined |

### 2. Provision DigitalOcean Droplet

**You do this** — agents cannot create infrastructure.

1. Log into DigitalOcean
2. Create droplet:
   - **Image:** Ubuntu 24.04 LTS
   - **Size:** 8 GB RAM / 4 vCPU ($48/mo)
   - **Region:** NYC1 (or closest to Chicago for Black Raven)
   - **VPC:** Default
   - **SSH Key:** Add your deployment key
   - **Hostname:** `blackraven-servicedesk`
   - **Enable:** Monitoring, encrypted volumes
3. Note the droplet IP: `_______________`
4. Create Cloud Firewall:
   - Inbound: TCP 80, TCP 443 from anywhere; TCP 22 from your IP only
   - Outbound: All
   - Attach to the droplet

**Optional:** Create a DigitalOcean Spaces bucket for backups:
- Name: `blackraven-backups`
- Region: NYC3
- Save the Spaces access key and secret

### 3. Set Up DNS

**You do this** — requires Cloudflare or client's DNS provider access.

1. Add an A record:
   - **Name:** `support` (or `tickets`)
   - **Value:** `[droplet IP from step 2]`
   - **Proxy:** DNS only (gray cloud) — Nginx handles SSL
   - **TTL:** Auto
2. Verify DNS propagation:
   ```
   dig support.blackravenit.com +short
   ```
   Should return the droplet IP.

### 4. Register Microsoft OAuth App

**You do this** with the client — requires access to their Azure AD tenant.

Follow `docs/MICROSOFT-OAUTH-SETUP.md` steps 1-3. You will need:
- Azure Portal admin access (or sit with their admin)
- The final domain (from step 3) for the redirect URI

**Save these values** (you'll put them in `.env`):
- Application (client) ID → `MICROSOFT_APP_ID`
- Client secret value → `MICROSOFT_APP_SECRET`
- Directory (tenant) ID → `MICROSOFT_TENANT_ID`

### 5. Obtain SSL Certificate

**You do this** on the droplet after DNS is pointed.

```bash
# SSH to droplet
ssh root@[droplet-ip]

# Install certbot
apt update && apt install -y certbot

# Get certificate (standalone mode, before Docker starts)
certbot certonly --standalone -d support.blackravenit.com

# Certificates saved to:
# /etc/letsencrypt/live/support.blackravenit.com/fullchain.pem
# /etc/letsencrypt/live/support.blackravenit.com/privkey.pem
```

### 6. Fill In the .env File

**You do this** — only you have the credentials.

```bash
# On the droplet, in the project directory
cp .env.example .env
nano .env
```

Fill in every `CHANGE_ME` value. Reference:

| Variable | Where You Got It |
|----------|-----------------|
| `POSTGRES_PASS` | Generate: `openssl rand -base64 32` |
| `ELASTICSEARCH_PASS` | Generate: `openssl rand -base64 32` |
| `REDIS_URL` password portion | Generate: `openssl rand -base64 32` |
| `ZAMMAD_ADMIN_PASSWORD` | Choose a strong initial password (change after first login) |
| `MICROSOFT_APP_ID` | Step 4 above |
| `MICROSOFT_APP_SECRET` | Step 4 above |
| `MICROSOFT_TENANT_ID` | Step 4 above |
| `NINJAONE_CLIENT_ID` | From Black Raven IT (step 1) |
| `NINJAONE_CLIENT_SECRET` | From Black Raven IT (step 1) |
| `NINJAONE_WEBHOOK_SECRET` | Generate: `openssl rand -hex 32` |
| `ZAMMAD_API_TOKEN` | Generated after first login (see step 8) |
| `SSL_CERT_PATH` | `/etc/letsencrypt/live/support.blackravenit.com/fullchain.pem` |
| `SSL_KEY_PATH` | `/etc/letsencrypt/live/support.blackravenit.com/privkey.pem` |
| `BACKUP_S3_KEY` | From DigitalOcean Spaces (step 2) |
| `BACKUP_S3_SECRET` | From DigitalOcean Spaces (step 2) |

**Set permissions:**
```bash
chmod 600 .env
```

---

## Deployment: Launch Sequence

After all pre-deployment steps are complete, the agents can handle deployment. But you need to **approve each stage**:

### 7. Start Services

```bash
docker compose up -d
```

**Wait 3-5 minutes** for initial setup (database creation, migrations, ES index). Monitor:
```bash
docker compose logs -f zammad-railsserver
```

Look for: `Listening on http://0.0.0.0:3000` — that means it's ready.

### 8. First Login & Initial Setup

**You do this** — initial admin configuration cannot be automated.

1. Open `https://support.blackravenit.com` (or droplet IP for POC) in browser
2. Complete the setup wizard:
   - Admin email: `admin@blackravenit.com`
   - Admin password: (from `.env`)
   - Organization: `Black Raven IT`
   - System name: `Black Raven Service Desk`
3. After login, go to **Admin** → **Settings** → **Branding**:
   - Product Name: `Black Raven Service Desk`
   - Organization: `Black Raven IT`
   - Upload logo
4. Generate API token (needed for seed script and ninja-bridge):
   - Go to your profile (top-right avatar) → **Token Access**
   - Create token with permissions: `ticket.agent`, `ticket.customer`, `admin.user`, `admin.organization`, `admin.group`
   - Copy token → update `.env`: `ZAMMAD_API_TOKEN=the_token`

### 8b. Seed Test Data (POC Exploration — Before Azure/NinjaOne)

**Do this to explore the system before connecting external services.**

```bash
# Make seed script executable
chmod +x scripts/seed-test-data.sh

# Run it (uses ZAMMAD_API_TOKEN from .env)
./scripts/seed-test-data.sh
```

This creates:
- **3 test agents** (admin, tech lead, helpdesk)
- **1 test customer** (client at TestCorp)
- **3 organizations** (Black Raven IT, TestCorp Industries, Acme Healthcare)
- **5 ticket groups** (Helpdesk, Network, Security, Cloud, Onboarding)
- **5 sample tickets** (realistic MSP scenarios: WiFi issue, security alert, onboarding, Azure sync, printer)

**Test credentials:**

| User | Login | Password | Role |
|------|-------|----------|------|
| Admin | admin@blackravenit.com | (set during wizard) | Admin |
| Tech Lead | tech@blackravenit.com | TestTech2026! | Agent |
| Helpdesk | helpdesk@blackravenit.com | TestHelp2026! | Agent |
| Client | client@testcorp.com | TestClient2026! | Customer |

**Explore these areas:**
1. Log in as Admin — try branding settings, custom CSS, groups, SLA policies
2. Log in as Tech Lead — assign/triage tickets, add internal notes
3. Log in as Helpdesk — pick up a ticket, respond, close it
4. Log in as Client — view tickets from customer portal, submit a new one
5. Test search (Elasticsearch) — search for "WiFi" or "Azure"
6. Check reporting dashboard

**When ready for production:** deactivate test users, connect Microsoft OAuth (step 8c), connect NinjaOne (step 9).

### 8c. Connect Microsoft OAuth (When Ready)

1. Go to **Admin** → **Settings** → **Security** → **Third-Party Applications**:
   - Enable Microsoft Office 365
   - Enter App ID, App Secret, Tenant ID (from step 4)
   - Save and test: click "Sign in with Microsoft" on the login page
2. Restart ninja-bridge with the API token:
   ```bash
   docker compose restart ninja-bridge
   ```
3. Deactivate test agent accounts (keep admin)
4. Have real Black Raven agents sign in with Microsoft — promote to Agent role

### 9. Configure NinjaOne Webhooks

**You do this** (or guide Black Raven IT admin) — requires NinjaOne admin access.

1. Log into NinjaOne admin panel
2. Go to **Administration** → **Apps** → **API**
3. Register a new application (if not done in step 1):
   - Type: Client Credentials
   - Scopes: Monitoring, Management
4. Go to **Administration** → **Notification Channels**
5. Create a new webhook channel:
   - **Name:** `Service Desk Integration`
   - **URL:** `https://support.blackravenit.com/api/ninja-webhook`
   - **Secret:** (same as `NINJAONE_WEBHOOK_SECRET` in `.env`)
   - **Events:** Select which alert types should create tickets
6. Create alert policies that use this notification channel
7. Test: trigger a test alert in NinjaOne and verify a ticket appears in Zammad

### 10. Configure Conditional Access (MFA)

**You do this** with the client's Azure AD admin.

1. Azure Portal → Microsoft Entra ID → Security → Conditional Access
2. Create policy:
   - Name: `MFA for Service Desk`
   - Users: All users (or IT staff group)
   - Cloud apps: Select `Black Raven Service Desk`
   - Grant: Require multifactor authentication
3. Enable the policy
4. Test: sign out and back in — MFA should prompt

---

## Post-Deployment: Verify Everything Works

### 11. Validation Checklist

**You verify these manually:**

| Test | How | Expected Result | Status |
|------|-----|-----------------|--------|
| HTTPS loads | Visit `https://support.blackravenit.com` | Login page, valid SSL | [ ] Pass |
| HTTP redirects | Visit `http://support.blackravenit.com` | Redirects to HTTPS | [ ] Pass |
| Microsoft login | Click "Sign in with Microsoft" | Redirects to MS login, returns authenticated | [ ] Pass |
| MFA prompts | Sign in with Conditional Access active | MFA challenge appears | [ ] Pass |
| Create ticket | As agent, create a test ticket | Ticket created, searchable | [ ] Pass |
| NinjaOne webhook | Trigger test alert in NinjaOne | Ticket auto-created in Zammad | [ ] Pass |
| Ticket → NinjaOne sync | Close the auto-created ticket | NinjaOne alert resolves | [ ] Pass |
| Branding | Check login page, header, emails | Black Raven logo and name everywhere | [ ] Pass |
| Attachment upload | Upload a test file to a ticket | File attaches successfully | [ ] Pass |
| Security headers | Run `securityheaders.com` scan | A+ or A rating | [ ] Pass |
| Backup | Run `./scripts/backup.sh` | Backup file created in Spaces | [ ] Pass |
| Health check | Visit `/api/v1/monitoring/health_check` | Returns healthy status | [ ] Pass |

### 12. Hand Off to Client

Once validation passes:

1. **Create agent accounts:** Have each Black Raven IT technician sign in with Microsoft (auto-creates account), then promote to Agent role
2. **Configure groups:** Create ticket groups matching their service categories (e.g., Network, Security, Helpdesk, Cloud)
3. **Set up SLAs:** Configure response time targets per priority level
4. **Email integration:** Add support email (`support@blackravenit.com`) as a Zammad email channel for incoming tickets via email
5. **Train the team:** Walk through creating/updating/closing tickets, using the dashboard, and the NinjaOne auto-ticket flow

---

## Ongoing: What You Need to Approve

NinjaOne RMM handles OS patching and monitors for Zammad updates, but **you approve production changes:**

| NinjaOne Alert | Your Action |
|---------------|-------------|
| "Ubuntu security patches available" | Auto-approved via policy (review if failures) |
| "New Zammad Docker image available" | Review changelog → approve staging pull → approve production |
| "Zammad critical security advisory" | Immediate: review → test in staging → approve production apply |
| "Microsoft app secret expiring in 30 days" | Rotate secret in Azure Portal + update `.env` |
| "SSL certificate expiring in 14 days" | Run `certbot renew` (should auto-renew if cron is set) |
| "Backup failed" | Investigate → check Spaces credentials and disk space |
| "NinjaOne integration error" | Check bridge logs → verify credentials haven't expired |
| "Docker Engine update available" | Schedule maintenance window → approve in NinjaOne |

---

## Quick Reference: Where Things Live

| Thing | Location |
|-------|----------|
| Project repo | `C:/Users/timwa/zammad/` (local) or GitHub |
| Secrets | `.env` on the droplet (never in git) |
| SSL certs | `/etc/letsencrypt/live/support.blackravenit.com/` |
| Docker data | `/var/lib/docker/volumes/` (encrypted volume) |
| Backups | DigitalOcean Spaces: `blackraven-backups` bucket |
| Logs | `docker compose logs [service]` |
| Zammad admin | `https://support.blackravenit.com` → Admin panel |
| Azure app registration | Azure Portal → App registrations |
| NinjaOne webhooks | NinjaOne admin → Notification Channels |
| NinjaOne patching scripts | `./ninjaone-scripts/` |
| All documentation | `./docs/` directory |
