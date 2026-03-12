const express = require('express');
const crypto = require('crypto');
const { mapAlertToTicket, mapTicketStatusToAlert } = require('./field-mapper');
const ninjaClient = require('./ninja-client');
const zammadClient = require('./zammad-client');
const { handleAutoOnboard } = require('./auto-onboard');

const app = express();
const PORT = process.env.BRIDGE_PORT || 3001;
const WEBHOOK_SECRET = process.env.NINJAONE_WEBHOOK_SECRET;

// Parse JSON bodies with raw body access for HMAC validation
app.use(express.json({
  verify: (req, _res, buf) => { req.rawBody = buf; }
}));

// --- Health Check ---
app.get('/health', (_req, res) => {
  const status = {
    status: 'ok',
    service: 'blackraven-ninja-bridge',
    timestamp: new Date().toISOString(),
    ninjaone: !!process.env.NINJAONE_CLIENT_ID,
    zammad: !!process.env.ZAMMAD_API_TOKEN,
  };
  res.json(status);
});

// --- HMAC Signature Validation Middleware ---
function validateWebhookSignature(req, res, next) {
  if (!WEBHOOK_SECRET) {
    console.warn('[BRIDGE] NINJAONE_WEBHOOK_SECRET not set — skipping signature validation');
    return next();
  }

  const signature = req.headers['x-ninja-signature'] || req.headers['x-hub-signature-256'];
  if (!signature) {
    console.warn('[BRIDGE] Missing webhook signature header');
    return res.status(401).json({ error: 'Missing signature' });
  }

  const expected = 'sha256=' + crypto
    .createHmac('sha256', WEBHOOK_SECRET)
    .update(req.rawBody)
    .digest('hex');

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
    console.warn('[BRIDGE] Invalid webhook signature');
    return res.status(401).json({ error: 'Invalid signature' });
  }

  next();
}

// --- NinjaOne → Zammad (Alert Webhook) ---
app.post('/webhook', validateWebhookSignature, async (req, res) => {
  try {
    const event = req.body;
    console.log(`[BRIDGE] Received NinjaOne webhook: ${event.type || 'unknown'}`);

    // Handle different event types
    switch (event.type) {
      case 'ALERT_TRIGGERED':
      case 'ALERT_CREATED': {
        const ticketData = mapAlertToTicket(event);
        const ticket = await zammadClient.createTicket(ticketData);
        console.log(`[BRIDGE] Created Zammad ticket #${ticket.id} from NinjaOne alert ${event.alertId || event.id}`);
        return res.json({ success: true, ticketId: ticket.id });
      }

      case 'ALERT_RESOLVED':
      case 'ALERT_RESET': {
        // Find linked Zammad ticket and close it
        const searchResults = await zammadClient.searchTickets(`ninja_alert_id:${event.alertId || event.id}`);
        if (searchResults.length > 0) {
          await zammadClient.updateTicket(searchResults[0].id, { state: 'closed' });
          console.log(`[BRIDGE] Closed Zammad ticket #${searchResults[0].id} (NinjaOne alert resolved)`);
        }
        return res.json({ success: true });
      }

      case 'ORGANIZATION_CREATED':
      case 'CLIENT_CREATED': {
        await handleAutoOnboard(event);
        return res.json({ success: true });
      }

      default:
        console.log(`[BRIDGE] Unhandled event type: ${event.type}`);
        return res.json({ success: true, message: 'Event type not handled' });
    }
  } catch (err) {
    console.error('[BRIDGE] Error processing NinjaOne webhook:', err.message);
    return res.status(500).json({ error: 'Internal bridge error' });
  }
});

// --- Zammad → NinjaOne (Ticket Status Webhook) ---
app.post('/zammad-webhook', async (req, res) => {
  try {
    const event = req.body;
    console.log(`[BRIDGE] Received Zammad webhook for ticket #${event.ticket?.id || 'unknown'}`);

    const ticket = event.ticket;
    if (!ticket || !ticket.ninja_alert_id) {
      return res.json({ success: true, message: 'No linked NinjaOne alert' });
    }

    const alertUpdate = mapTicketStatusToAlert(ticket);
    if (alertUpdate) {
      await ninjaClient.updateAlert(ticket.ninja_alert_id, alertUpdate);
      console.log(`[BRIDGE] Updated NinjaOne alert ${ticket.ninja_alert_id} from ticket #${ticket.id}`);
    }

    return res.json({ success: true });
  } catch (err) {
    console.error('[BRIDGE] Error processing Zammad webhook:', err.message);
    return res.status(500).json({ error: 'Internal bridge error' });
  }
});

// --- Startup ---
app.listen(PORT, () => {
  console.log(`[BRIDGE] Black Raven NinjaOne Bridge running on port ${PORT}`);

  if (!process.env.NINJAONE_CLIENT_ID) {
    console.warn('[BRIDGE] WARNING: NINJAONE_CLIENT_ID not set — NinjaOne API calls will fail');
  }
  if (!process.env.ZAMMAD_API_TOKEN) {
    console.warn('[BRIDGE] WARNING: ZAMMAD_API_TOKEN not set — Zammad API calls will fail');
  }
  if (!WEBHOOK_SECRET) {
    console.warn('[BRIDGE] WARNING: NINJAONE_WEBHOOK_SECRET not set — webhook signatures will not be validated');
  }
});
