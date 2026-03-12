/**
 * NinjaOne Alert → Zammad Ticket Field Mapping
 *
 * NinjaOne Field          → Zammad Field
 * alert.message           → ticket.title
 * alert.device.name       → ticket.article.body (device context)
 * alert.severity          → ticket.priority (critical→3, warning→2, info→1)
 * alert.type              → ticket.group (mapped to service category)
 * alert.organization      → ticket.customer (matched by org name)
 * alert.id                → ticket.ninja_alert_id (custom field)
 */

// Severity mapping: NinjaOne severity → Zammad priority ID
const SEVERITY_MAP = {
  critical: 3,   // High
  major: 3,      // High
  warning: 2,    // Normal
  minor: 2,      // Normal
  info: 1,       // Low
  none: 1,       // Low
};

// Alert type → Zammad group mapping
const GROUP_MAP = {
  patch_management: 'Helpdesk',
  antivirus: 'Security',
  backup: 'Helpdesk',
  disk_space: 'Helpdesk',
  system: 'Helpdesk',
  network: 'Network',
  hardware: 'Helpdesk',
  software: 'Helpdesk',
  cloud: 'Cloud',
  security: 'Security',
};

/**
 * Map a NinjaOne alert webhook to a Zammad ticket creation payload
 */
function mapAlertToTicket(event) {
  const alert = event.alert || event;
  const device = alert.device || event.device || {};
  const org = alert.organization || event.organization || {};

  const severity = (alert.severity || alert.priority || 'info').toLowerCase();
  const alertType = (alert.type || alert.sourceType || 'system').toLowerCase();

  const deviceInfo = [
    device.name && `Device: ${device.name}`,
    device.systemName && `System: ${device.systemName}`,
    device.ipAddress && `IP: ${device.ipAddress}`,
    device.os && `OS: ${device.os}`,
    org.name && `Organization: ${org.name}`,
  ].filter(Boolean).join('\n');

  return {
    title: alert.message || alert.subject || `NinjaOne Alert: ${alertType}`,
    group: GROUP_MAP[alertType] || 'Helpdesk',
    priority_id: SEVERITY_MAP[severity] || 2,
    customer_id: 'guess:' + (org.email || `noreply@${org.name || 'unknown'}.com`),
    article: {
      subject: alert.message || `NinjaOne Alert: ${alertType}`,
      body: `<h3>NinjaOne Alert</h3>
<p><strong>Alert:</strong> ${alert.message || 'No message'}</p>
<p><strong>Severity:</strong> ${severity}</p>
<p><strong>Type:</strong> ${alertType}</p>
<hr/>
<pre>${deviceInfo || 'No device info available'}</pre>
<hr/>
<p><em>Auto-created by NinjaOne Bridge</em></p>`,
      type: 'note',
      internal: false,
      content_type: 'text/html',
    },
    // Custom field to track NinjaOne alert linkage
    ninja_alert_id: String(alert.id || event.alertId || event.id || ''),
  };
}

/**
 * Map Zammad ticket state to NinjaOne alert update
 */
function mapTicketStatusToAlert(ticket) {
  const stateMap = {
    closed: 'RESOLVED',
    merged: 'RESOLVED',
    'pending close': 'ACKNOWLEDGED',
    open: 'ACTIVE',
    new: 'ACTIVE',
    'pending reminder': 'ACKNOWLEDGED',
  };

  const state = (ticket.state || '').toLowerCase();
  const ninjaStatus = stateMap[state];

  if (!ninjaStatus) return null;

  return {
    status: ninjaStatus,
    note: `Ticket #${ticket.id} status changed to ${ticket.state} in Black Raven Service Desk`,
  };
}

module.exports = { mapAlertToTicket, mapTicketStatusToAlert };
