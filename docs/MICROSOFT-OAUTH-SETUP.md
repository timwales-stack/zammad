# Microsoft OAuth Setup — Black Raven Service Desk

## Overview

This guide configures Microsoft Entra ID (Azure AD) as the primary authentication provider for the Black Raven Service Desk. All agents and technicians will use "Sign in with Microsoft" to access the system.

---

## Step 1: Register Application in Azure Portal

1. Go to [Azure Portal](https://portal.azure.com) → **Microsoft Entra ID** → **App registrations**
2. Click **New registration**
3. Configure:
   - **Name:** `Black Raven Service Desk`
   - **Supported account types:** `Accounts in this organizational directory only` (Single tenant)
   - **Redirect URI:** `Web` → `https://support.blackravenit.com/auth/microsoft_office365/callback`
4. Click **Register**
5. Note down:
   - **Application (client) ID** → This is your `MICROSOFT_APP_ID`
   - **Directory (tenant) ID** → This is your `MICROSOFT_TENANT_ID`

## Step 2: Create Client Secret

1. In the app registration, go to **Certificates & secrets**
2. Click **New client secret**
3. Set description: `Zammad Service Desk`
4. Set expiration: **24 months** (set calendar reminder to rotate)
5. Click **Add**
6. **Copy the secret value immediately** → This is your `MICROSOFT_APP_SECRET`
   - WARNING: You cannot view this value again after leaving the page

## Step 3: Configure API Permissions

1. Go to **API permissions**
2. Click **Add a permission** → **Microsoft Graph**
3. Select **Delegated permissions**
4. Add these permissions:
   - `openid` (Sign users in)
   - `profile` (View users' basic profile)
   - `email` (View users' email address)
   - `User.Read` (Sign in and read user profile)
5. Click **Grant admin consent for [Your Org]**

## Step 4: Configure Zammad

### Via Admin UI (Recommended)
1. Log into Zammad as admin: `https://support.blackravenit.com`
2. Go to **Settings** → **Security** → **Third-Party Applications**
3. Find **Microsoft / Office 365**
4. Enable it and configure:
   - **App ID:** `[Your MICROSOFT_APP_ID]`
   - **App Secret:** `[Your MICROSOFT_APP_SECRET]`
   - **App Tenant ID:** `[Your MICROSOFT_TENANT_ID]`
5. Save

### Via Environment Variables (Alternative)
Add to `.env`:
```
MICROSOFT_APP_ID=your-client-id
MICROSOFT_APP_SECRET=your-client-secret
MICROSOFT_TENANT_ID=your-tenant-id
```

## Step 5: Enforce MFA via Conditional Access

1. In Azure Portal → **Microsoft Entra ID** → **Security** → **Conditional Access**
2. Create new policy:
   - **Name:** `MFA for Service Desk`
   - **Users:** All users (or specific group)
   - **Cloud apps:** Select `Black Raven Service Desk` app
   - **Grant:** Require multifactor authentication
3. Enable policy

This ensures all users must complete MFA before accessing the service desk.

## Step 6: Enable Zammad 2FA (Secondary Layer)

1. In Zammad admin: **Settings** → **Security** → **Two-Factor Authentication**
2. Enable:
   - **Authenticator App** (TOTP) — Recommended for all agents
   - **Security Keys** (WebAuthn/FIDO2) — Optional for hardware key users
3. Set **Recovery Codes** to enabled (10 backup codes per user)

---

## User Provisioning

### Automatic (via OAuth)
When a user signs in with Microsoft for the first time, Zammad automatically creates their account with:
- Name (from Microsoft profile)
- Email (from Microsoft profile)
- Role: Customer (default — admin must promote to Agent)

### Via LDAP Sync (Recommended for Role Mapping)
1. In Zammad admin: **System** → **Integrations** → **LDAP**
2. Configure AD connection:
   - **Host:** Your AD domain controller
   - **SSL:** STARTTLS or SSL
   - **Base DN:** `DC=blackravenit,DC=com`
   - **Bind User:** Service account with read access
3. Map LDAP groups to Zammad roles:
   - `IT-Helpdesk` → Agent
   - `IT-Admins` → Admin
   - All others → Customer
4. Sync runs hourly automatically

---

## Hardening: Prevent Password Login

Zammad cannot natively disable password authentication (GitHub issue #4225). Workarounds:

1. **Set random passwords:** For all accounts created via SSO, set a 64-character random password that nobody knows
2. **LDAP role gating:** Only users in specific AD groups get Agent roles
3. **Monitor login methods:** Check Zammad logs for password-based logins and investigate

---

## Secret Rotation Schedule

| Secret | Rotation | Reminder |
|--------|----------|----------|
| Microsoft App Secret | Every 24 months | Set Azure Portal notification + calendar event |
| Zammad API Tokens | Every 12 months | Admin → Settings → API tokens |
| LDAP Bind Password | Per AD policy | Sync with AD password rotation |

---

## Troubleshooting

### "Redirect URI mismatch" error
- Verify the redirect URI in Azure matches exactly: `https://support.blackravenit.com/auth/microsoft_office365/callback`
- Check for trailing slashes, http vs https

### Users can't sign in
- Verify admin consent was granted for API permissions
- Check Conditional Access policies aren't blocking the app
- Verify tenant ID matches Black Raven's Azure AD tenant

### User created as Customer instead of Agent
- Configure LDAP group mapping (preferred) or manually promote in Zammad admin
- Auto-role assignment based on email domain is not natively supported

### SSO works but MFA not prompting
- Verify Conditional Access policy targets the correct app registration
- Check the policy is enabled (not in report-only mode)
