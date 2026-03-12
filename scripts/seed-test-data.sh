#!/bin/bash
# Black Raven Service Desk — Seed Test Data
# Run AFTER first boot setup wizard completes
# Creates test users, organizations, groups, and sample tickets
#
# Usage: ./scripts/seed-test-data.sh
#
# Prerequisites:
#   - Zammad is running and setup wizard completed
#   - ZAMMAD_API_TOKEN set in .env (create via admin profile → Token Access)

set -e

# Load environment
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

ZAMMAD_URL="${ZAMMAD_API_URL:-http://localhost:3000}"
TOKEN="${ZAMMAD_API_TOKEN}"

if [ -z "$TOKEN" ]; then
  echo "ERROR: ZAMMAD_API_TOKEN not set. Create one in admin profile → Token Access, then add to .env"
  exit 1
fi

API="$ZAMMAD_URL/api/v1"
AUTH="Authorization: Token token=$TOKEN"
CT="Content-Type: application/json"

echo "=== Black Raven Service Desk — Seeding Test Data ==="
echo "API: $ZAMMAD_URL"
echo ""

# ─── Create Groups ───────────────────────────────────────
echo "Creating ticket groups..."

for group in "Helpdesk:General IT support" "Network:Network infrastructure" "Security:Security incidents" "Cloud:Cloud and M365" "Onboarding:New employee setup"; do
  name="${group%%:*}"
  note="${group##*:}"
  curl -s -X POST "$API/groups" \
    -H "$AUTH" -H "$CT" \
    -d "{\"name\": \"$name\", \"note\": \"$note\", \"active\": true}" \
    > /dev/null 2>&1 && echo "  ✓ Group: $name" || echo "  - Group: $name (may already exist)"
done

# ─── Create Organizations ────────────────────────────────
echo ""
echo "Creating test organizations..."

for org in '{"name":"Black Raven IT","domain":"blackravenit.com","note":"Internal MSP organization","active":true}' \
           '{"name":"TestCorp Industries","domain":"testcorp.com","note":"Sample client organization","active":true}' \
           '{"name":"Acme Healthcare","domain":"acmehealthcare.com","note":"Sample healthcare client","active":true}'; do
  name=$(echo "$org" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
  curl -s -X POST "$API/organizations" \
    -H "$AUTH" -H "$CT" \
    -d "$org" \
    > /dev/null 2>&1 && echo "  ✓ Organization: $name" || echo "  - Organization: $name (may already exist)"
done

# ─── Create Test Users ───────────────────────────────────
echo ""
echo "Creating test users..."

# Tech Lead (Agent)
curl -s -X POST "$API/users" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "login": "tech@blackravenit.com",
    "email": "tech@blackravenit.com",
    "firstname": "Alex",
    "lastname": "Martinez",
    "organization": "Black Raven IT",
    "password": "TestTech2026!",
    "active": true,
    "roles": ["Agent"]
  }' > /dev/null 2>&1 && echo "  ✓ Agent: Alex Martinez (tech@blackravenit.com / TestTech2026!)" || echo "  - Agent: tech@ (may already exist)"

# Helpdesk Agent
curl -s -X POST "$API/users" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "login": "helpdesk@blackravenit.com",
    "email": "helpdesk@blackravenit.com",
    "firstname": "Jordan",
    "lastname": "Chen",
    "organization": "Black Raven IT",
    "password": "TestHelp2026!",
    "active": true,
    "roles": ["Agent"]
  }' > /dev/null 2>&1 && echo "  ✓ Agent: Jordan Chen (helpdesk@blackravenit.com / TestHelp2026!)" || echo "  - Agent: helpdesk@ (may already exist)"

# Test Client (Customer)
curl -s -X POST "$API/users" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "login": "client@testcorp.com",
    "email": "client@testcorp.com",
    "firstname": "Sam",
    "lastname": "Wilson",
    "organization": "TestCorp Industries",
    "password": "TestClient2026!",
    "active": true,
    "roles": ["Customer"]
  }' > /dev/null 2>&1 && echo "  ✓ Customer: Sam Wilson (client@testcorp.com / TestClient2026!)" || echo "  - Customer: client@ (may already exist)"

