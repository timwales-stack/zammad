# Black Raven Service Desk — CLAUDE.md

## Project Overview
> White-labeled Zammad ticketing system for Black Raven IT, integrated with NinjaOne RMM.

Black Raven IT is a managed IT services provider serving businesses nationwide (primary: Chicago + South Florida). This project deploys a branded, self-hosted ticketing system that integrates with their existing NinjaOne RMM platform. The system handles internal service desk operations, client ticket management, and automated alert-to-ticket workflows.

**Client:** Black Raven IT (blackravenit.com)
**Product Name:** Black Raven Service Desk
**Base Platform:** Zammad (AGPL-3.0 fork)
**Repo:** github.com/timwales-stack/zammad (branch: `blackraven`)

---

## Team Protocol

Follow Core + Flex agent team framework from: `C:/Users/timwa/agency-agents/`

### Core Team (6 — Always Active)
- **Senior PM** `[PM]` — Only agent who talks to Tim. All messages prefixed `[PM]`.
- **Program Manager** `[PgM]` — Cross-project coordination, links to Morpheus hosting platform
- **Lead Architect** `[Architect]` — COMPARE→PLAN→APPROVED before any execution
- **Lead Designer** `[Design]` — Brand application, UI customization review
- **QA Lead** `[QA]` — Gates all phase completions. Can block any release.
- **Training Lead** `[Training]` — Continuous improvement, captures lessons learned

### Flex Agents (Spun Up Per Task)
- **DevOps** — Docker Compose, DigitalOcean deployment, Nginx, SSL
- **Security** — MS OAuth/SAML config, hardening, Elasticsearch security, ClamAV
- **Backend** — NinjaOne webhook bridge, API integration middleware
- **Research** — NinjaOne API docs, Zammad config deep dives
- **Docs** — Maintenance runbook, patching guide, NinjaOne setup instructions
- **Debug** — Troubleshooting deployment, integration, and auth issues

### Non-Negotiable Rules
1. Core team always active — no solo work
2. PM is the ONLY speaker to Tim — `[PM]` prefix required
3. Architect approves all plans before execution
4. QA signs off before any commit or deployment
5. Security agent leads all hardening work
6. All commits: `Co-Authored-By: Morpheus <morpheus@morpheusweb.ai>`
7. Agents police each other per `agency-agents/protocols/policing.md`

### Agent Definitions
- Core agents: `C:/Users/timwa/agency-agents/core/`
- Flex agents: `C:/Users/timwa/agency-agents/flex/`
- Protocols: `C:/Users/timwa/agency-agents/protocols/`
- Guardrails: `C:/Users/timwa/agency-agents/guardrails/`

### Session Flow
1. PM reads this CLAUDE.md + TOMORROW_SUMMARY
2. Training loads relevant lessons from `agency-agents/learning/`
3. Architect runs gap analysis (COMPARE→PLAN→APPROVED)
4. PM presents plan to Tim (with flex agent assignments)
5. Agents execute (parallel where independent)
6. QA validates + Security reviews hardening
7. Docs prepares commit + PM authorizes
8. Training captures lessons

---

## Architecture

