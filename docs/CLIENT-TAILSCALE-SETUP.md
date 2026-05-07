# Black Raven Service Desk — Secure VPN Access Guide

> **For:** William & Edgar at Black Raven IT
> **From:** Morpheus AI™ — Your Web Technology Partner

---

## What is Tailscale?

Tailscale is a lightweight VPN that creates a secure, private network between your devices and the Black Raven Service Desk server. It's used by companies like Instacart, GitHub, and Square.

**Why we use it:**
- Adds an extra layer of security for admin access
- No complex VPN configuration — installs in under 2 minutes
- Works automatically in the background
- Your access is limited to only the Service Desk — nothing else

---

## Step 1: Accept the Invitation

You'll receive an email invitation from Tailscale to join the network. Click the **"Accept Invite"** link in that email.

> If you don't see the email, check your spam/junk folder. The sender is `noreply@tailscale.com`.

---

## Step 2: Download & Install Tailscale

| Platform | Download Link |
|----------|--------------|
| **Windows** | https://tailscale.com/download/windows |
| **Mac** | https://tailscale.com/download/macos |
| **iOS** | Search "Tailscale" in the App Store |
| **Android** | Search "Tailscale" in Google Play |

### Installation Steps

1. Download and run the installer for your platform
2. After installation, Tailscale will ask you to **Sign in**
3. Sign in with the **same email address** that received the invitation
   - `william@blackravenit.com` or `edgar@blackravenit.com`
4. Tailscale will connect automatically

**That's it.** Once connected, Tailscale runs quietly in the background.

---

## Step 3: Access the Service Desk

Once Tailscale is connected, you can access the Black Raven Service Desk at:

### Production (Live System)
- **URL:** https://support.blackravenit.com
- This is the live ticketing system your team and clients use

### Staging (Testing Environment)
- **URL:** https://staging-support.blackravenit.com
- **Direct access:** http://100.110.58.29:8091 (via Tailscale only)
- This is the test environment for trying patches and upgrades before they go live
- Data here is separate from production — feel free to experiment

---

## How to Use the Staging Environment

Staging is your sandbox for testing changes before they go live. Here's what to do:

### Before Any Production Update
1. We'll apply the patch/upgrade to **staging first**
2. You'll receive a notification that staging is ready for testing
3. Log in to https://staging-support.blackravenit.com
4. Test the changes — create test tickets, check workflows, verify settings
5. If everything looks good, **give us the green light** and we'll apply to production
6. If something's wrong, let us know — production stays untouched

### What to Test on Staging
- **Create a test ticket** — verify it flows through your groups correctly
- **Check email notifications** — make sure templates look right
- **Test any new features** — try out whatever was just updated
- **Verify branding** — logo, colors, and naming still look correct
- **Check agent workflows** — assignments, notes, status changes

### Important Reminders
- Staging data is **completely separate** from production — nothing you do there affects live tickets
- Staging resets periodically — don't store anything important there
- Test accounts use the same credentials as production setup wizard

---

## What You CAN Access

| Service | URL | Purpose |
|---------|-----|---------|
| Production Service Desk | https://support.blackravenit.com | Live ticketing |
| Staging Service Desk | https://staging-support.blackravenit.com | Testing/upgrades |

## What You CANNOT Access

- SSH or terminal access to any server
- Any other Morpheus infrastructure or servers
- Internal management tools

Your access is strictly limited to the Service Desk web interfaces only.

---

## Troubleshooting

### "I can't connect to the Service Desk"
1. Check that Tailscale is running (look for the Tailscale icon in your system tray/menu bar)
2. Click the Tailscale icon — it should show "Connected"
3. If it says "Disconnected," click **Connect**
4. Try accessing https://support.blackravenit.com again

### "Tailscale says I'm not authorized"
- Your device may need to be approved. Contact us and we'll approve it within the hour.

### "I forgot which email to use"
- Use the same email that received the Tailscale invitation:
  - `william@blackravenit.com`
  - `edgar@blackravenit.com`

---

## Need Help?

Contact your Morpheus AI support team:
- **Email:** support@morpheusweb.ai
- **Response time:** Within 1 business hour during business hours (Mon-Fri, 9am-6pm EST)
