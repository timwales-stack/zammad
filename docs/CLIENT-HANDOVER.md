# Black Raven Service Desk — Client Handover Guide

> **Prepared by:** Morpheus AI
> **Date:** March 2026
> **System:** Black Raven Service Desk (white-labeled Zammad)
> **URL:** https://support.blackravenit.com
> **Staging URL (use now):** https://staging.blackraven.morpheusweb.dev

---

## 1. System Overview

The Black Raven Service Desk is a fully branded, self-hosted ticketing system built on Zammad. It integrates with your existing NinjaOne RMM platform and Microsoft 365 environment.

> **Access Model:** Morpheus AI manages the server infrastructure (DigitalOcean droplet, Docker, SSL, backups). Black Raven IT manages the application configuration (users, groups, OAuth, email, NinjaOne policies) via the Zammad admin UI and their own dashboards. Black Raven does not have direct server/SSH access.

| Component | Detail |
|-----------|--------|
| Platform | Zammad (AGPL-3.0) |
| Hosting | DigitalOcean (dedicated droplet, 4 vCPU / 8 GB RAM) |
| Domain | support.blackravenit.com |
| Auth | Microsoft Entra ID (OAuth) + local fallback |
| Integration | NinjaOne RMM (auto-ticket creation, client onboarding) |
| Network Security | Tailscale (zero-trust mesh — pre-configured by Morpheus AI) |
| Managed by | Morpheus AI |

---

## 2. Initial Admin Access

Use these credentials for first login. **Change the admin password immediately.**

| Field | Value |
|-------|-------|
| **URL** | https://support.blackravenit.com *(after DNS setup)* |
| **Staging URL** | **https://staging.blackraven.morpheusweb.dev** *(use this now)* |
| **Username** | admin@blackravenit.com |
| **Password** | `BlackRaven2024!` |
| **Role** | Administrator |

### Additional Test Accounts

| User | Email | Password | Role |
|------|-------|----------|------|
| Tech Lead | tech@blackravenit.com | `TechLead2024!` | Agent |
| Helpdesk | helpdesk@blackravenit.com | `Helpdesk2024!` | Agent |
| Test Client | client@testcorp.com | `TestClient2024!` | Customer |

### Test Organizations

| Organization | Domain | Type |
|-------------|--------|------|
| Black Raven IT | blackravenit.com | Internal |
| TestCorp Industries | testcorp.com | Sample client |
| Acme Healthcare | acmehealthcare.com | Sample client |

> **Important:** Once Microsoft OAuth is configured (Section 5), users will sign in via "Sign in with Microsoft" and these local passwords become emergency fallbacks only.

---

## 3. Tailscale Setup (Secure Access)

Before testing, each team member who needs access must install Tailscale. This creates a secure, private network connection to the Service Desk server — no ports are exposed to the public internet.

### What is Tailscale?

Tailscale is a zero-trust mesh VPN. It takes 2 minutes to set up and runs quietly in the background. Once connected, you can access the Service Desk as if you were on the same local network as the server.

### Step-by-Step (Per User)