### Deployment Stack (Docker Compose)
```
┌─────────────────────────────────────────────┐
│              DigitalOcean Droplet            │
│              8 GB RAM / 4 vCPU              │
│                                             │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Nginx  │  │  Zammad  │  │ PostgreSQL│  │
│  │ (SSL)   │→ │  (App)   │→ │  (Data)   │  │
│  └─────────┘  └──────────┘  └───────────┘  │
│                    │                        │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │  Redis  │  │Elasticse.│  │  ClamAV   │  │
│  │ (Cache) │  │ (Search) │  │  (Scan)   │  │
│  └─────────┘  └──────────┘  └───────────┘  │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  NinjaOne Bridge (Node.js)          │    │
│  │  Webhook receiver + status sync     │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Container Services
| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| zammad-railsserver | zammad/zammad | 3000 | Main application |
| zammad-websocket | zammad/zammad | 6042 | WebSocket server |
| zammad-scheduler | zammad/zammad | — | Background jobs |
| postgresql | postgres:16 | 5432 | Database |
| redis | redis:7-alpine | 6379 | Cache + sessions |
| elasticsearch | elasticsearch:8.x | 9200 | Full-text search |
| nginx | nginx:alpine | 80/443 | Reverse proxy + SSL |
| clamav | clamav/clamav | 3310 | Attachment scanning |
| ninja-bridge | node:20-alpine | 3001 | NinjaOne integration |

### Domain
- Production: `support.blackravenit.com` (or `tickets.blackravenit.com` — TBD with client)
- POC/Testing: Droplet IP or temp domain

---

## Security Requirements

### Authentication — Microsoft Entra ID
- **Primary auth:** Microsoft OAuth (Entra ID) — "Sign in with Microsoft" button
- **Backup:** SAML 2.0 with Entra ID (if OAuth insufficient)
- **LDAP sync:** Active Directory for user provisioning + role mapping
- **MFA:** Enforced via Microsoft Conditional Access policies
- **2FA:** Zammad-native TOTP + FIDO2 as secondary layer
- **Password login:** Set random complex passwords on all local accounts (cannot be disabled natively)
- See `docs/MICROSOFT-OAUTH-SETUP.md` for full configuration guide

### Hardening Checklist
- [ ] Elasticsearch password set (non-default)
- [ ] Elasticsearch network isolated (internal only)
- [ ] PostgreSQL password rotated, no external access
- [ ] Redis password set, no external access
- [ ] Nginx TLS 1.2+ with strong cipher suites
- [ ] ClamAV scanning all attachments
- [ ] CSP headers configured
- [ ] Rate limiting on login endpoints
- [ ] API tokens scoped (least privilege)
- [ ] Disk encryption enabled (LUKS or DO encrypted volumes)
- [ ] Firewall: only 80/443 exposed externally
- [ ] Container network isolation (internal bridge)
- [ ] Regular backup schedule (automated)
- [ ] Zammad security advisory monitoring (via NinjaOne RMM)

### AGPL-3.0 Compliance
- Source code modifications must be available on request to users of the hosted instance
- Keep customizations minimal — use configuration over code changes
- Branding changes (CSS, logo, product name) are configuration, not code modifications
- Document any source code modifications in `docs/AGPL-MODIFICATIONS.md`

---

## NinjaOne Integration

### Architecture
```
NinjaOne Alert
    │
    ▼
Webhook POST → ninja-bridge (Node.js :3001)
    │
    ├── Map alert fields → Zammad ticket fields
    ├── Create ticket via Zammad REST API
    └── Store mapping (NinjaOne alert ID ↔ Zammad ticket ID)

Zammad Ticket Status Change
    │
    ▼
Webhook POST → ninja-bridge
    │
    ├── Lookup linked NinjaOne alert
    └── Update/resolve alert via NinjaOne API v2
```

### Field Mapping
| NinjaOne Alert Field | Zammad Ticket Field |
|---------------------|---------------------|
| alert.message | ticket.title |
| alert.device.name | ticket.article.body (device context) |
| alert.severity | ticket.priority (mapped: critical→3, warning→2, info→1) |
| alert.type | ticket.group (mapped to service category) |
| alert.organization | ticket.customer (matched by org name) |
| alert.id | ticket.custom_field (ninja_alert_id) |

### NinjaOne API Requirements
- OAuth 2.0 client credentials grant
- Scopes: Monitoring (read), Management (create/modify)
- Base URL: `https://app.ninjarmm.com/v2/`
- Webhook configuration in NinjaOne admin → Notification Channels

### Status — Ready for Implementation
Integration architecture is defined. Implementation requires:
1. NinjaOne API credentials from Black Raven IT
2. Webhook endpoint URL (after domain is set)
3. Organization/device mapping between NinjaOne and Zammad

---

## POC Test Environment

### Test Users (Pre-Azure, Pre-NinjaOne)
The POC runs with local auth so the team can explore Zammad before connecting external services.

**Created on first boot via setup wizard:**

| User | Email | Role | Purpose |
|------|-------|------|---------|
| Admin | admin@blackravenit.com | Admin | Full system config, branding, settings |
| Tech Lead | tech@blackravenit.com | Agent | Ticket management, queues, SLAs |
| Helpdesk | helpdesk@blackravenit.com | Agent | Standard ticket workflow |
| Test Client | client@testcorp.com | Customer | Client-side ticket submission |

