const zammadClient = require('./zammad-client');

/**
 * Auto-onboard a new MSP client from NinjaOne into Zammad.
 *
 * When NinjaOne sends an ORGANIZATION_CREATED or CLIENT_CREATED webhook:
 * 1. Create a Zammad Organization (if not exists)
 * 2. Create a Zammad Customer user (primary contact)
 * 3. Zammad automatically sends a welcome/password-setup email to the new customer
 *
 * The customer can then:
 * - Click the email link to set their password
 * - Or use "Sign in with Microsoft" if their org is federated
 * - Submit and track tickets via the customer portal
 */
async function handleAutoOnboard(event) {
  const orgData = event.organization || event.client || event;
  const orgName = orgData.name || orgData.organizationName;

  if (!orgName) {
    console.warn('[ONBOARD] No organization name in webhook — skipping');
    return;
  }

  console.log(`[ONBOARD] Processing new client: ${orgName}`);

  // 1. Check if organization already exists in Zammad
  let zammadOrg = null;
  try {
    const existing = await zammadClient.searchOrganizations(orgName);
    if (Array.isArray(existing) && existing.length > 0) {
      zammadOrg = existing[0];
      console.log(`[ONBOARD] Organization "${orgName}" already exists in Zammad (ID: ${zammadOrg.id})`);
    }
  } catch (err) {
    // Search failed, proceed to create
  }

  // 2. Create organization if not found
  if (!zammadOrg) {
    try {
      zammadOrg = await zammadClient.createOrganization({
        name: orgName,
        domain: orgData.domain || '',
        domain_assignment: !!orgData.domain, // auto-assign users by email domain
        active: true,
        note: `Auto-created from NinjaOne on ${new Date().toISOString()}`,
      });
      console.log(`[ONBOARD] Created Zammad organization "${orgName}" (ID: ${zammadOrg.id})`);
    } catch (err) {
      console.error(`[ONBOARD] Failed to create organization "${orgName}":`, err.message);
      throw err;
    }
  }

  // 3. Create primary contact as Zammad customer (if contact info provided)
  const contact = orgData.primaryContact || orgData.contact || {};
  const contactEmail = contact.email || orgData.email;
  const contactName = contact.name || orgData.contactName;

  if (!contactEmail) {
    console.log(`[ONBOARD] No contact email for "${orgName}" — organization created but no user`);
    return;
  }

  // Check if user already exists
  try {
    const existingUser = await zammadClient.findUserByEmail(contactEmail);
    if (existingUser) {
      console.log(`[ONBOARD] User "${contactEmail}" already exists in Zammad (ID: ${existingUser.id})`);
      return;
    }
  } catch (err) {
    // Search failed, proceed to create
  }

  // Parse name
  const nameParts = (contactName || contactEmail.split('@')[0]).split(' ');
  const firstName = nameParts[0] || contactEmail.split('@')[0];
  const lastName = nameParts.slice(1).join(' ') || '';

  try {
    const user = await zammadClient.createUser({
      firstname: firstName,
      lastname: lastName,
      email: contactEmail,
      organization_id: zammadOrg.id,
      role_ids: [3], // Customer role (ID 3 in default Zammad)
      active: true,
      note: `Auto-onboarded from NinjaOne on ${new Date().toISOString()}`,
    });
    console.log(`[ONBOARD] Created Zammad customer "${contactEmail}" (ID: ${user.id}) for org "${orgName}"`);
    console.log(`[ONBOARD] Zammad will send a welcome email to ${contactEmail} with login instructions`);
  } catch (err) {
    console.error(`[ONBOARD] Failed to create user "${contactEmail}":`, err.message);
    throw err;
  }
}

module.exports = { handleAutoOnboard };
