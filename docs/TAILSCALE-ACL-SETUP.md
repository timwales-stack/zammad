# Tailscale ACL Setup — Black Raven Service Desk

> **Internal Morpheus AI document — do NOT share with Black Raven IT.**
> This covers the Tailscale access control configuration to restrict Black Raven users to their Service Desk server only.

---

## Server Details

| Item | Value |
|------|-------|
| Droplet Name | `blackraven-servicedesk` |
| Public IP | `104.131.85.152` |
| Tailscale IP | `100.110.58.29` |
| Tailscale Hostname | `blackraven-servicedesk` |
| Staging URL | `https://staging.blackraven.morpheusweb.dev` |

---

## Step-by-Step: Restrict Black Raven to This Server Only

### Step 1: Create a Tailscale Tag for Black Raven Users

1. Go to [Tailscale Admin Console → Access Controls](https://login.tailscale.com/admin/acls)
2. In the JSON ACL editor, add a **tag** for Black Raven under `tagOwners`:

```json
"tagOwners": {
  "tag:blackraven": ["autogroup:admin"],
  "tag:morpheus-infra": ["autogroup:admin"]
}
```

### Step 2: Tag the Service Desk Server

1. Go to [Tailscale Admin Console → Machines](https://login.tailscale.com/admin/machines)
2. Find `blackraven-servicedesk`
3. Click the **...** menu → **Edit tags**
4. Add tag: `tag:blackraven`
5. Save

### Step 3: Create a Group for Black Raven Users

In the ACL editor, add a group:

```json
"groups": {
  "group:blackraven-team": [
    "william@blackravenit.com",
    "edgar@blackravenit.com"
  ]
}
```

### Step 4: Write the ACL Rule

Add this rule to the `acls` section. This allows Black Raven users to access ONLY the tagged `blackraven-servicedesk` server, on web ports only:

```json
{
  "action": "accept",
  "src": ["group:blackraven-team"],
  "dst": ["tag:blackraven:80,443,8090,8091"]
}
```

This means:
- Black Raven users **CAN** access `blackraven-servicedesk` on ports 80, 443, 8090 (production), 8091 (staging)
- Black Raven users **CANNOT** access SSH (22), any other port, or any other Morpheus machine
- Black Raven users **CANNOT** see or reach `morpheus-production`, `morpheus`, or `desktop-leqsl2f`

### Step 5: Ensure Morpheus Admin Retains Full Access

Make sure the existing Morpheus admin rule grants full access to all machines:

```json
{
  "action": "accept",
  "src": ["autogroup:admin"],
  "dst": ["*:*"]
}
```

### Step 6: Full ACL Example

Here is a complete ACL policy example:

```json
{
  "tagOwners": {
    "tag:blackraven": ["autogroup:admin"],
    "tag:morpheus-infra": ["autogroup:admin"]
  },
  "groups": {
    "group:blackraven-team": [
      "william@blackravenit.com",
      "edgar@blackravenit.com"
    ]
  },
  "acls": [
    // Morpheus admins can access everything
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["*:*"]
    },
    // Black Raven team can ONLY access their service desk (web + staging ports)
    {
      "action": "accept",
      "src": ["group:blackraven-team"],
      "dst": ["tag:blackraven:80,443,8090,8091"]
    }
  ],
  "ssh": [
    // Only Morpheus admins can SSH into any machine
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    }
  ]
}
```

> **Important:** Review your existing ACL rules before replacing. The example above is a starting point — merge it with any existing rules you have for other Morpheus machines.

### Step 7: Test

1. Invite a test Black Raven user (or use a test account)
2. Approve their device in the Tailscale admin console
3. Verify they can reach `https://staging.blackraven.morpheusweb.dev`
4. Verify they **cannot** ping or reach `morpheus-production` (100.68.235.89) or `morpheus` (100.103.223.80)

---

## Adding/Removing Black Raven Users

### To Add a User
1. Go to ACL editor → update `group:blackraven-team` with their email
2. Send them a Tailscale invite link
3. Approve their device when it appears in the Machines list

### To Remove a User
1. Remove their email from `group:blackraven-team` in the ACL
2. Go to Machines → find their device → **Remove**

---

## When Black Raven DNS Goes Live

Once `support.blackravenit.com` is pointed to `104.131.85.152`:
1. Black Raven's regular users (agents, customers) access via the public URL — no Tailscale needed
2. Tailscale access becomes admin-only (for Black Raven admins who want direct access during maintenance)
3. Consider removing port 8090 from the ACL rule at that point (only 80/443 needed)