1. **Request access** — Provide your Morpheus AI representative with the names and email addresses of team members who need access
2. **Morpheus AI approves and sends invite** — Each approved user receives a Tailscale invite link via secure channel
3. **Download Tailscale** — [tailscale.com/download](https://tailscale.com/download) (Windows, Mac, iOS, Android available)
4. **Install and sign in** — Use your Microsoft account (same one you use for M365)
5. **Click the invite link** — This joins you to the Service Desk network
6. **Wait for approval** — A Morpheus AI admin must approve your device before access is granted
7. **Verify connection** — Tailscale icon in your system tray shows "Connected"

> **All Tailscale connections require Morpheus AI admin approval.** This is a security measure — no device can access the server network without explicit authorization. Approval is typically completed within 1 business day.
>
> **Access is restricted to the Service Desk server only.** Black Raven devices on Tailscale can only reach the `blackraven-servicedesk` machine. You will not have access to any other Morpheus infrastructure. This is enforced via Tailscale ACLs (access control lists) managed by Morpheus AI.

### Who Needs Tailscale?

| Role | Needs Tailscale? | When |
|------|-----------------|------|
| Admins exploring the system (Section 4) | **Yes** | Before DNS is configured |
| Agents using the live system | No | After DNS + SSL are configured, access via `support.blackravenit.com` |
| MSP Clients submitting tickets | No | After DNS + SSL, access via `support.blackravenit.com` |

> **Note:** Tailscale is only required during the testing/setup phase and for ongoing admin access to internal tools. Once DNS and SSL are live, regular users access the system via `https://support.blackravenit.com` without Tailscale.

---

## 4. Testing Before Full Setup

You can explore the full system **before** configuring DNS, Microsoft OAuth, or NinjaOne. This lets your team look around, test ticket workflows, and verify everything works.

### How to Access

1. Ensure Tailscale is connected (Section 3)
2. Open your browser and go to: **https://staging.blackraven.morpheusweb.dev**
3. Log in with the admin credentials from Section 2:
   - **Email:** admin@blackravenit.com
   - **Password:** `BlackRaven2024!`

### What You Can Test

| Area | What to Try |
|------|------------|
| **Admin Dashboard** | Explore settings, branding, groups, roles |
| **Create Tickets** | Submit test tickets, assign to agents, set priorities |
| **Agent Workflow** | Log in as tech@blackravenit.com — pick up and resolve tickets |
| **Customer Portal** | Log in as client@testcorp.com — submit a ticket as a customer |
| **Search** | Search tickets by keyword to verify Elasticsearch is working |
| **Reporting** | Check the built-in reporting dashboard |
| **Custom Fields** | Review the `ninja_alert_id` field (prep for NinjaOne) |

### What Won't Work Yet

| Feature | Requires |
|---------|----------|
| `https://support.blackravenit.com` URL | DNS setup (Section 5) — currently accessible at `https://staging.blackraven.morpheusweb.dev` |
| "Sign in with Microsoft" button | Microsoft OAuth (Section 6) |
| Auto-ticket creation from alerts | NinjaOne integration (Section 7) |
| Auto-onboarding of MSP clients | NinjaOne integration (Section 7) |
| Email-based ticket submission | Email channel setup (Section 8) |
| SSL on `support.blackravenit.com` | DNS pointing to droplet (SSL auto-provisions once DNS is set) |

> **Note:** All features above will activate once you complete the corresponding setup sections. No reinstallation needed — just configuration.

### Cleaning Up After Testing

Once you're done exploring and ready to go live, clean up the test data:

| Action | How | Why |
|--------|-----|-----|
| **Change admin password** | Admin → Profile → Password | The default password `BlackRaven2024!` is in this document |
| **Delete test agent accounts** | Admin → Users → delete `tech@blackravenit.com` and `helpdesk@blackravenit.com` | Known passwords are a security risk, even as fallback |
| **Delete test customer account** | Admin → Users → delete `client@testcorp.com` | Not a real customer |
| **Delete test organizations** | Admin → Organizations → delete "TestCorp Industries" and "Acme Healthcare" | Keeps real client data clean |
| **Delete test tickets** | Admin → Tickets → delete any tickets created during testing | Prevents confusion with real tickets |
| **Keep "Black Raven IT" org** | Do not delete — this is your real internal organization | Used for agent accounts |

> **Note:** Zammad does **not** force password resets on these accounts. If you skip this cleanup, anyone with this document could log in using the test credentials. At minimum, change the admin password and delete the test agent accounts before going live.

### When You're Ready

Once you've explored and cleaned up test data, proceed with Sections 4–7 in order. Each section enables additional functionality on the same running system.

---

## 4. DNS Setup (Required — GoDaddy)

> *Skip this section until you're done testing (Section 3).*

Your domain `blackravenit.com` is managed through GoDaddy. You need to add one DNS record:

### Step-by-Step

1. Log into [GoDaddy DNS Management](https://dcc.godaddy.com/) for **blackravenit.com**
2. Click **DNS** → **DNS Records**
3. Click **Add New Record**
4. Configure:

| Field | Value |
|-------|-------|
| Type | **A** |
| Name | **support** |
| Value | **`104.131.85.152`** |
| TTL | 600 (10 minutes) |

5. Click **Save**
6. Wait 5–30 minutes for DNS propagation
7. Verify: `nslookup support.blackravenit.com` should return the droplet IP

> **Warning:** Do NOT modify your existing MX, TXT (SPF/DKIM/DMARC), or root A records. Only add the new `support` subdomain.

---

## 5. Microsoft Entra ID (OAuth) Setup

This allows your team and clients to sign in with their Microsoft accounts. Your Azure admin performs these steps.

### Step 1: Register the Application

1. Go to [Azure Portal → App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationsListBlade)
2. Click **New registration**
3. Configure:

| Field | Value |
|-------|-------|
| Name | **Black Raven Service Desk** |
| Supported account types | **Accounts in this organizational directory only** (single tenant) |
| Redirect URI (Web) | `https://support.blackravenit.com/auth/microsoft_office365/callback` |

4. Click **Register**
5. On the overview page, copy:
   - **Application (client) ID** → save this
   - **Directory (tenant) ID** → save this

### Step 2: Create a Client Secret

1. Go to **Certificates & secrets** → **Client secrets** → **New client secret**
2. Description: "Black Raven Service Desk"
3. Expires: **24 months**
4. Click **Add**
5. **Copy the Value immediately** — it's only shown once

### Step 3: Configure API Permissions

1. Go to **API permissions** → **Add a permission** → **Microsoft Graph** → **Delegated permissions**
2. Add these permissions:
   - `openid`
   - `profile`
   - `email`
   - `User.Read`
3. Click **Grant admin consent for [Your Org]**

### Step 4: Configure in Zammad

1. Log into the Service Desk as admin
2. Go to **Admin** → **Settings** → **Security** → **Third Party Applications**
3. Find **Microsoft Office 365** and click it
4. Enter:

| Field | Value |
|-------|-------|
| App ID | *[paste Application (client) ID]* |
| App Secret | *[paste client secret value]* |
| App Tenant ID | *[paste Directory (tenant) ID]* |

5. Toggle **Enable** → On
6. Click **Save**

### MFA Enforcement (Optional but Recommended)

MFA is enforced via Azure Conditional Access, not in Zammad:

1. Go to [Azure Portal → Conditional Access](https://portal.azure.com/#blade/Microsoft_AAD_IAM/ConditionalAccessBlade)
2. Create a new policy:
   - Name: "MFA for Service Desk"
   - Target: Cloud app → "Black Raven Service Desk"
   - Grant: Require multifactor authentication
3. Enable the policy

### Secret Rotation

The client secret expires after 24 months. Set a calendar reminder to:
1. Create a new secret in Azure Portal
2. Update the secret in Zammad Admin → Security → Third Party → Microsoft Office 365
3. Delete the old secret

---

## 6. NinjaOne Integration Setup (Webhooks)

The Service Desk includes a webhook bridge that automatically creates tickets from NinjaOne alerts and onboards new MSP clients.

> **Note:** This section sets up the **webhook integration** (alerts → tickets, auto-onboarding). Server **patching and monitoring** via NinjaOne RMM is a separate step — see Section 9.

### Step 1: Create NinjaOne API Application

1. Log into NinjaOne → **Administration** → **Apps** → **API**
2. Click **Add** → **Client App IDs**
3. Configure:

| Field | Value |
|-------|-------|
| Application Name | Black Raven Service Desk |
| Grant Type | **Client Credentials** |
| Scopes | Monitoring (read), Management (create/modify) |

4. Click **Save**
5. Copy:
   - **Client ID**
   - **Client Secret**

### Step 2: Configure Webhook

1. Go to NinjaOne → **Administration** → **Notification Channels**
2. Click **Add** → **Webhook**
3. Configure:

| Field | Value |
|-------|-------|
| Name | Black Raven Service Desk |
| URL | `https://support.blackravenit.com/api/ninja-webhook` |
| Events | Alert Triggered, Alert Resolved, Organization Created |

4. Save

### Step 3: Provide Credentials to Morpheus Team

Send the following to your Morpheus contact (via secure channel, NOT email):
- NinjaOne Client ID
- NinjaOne Client Secret
- NinjaOne Instance URL (e.g., `app.ninjarmm.com` or `eu.ninjarmm.com`)

We will configure these on the server. Once set, the integration is automatic.

### How Auto-Onboarding Works

When you add a new MSP client in NinjaOne:

```
New Client in NinjaOne
  → Webhook fires to Service Desk
  → Organization automatically created in Zammad
  → Primary contact gets a customer account
  → Welcome email sent with login instructions
  → Client can submit tickets at support.blackravenit.com
```

### How Alert-to-Ticket Works

```
NinjaOne Alert (e.g., disk space warning)
  → Webhook fires to Service Desk
  → Ticket auto-created with alert details
  → Assigned to appropriate group (Helpdesk, Network, Security, Cloud)
  → Priority mapped: critical→High, warning→Normal, info→Low
  → When ticket is closed in Zammad, alert is resolved in NinjaOne
```

---

## 7. Email Channel Setup

Configure email so customers can submit/reply to tickets via email.

### Recommended Setup

1. Create a dedicated Microsoft 365 mailbox: **support@blackravenit.com**
2. In the Service Desk, go to **Admin** → **Channels** → **Email**
3. Click **Add Email Account**
4. Configure:

| Setting | Value |
|---------|-------|
| Email address | support@blackravenit.com |
| Channel | Microsoft 365 |
| Organization | Black Raven IT |
| Group | Helpdesk |

5. Follow the Microsoft OAuth flow to authenticate the mailbox

### Email Branding

- **Admin** → **Settings** → **Branding** → Product Name: "Black Raven Service Desk"
- **Admin** → **Channels** → **Email** → Signatures: Add Black Raven branding, contact info, hours
- **Admin** → **Settings** → **Ticket** → Email Notifications: Customize templates if desired

---

## 8. How Client Access Works

### For Your Internal Staff (Agents)

1. Visit https://support.blackravenit.com
2. Click **"Sign in with Microsoft"** (once OAuth is configured)
3. Authenticate via Microsoft → Dashboard loads
4. Assign roles in **Admin** → **Users** (Agent, Admin)

### For MSP Clients (Customers)

There are three ways customers get access:

| Method | How It Works |
|--------|-------------|
| **NinjaOne Auto-Onboard** | When added in NinjaOne, customer gets welcome email with login link |
| **Admin Creates Manually** | Admin → Users → Add Customer → Zammad sends password setup email |
| **Self-Registration** | Customer clicks "Register as a new customer" on login page |

### Where Invitation Emails Are Configured

| Setting | Location |
|---------|----------|
| Welcome email template | Admin → Settings → Ticket → Email Notifications |
| Sender address & name | Admin → Channels → Email |
| Product name in emails | Admin → Settings → Branding |
| Email signature | Admin → Channels → Email → Signatures |

### Customer Portal Features

Customers can:
- Submit new tickets (via web portal or email)
- View their ticket history and status
- Reply to tickets and add attachments
- Receive email notifications on ticket updates

---

## 9. Server Patching & Monitoring via NinjaOne RMM

> **This is separate from the webhook integration (Section 6).** Section 6 connects NinjaOne alerts and client onboarding to the ticket system. This section is about managing the Service Desk **server itself** — OS patches, Docker updates, and health monitoring — through NinjaOne RMM.

### Important: Server Access

The Service Desk runs on Morpheus AI-managed infrastructure. **Black Raven IT does not have direct SSH or server access.** All server-side actions are performed by Morpheus AI. The table below clarifies who does what:

| Action | Who Does It | How |
|--------|-------------|-----|
| Install NinjaOne agent on droplet | **Morpheus AI** | Black Raven provides the agent installer/token |
| Install Tailscale on droplet | **Morpheus AI** | Connects droplet to secure mesh network |
| Add server to NinjaOne org | **Black Raven IT** | Via NinjaOne dashboard (once agent checks in) |
| Configure monitoring policies | **Black Raven IT** | Via NinjaOne dashboard |
| Configure patch policies | **Black Raven IT** | Via NinjaOne dashboard |
| Apply Docker/Zammad updates | **Morpheus AI** | Coordinated with Black Raven approval |
| Rollback if update fails | **Morpheus AI** | Image tags pinned, backup taken before every update |

### Tailscale Requirement (Zero-Trust Network)

The droplet is behind a **Tailscale mesh network**. This means:

- **No open SSH port** — SSH is only accessible over the Tailscale network
- **NinjaOne agent** connects outbound to NinjaOne cloud (allowed)
- **Script execution via NinjaOne** is restricted to **monitoring-only** by default
- Any NinjaOne scripted tasks that modify the server (patches, updates, restarts) must be **coordinated with Morpheus AI** before execution

> **Why Tailscale?** The NinjaOne RMM agent has full script execution capability on any server it's installed on. Since this droplet is Morpheus-managed infrastructure, Tailscale ensures that all management access goes through a zero-trust boundary. This protects both parties — Black Raven gets monitoring visibility, Morpheus retains infrastructure control.
>
> **No action required from Black Raven.** Tailscale is pre-installed and configured by Morpheus AI during droplet provisioning. It does not affect your access to the Zammad admin UI, customer portal, or NinjaOne dashboard — only direct server management (SSH, Docker) is restricted to the Tailscale mesh.

### Setup Steps

**Black Raven provides:**
1. NinjaOne agent installer package or enrollment token
2. Desired monitoring thresholds (or use the recommended defaults below)

**Morpheus AI performs:**
1. Install Tailscale on the droplet and join to Morpheus mesh network
2. Install the NinjaOne agent using Black Raven's enrollment token
3. Verify agent checks in to Black Raven's NinjaOne dashboard

**Black Raven configures (in NinjaOne dashboard):**
1. Add the server to your "Black Raven IT" organization
2. Apply monitoring policies:

| Monitor | Recommended Threshold | Alert |
|---------|----------------------|-------|
| CPU Usage | > 80% for 5 min | Warning |
| RAM Usage | > 85% for 5 min | Warning |
| Disk Space | < 20% free | Critical |
| Docker Services | Any container unhealthy | Critical |
| SSL Certificate | < 30 days to expiry | Warning |

3. Set patch policies to **notify only** (not auto-apply) — Morpheus AI coordinates all server-side changes

### Update Procedure

| Update Type | Black Raven Action | Morpheus AI Action |
|-------------|-------------------|-------------------|
| Ubuntu security patches | Review alert in NinjaOne | Apply patch in maintenance window |
| Ubuntu feature updates | Approve in NinjaOne | Stage → test → apply |
| Zammad new version | Notified via NinjaOne alert | Pull image → test staging → apply production |
| Critical Zammad CVE | Notified (high priority) | Immediate staging test → apply same day |

### Rollback

Docker image tags are pinned in the deployment configuration. Morpheus AI handles all rollbacks:
1. Revert the image tag in docker-compose.yml
2. Run `docker compose up -d`
3. Database backup is taken automatically before every update

---

## 10. Support & Maintenance

| Item | Detail |
|------|--------|
| **Managed by** | Morpheus AI |
| **Contact** | Your Morpheus AI representative |
| **Backups** | Daily automated to DigitalOcean Spaces (30-day retention) |
| **SSL** | Let's Encrypt auto-renewing certificates |
| **Monitoring** | DigitalOcean built-in alerts + NinjaOne RMM |
| **Uptime SLA** | Best-effort (discuss SLA terms if required) |

---

## Completion Checklist

| Task | Owner | Status |
|------|-------|--------|
| Droplet provisioned + Tailscale installed | Morpheus AI | ☐ |
| **Black Raven team explores system via IP** | **Black Raven IT** | **☐** |
| Test accounts + orgs cleaned up | Black Raven IT (Service Desk Admin) | ☐ |
| Admin password changed | Black Raven IT | ☐ |
| DNS A record added | Black Raven IT (GoDaddy) | ☐ |
| SSL certificate provisioned | Morpheus AI | ☐ |
| Microsoft OAuth registered in Azure | Black Raven IT (Azure Admin) | ☐ |
| Microsoft OAuth configured in Zammad | Black Raven IT (Service Desk Admin) | ☐ |
| NinjaOne API credentials provided | Black Raven IT | ☐ |
| NinjaOne webhook configured | Black Raven IT (NinjaOne Admin) | ☐ |
| NinjaOne bridge activated on server | Morpheus AI | ☐ |
| Email channel configured | Black Raven IT (Service Desk Admin) | ☐ |
| Test ticket submitted | Black Raven IT | ☐ |
| NinjaOne enrollment token provided | Black Raven IT | ☐ |
| NinjaOne agent installed on droplet | Morpheus AI | ☐ |
| NinjaOne monitoring policies configured | Black Raven IT (NinjaOne Admin) | ☐ |
| Automated backups configured | Morpheus AI | ☐ |
