const axios = require('axios');

const API_URL = process.env.ZAMMAD_API_URL || 'http://zammad-railsserver:3000';
const API_TOKEN = process.env.ZAMMAD_API_TOKEN;

/**
 * Make authenticated API request to Zammad
 */
async function apiRequest(method, path, data = null) {
  if (!API_TOKEN) {
    throw new Error('ZAMMAD_API_TOKEN is required');
  }

  const config = {
    method,
    url: `${API_URL}/api/v1${path}`,
    headers: {
      Authorization: `Token token=${API_TOKEN}`,
      'Content-Type': 'application/json',
    },
  };
  if (data) config.data = data;

  const resp = await axios(config);
  return resp.data;
}

module.exports = {
  // Tickets
  createTicket: (data) => apiRequest('POST', '/tickets', data),
  updateTicket: (id, data) => apiRequest('PUT', `/tickets/${id}`, data),
  getTicket: (id) => apiRequest('GET', `/tickets/${id}`),
  searchTickets: async (query) => {
    const resp = await apiRequest('GET', `/tickets/search?query=${encodeURIComponent(query)}`);
    return resp.assets?.Ticket ? Object.values(resp.assets.Ticket) : [];
  },

  // Organizations
  createOrganization: (data) => apiRequest('POST', '/organizations', data),
  searchOrganizations: async (query) => {
    const resp = await apiRequest('GET', `/organizations/search?query=${encodeURIComponent(query)}`);
    return resp || [];
  },

  // Users
  createUser: (data) => apiRequest('POST', '/users', data),
  findUserByEmail: async (email) => {
    const resp = await apiRequest('GET', `/users/search?query=${encodeURIComponent(email)}`);
    return resp && resp.length > 0 ? resp[0] : null;
  },
};
