# Black Raven Service Desk — TOMORROW_SUMMARY

## Project Status: Phase 1 — Foundation (In Progress)

### Current Sprint: POC Setup

#### Phase 1 — Foundation
- [x] Clone Zammad fork from github.com/timwales-stack/zammad
- [x] Create CLAUDE.md with agency-agents team protocol
- [x] Create TOMORROW_SUMMARY.md (this file)
- [ ] Create docker-compose.yml (production stack)
- [ ] Create docker-compose.staging.yml (testing stack)
- [ ] Create .env.example with all required variables
- [ ] Create nginx/nginx.conf (reverse proxy + SSL termination)
- [ ] Create docs/MICROSOFT-OAUTH-SETUP.md
- [ ] Create docs/DEPLOYMENT.md
- [x] Create seed script for test users, orgs, groups, and sample tickets
- [x] Create docs/DEPLOYMENT-CHECKLIST.md (human-in-the-loop steps)

#### Phase 2 — Security Hardening
- [ ] Elasticsearch password + network isolation
- [ ] PostgreSQL hardening (password, no external access)
- [ ] Redis password + internal-only binding
- [ ] Nginx TLS 1.2+ configuration
- [ ] ClamAV container for attachment scanning
- [ ] Container network isolation (internal bridge)
- [ ] Firewall rules (only 80/443 exposed)
- [ ] Disk encryption documentation
- [ ] Rate limiting on login endpoints
- [ ] Create docs/SECURITY-HARDENING.md

#### Phase 3 — Black Raven Branding
- [ ] Custom CSS theme (blackraven-theme.css)
- [ ] Product name + organization config instructions
- [ ] Logo upload instructions
- [ ] Email template branding
- [ ] Confirm branding name with client ("Black Raven Service Desk"?)

#### Phase 4 — NinjaOne Integration Architecture
- [ ] ninja-bridge service scaffold (Node.js)
- [ ] NinjaOne webhook receiver design
- [ ] Zammad API client wrapper
- [ ] Field mapping configuration
- [ ] Status sync (Zammad → NinjaOne) design
- [ ] Create docs/NINJAONE-INTEGRATION.md
- [ ] Leave ready for implementation (needs client API credentials)

#### Phase 5 — Patching via NinjaOne RMM
- [ ] Install NinjaOne agent on droplet
- [ ] Configure OS patch policy (Ubuntu security auto-approve)
- [ ] Create NinjaOne scripted task for Docker image update checks
- [ ] Configure advisory monitoring (Zammad RSS → NinjaOne custom monitor)
- [ ] Set up alert → webhook → Zammad ticket for patch notifications
- [ ] Document rollback procedure (Docker image tag pinning)
- [ ] Create docs/PATCHING-VIA-NINJAONE.md

#### Phase 6 — Maintenance Documentation
- [ ] Create docs/MAINTENANCE-RUNBOOK.md
- [ ] Backup/restore scripts + documentation
- [ ] Health check scripts
- [ ] MS OAuth app registration maintenance
- [ ] NinjaOne integration maintenance
- [ ] Patching agent operation guide

---

## Key Decisions Made
- **Platform:** Zammad (AGPL-3.0 fork) — self-hosted, white-labeled
- **Deployment:** Docker Compose on DigitalOcean (8GB RAM / 4 vCPU)
- **Auth:** Microsoft OAuth via Entra ID (primary) + 2FA
- **Integration:** NinjaOne via custom webhook bridge (Node.js)
- **Branding:** "Black Raven Service Desk" (pending client confirmation)
- **Patching:** NinjaOne RMM managed (OS patches + Docker image updates)

## Key Decisions Pending
- [ ] Domain choice: `support.blackravenit.com` vs `tickets.blackravenit.com`
- [ ] Exact brand name confirmation from client
- [ ] NinjaOne API credentials from client
- [ ] MS Entra ID app registration (client's tenant)
- [ ] Backup storage location (DigitalOcean Spaces bucket)

## Team Notes
- **Security agent** leads all hardening — Phase 2 is security-first
- **No source code modifications** unless absolutely necessary (AGPL compliance)
- All customization via admin UI, custom CSS, API integrations
- This is a **proof of concept** — production hardening comes after POC validation
