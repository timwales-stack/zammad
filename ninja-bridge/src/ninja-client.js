const axios = require('axios');

const API_URL = process.env.NINJAONE_API_URL || 'https://app.ninjarmm.com';
const CLIENT_ID = process.env.NINJAONE_CLIENT_ID;
const CLIENT_SECRET = process.env.NINJAONE_CLIENT_SECRET;

let accessToken = null;
let tokenExpiry = 0;

/**
 * Get OAuth 2.0 access token using client credentials grant
 */
async function getAccessToken() {
  if (accessToken && Date.now() < tokenExpiry) return accessToken;

  if (!CLIENT_ID || !CLIENT_SECRET) {
    throw new Error('NINJAONE_CLIENT_ID and NINJAONE_CLIENT_SECRET are required');
  }

  const resp = await axios.post(`${API_URL}/oauth/token`, new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    scope: 'monitoring management',
  }), {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });

  accessToken = resp.data.access_token;
  tokenExpiry = Date.now() + (resp.data.expires_in - 60) * 1000; // refresh 60s early
  return accessToken;
}

/**
 * Make authenticated API request to NinjaOne
 */
async function apiRequest(method, path, data = null) {
  const token = await getAccessToken();
  const config = {
    method,
    url: `${API_URL}/v2${path}`,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  };
  if (data) config.data = data;

  const resp = await axios(config);
  return resp.data;
}

module.exports = {
  // Alerts
  getAlerts: () => apiRequest('GET', '/alerts'),
  getAlert: (id) => apiRequest('GET', `/alert/${id}`),
  updateAlert: (id, data) => apiRequest('PUT', `/alert/${id}`, data),
  resetAlert: (id) => apiRequest('POST', `/alert/${id}/reset`),

  // Organizations
  getOrganizations: () => apiRequest('GET', '/organizations'),
  getOrganization: (id) => apiRequest('GET', `/organization/${id}`),

  // Devices
  getDevices: () => apiRequest('GET', '/devices'),
  getDevice: (id) => apiRequest('GET', `/device/${id}`),
  getDeviceAlerts: (id) => apiRequest('GET', `/device/${id}/alerts`),
};