# ─── Create Sample Tickets ───────────────────────────────
echo ""
echo "Creating sample tickets..."

# Ticket 1: Network issue
curl -s -X POST "$API/tickets" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "title": "Office WiFi dropping connections intermittently",
    "group": "Network",
    "customer": "client@testcorp.com",
    "priority_id": 2,
    "state_id": 2,
    "article": {
      "subject": "WiFi connectivity issues",
      "body": "Our office WiFi has been dropping connections every 30-60 minutes since Monday. Affects about 15 users on the 3rd floor. Access points were rebooted but issue persists.",
      "type": "note",
      "internal": false
    }
  }' > /dev/null 2>&1 && echo "  ✓ Ticket: WiFi dropping connections" || echo "  - Ticket 1 failed"

# Ticket 2: Security alert
curl -s -X POST "$API/tickets" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "title": "Suspicious login attempts detected on mail server",
    "group": "Security",
    "customer": "client@testcorp.com",
    "priority_id": 3,
    "state_id": 2,
    "article": {
      "subject": "Suspicious login attempts",
      "body": "NinjaOne flagged 47 failed login attempts on the Exchange server from IP 185.220.101.xx over the past 2 hours. GeoIP shows Eastern Europe. Need immediate review.",
      "type": "note",
      "internal": false
    }
  }' > /dev/null 2>&1 && echo "  ✓ Ticket: Suspicious login attempts (Security)" || echo "  - Ticket 2 failed"

# Ticket 3: Onboarding
curl -s -X POST "$API/tickets" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "title": "New hire onboarding - Jennifer Park starting 3/24",
    "group": "Onboarding",
    "customer": "client@testcorp.com",
    "priority_id": 2,
    "state_id": 1,
    "article": {
      "subject": "New employee setup",
      "body": "New hire Jennifer Park starting March 24th. Role: Marketing Manager. Needs: Laptop (Windows), M365 license, Teams, SharePoint access to Marketing site, VPN, building badge request. Manager: Dave Thompson.",
      "type": "note",
      "internal": false
    }
  }' > /dev/null 2>&1 && echo "  ✓ Ticket: New hire onboarding" || echo "  - Ticket 3 failed"

# Ticket 4: Cloud issue
curl -s -X POST "$API/tickets" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "title": "Azure AD sync failing - users not provisioning",
    "group": "Cloud",
    "customer": "client@testcorp.com",
    "priority_id": 3,
    "state_id": 2,
    "article": {
      "subject": "Azure AD Connect sync failure",
      "body": "Azure AD Connect has not synced in 3 days. New users created in on-prem AD are not appearing in M365. Error in Event Viewer: Export to Azure AD failed with stopped-extension-dll-exception. Affecting 4 new hires who cannot access cloud resources.",
      "type": "note",
      "internal": false
    }
  }' > /dev/null 2>&1 && echo "  ✓ Ticket: Azure AD sync failing (Cloud)" || echo "  - Ticket 4 failed"

# Ticket 5: Helpdesk - resolved
curl -s -X POST "$API/tickets" \
  -H "$AUTH" -H "$CT" \
  -d '{
    "title": "Cannot print to shared printer on 2nd floor",
    "group": "Helpdesk",
    "customer": "client@testcorp.com",
    "priority_id": 1,
    "state_id": 4,
    "article": {
      "subject": "Printer issue",
      "body": "User reports cannot print to HP LaserJet on 2nd floor. Print jobs stuck in queue. Resolved: cleared print spooler, reinstalled driver, test page printed successfully.",
      "type": "note",
      "internal": false
    }
  }' > /dev/null 2>&1 && echo "  ✓ Ticket: Printer issue (Closed)" || echo "  - Ticket 5 failed"

echo ""
echo "=== Seed Complete ==="
echo ""
echo "Test Credentials:"
echo "  Admin:    admin@blackravenit.com   (password set during setup wizard)"
echo "  Tech:     tech@blackravenit.com    / TestTech2026!"
echo "  Helpdesk: helpdesk@blackravenit.com / TestHelp2026!"
echo "  Client:   client@testcorp.com      / TestClient2026!"
echo ""
echo "NOTE: Change all test passwords before connecting to production systems."
echo "NOTE: Deactivate test users when switching to Microsoft OAuth."