**Test Organizations:**
| Organization | Domain | Type |
|-------------|--------|------|
| Black Raven IT | blackravenit.com | Internal |
| TestCorp Industries | testcorp.com | Sample client |
| Acme Healthcare | acmehealthcare.com | Sample client (healthcare vertical) |

**Test Ticket Groups:**
| Group | Description |
|-------|-------------|
| Helpdesk | General IT support tickets |
| Network | Network infrastructure issues |
| Security | Security incidents and requests |
| Cloud | Cloud/Azure/M365 issues |
| Onboarding | New employee setup |

### POC Exploration Checklist
Use these test scenarios to validate the system before going live:

1. **Admin** — Log in, set branding (name, logo, colors), create groups
2. **Tech Lead** — Create a ticket, assign to Helpdesk agent, set priority/SLA
3. **Helpdesk** — Pick up ticket, add internal note, respond to customer, close
4. **Test Client** — Submit ticket via customer portal, view status, reply
5. **Search** — Verify Elasticsearch: search tickets by keyword
6. **Email** — Test inbound/outbound email channel (optional for POC)
7. **Reporting** — Check built-in reporting dashboard
8. **Custom fields** — Add `ninja_alert_id` field (prep for NinjaOne)

### When Ready to Go Live
1. Configure Microsoft OAuth (replace local auth)
2. Connect NinjaOne webhooks
3. Deactivate test users or convert to real accounts
4. Import real organizations and agent list from client

---

## Patching via NinjaOne RMM

### Overview
Black Raven IT uses NinjaOne as their RMM platform. All patching for the Service Desk server is managed through NinjaOne's built-in patch management — no standalone patching agent needed.

### How It Works
```
NinjaOne RMM Agent (on droplet)
    │
    ├── OS patches (Ubuntu)         → NinjaOne patch policies
    ├── Docker image updates         → NinjaOne scripted task
    ├── Zammad security advisories   → NinjaOne custom monitor
    └── Alert on patch failure       → NinjaOne → webhook → Zammad ticket
```

### NinjaOne Patch Configuration
1. **Install NinjaOne agent** on the DigitalOcean droplet
2. **OS Patching:** NinjaOne patch policy for Ubuntu (security updates auto-approved, feature updates manual)
3. **Docker Updates:** NinjaOne scheduled script that:
   - Checks for new Zammad Docker image tags
   - Pulls to staging compose stack
   - Runs health checks
   - Alerts if new version available (human approves production apply)
4. **Advisory Monitoring:** NinjaOne custom monitor watching `zammad.com/en/advisories` RSS
   - Creates NinjaOne alert on new advisory
   - Alert → webhook → Zammad ticket (via ninja-bridge)
   - Team triages and schedules patch window

### Approval Flow
| Event | NinjaOne Action | Human Action |
|-------|----------------|--------------|
| Ubuntu security patch | Auto-approve via policy | None (auto) |
| Ubuntu feature update | Alert + hold | Approve in NinjaOne |
| New Zammad image available | Alert + pull to staging | Review staging → approve production |
| Critical Zammad CVE | Alert (high priority) | Immediate staging test → approve |
| Elasticsearch/PostgreSQL CVE | Alert + image update plan | Approve in NinjaOne |
| Docker Engine update | Alert | Schedule maintenance window |

### Rollback
- Docker image tags pinned in `docker-compose.yml`
- Rollback = revert tag + `docker compose up -d`
- Database backup taken before every update (NinjaOne pre-script)

---

## Branding — Black Raven IT

### Admin Configuration (No Code Changes)
| Setting | Value |
|---------|-------|
| Product Name | Black Raven Service Desk |
| Organization | Black Raven IT |
| Logo | Black Raven IT logo (uploaded via admin UI) |
| Locale | English (United States) |
| Timezone | America/Chicago |

### Custom CSS
- Primary: Black (#1a1a1a) + Raven gradient (#0a0a0a → #2d2d2d)
- Accent: Red (#c62828) or brand red from existing site
- Secondary: Dark gray (#333333)
- Text: White (#ffffff) on dark, Black (#1a1a1a) on light
- Font: Inter (matching website)
- File: `custom/css/blackraven-theme.css`

### Email Templates
- From name: "Black Raven Service Desk"
- From email: `support@blackravenit.com`
- Signature: Black Raven IT branding + contact info
- Footer: Company address, phone, hours

---

## Project-Specific Rules

### No Secrets in Code
- **NEVER** display, print, or echo API keys/tokens/secrets
- **NEVER** hardcode credentials in Docker Compose or configs
- All secrets in `.env` file (not committed)
- `.env.example` has placeholder structure only

### Key Source
- Project secrets: `C:/Users/timwa/zammad/.env` (local, not committed)
- Master keys: `C:/Users/timwa/morpheus/.env` (DigitalOcean, etc.)

### Commit Convention
- `Co-Authored-By: Morpheus <morpheus@morpheusweb.ai>`
- Conventional commits: `feat:`, `fix:`, `docs:`, `chore:`, `security:`
- PM authorizes every commit via commit pipeline

### What We Don't Touch
- Zammad core source code (unless absolutely necessary — AGPL implications)
- Use configuration, admin UI, custom CSS, and API integrations instead
- Any source modifications documented in `docs/AGPL-MODIFICATIONS.md`

---

## File Structure (Our Additions)
```
zammad/
├── CLAUDE.md                          # This file
├── TOMORROW_SUMMARY.md                # Sprint tracker
├── docker-compose.yml                 # Production stack
├── docker-compose.staging.yml         # Staging/testing stack
├── .env.example                       # Environment template
├── nginx/
│   ├── nginx.conf                     # Reverse proxy config
│   └── ssl/                           # SSL certificates
├── custom/
│   └── css/
│       └── blackraven-theme.css       # Brand CSS overrides
├── ninja-bridge/
│   ├── package.json                   # Node.js middleware
│   ├── src/
│   │   ├── index.ts                   # Entry point
│   │   ├── ninja-webhook.ts           # NinjaOne alert receiver
│   │   ├── zammad-client.ts           # Zammad API client
│   │   ├── ninja-client.ts            # NinjaOne API client
│   │   └── field-mapper.ts            # Alert → ticket field mapping
│   └── Dockerfile                     # Bridge container
├── ninjaone-scripts/
│   ├── check-zammad-updates.sh        # NinjaOne scheduled script: check for new images
│   ├── stage-update.sh                # Pull new image to staging, run health checks
│   └── apply-update.sh               # Apply staged update to production
├── scripts/
│   ├── backup.sh                      # Database + attachment backup
│   ├── restore.sh                     # Restore from backup
│   └── health-check.sh               # Container health verification
├── docs/
│   ├── MICROSOFT-OAUTH-SETUP.md       # Entra ID configuration guide
│   ├── NINJAONE-INTEGRATION.md        # Integration architecture + setup
│   ├── MAINTENANCE-RUNBOOK.md         # Day-to-day operations guide
│   ├── PATCHING-VIA-NINJAONE.md       # RMM-managed patching procedures
│   ├── SECURITY-HARDENING.md          # Full hardening checklist
│   ├── AGPL-MODIFICATIONS.md          # Source code change log
│   └── DEPLOYMENT.md                  # Initial deployment steps
└── logs/
    └── patching/                      # Patch activity logs
```

---

## Quick Commands
```bash
# Start all services (production)
docker compose up -d

# Start staging environment
docker compose -f docker-compose.staging.yml up -d

# View logs
docker compose logs -f zammad-railsserver

# Backup database
./scripts/backup.sh

# Check container health
./scripts/health-check.sh

# Pull latest Zammad image (staging first!)
docker compose -f docker-compose.staging.yml pull
docker compose -f docker-compose.staging.yml up -d
# Verify staging works, then:
docker compose pull && docker compose up -d
```

---

## Deployment Target
- **Provider:** DigitalOcean
- **Droplet:** 8 GB RAM / 4 vCPU ($48/mo)
- **OS:** Ubuntu 24.04 LTS
- **Docker:** Docker Engine + Docker Compose v2
- **Backup:** Automated daily to DigitalOcean Spaces
- **Monitoring:** Integrated with Morpheus hosting platform
