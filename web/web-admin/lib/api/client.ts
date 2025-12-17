// API Client for backend communication
const API_BASE_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8080';

export class APIError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'APIError';
  }
}

async function fetchAPI(endpoint: string, options: RequestInit = {}) {
  const token = localStorage.getItem('auth_token')?.trim();

  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ message: 'Unknown error' }));
    throw new APIError(response.status, error.message || 'Request failed');
  }

  return response.json();
}

export const api = {
  // Admin Stats
  getStats: () => fetchAPI('/api/v1/admin/stats'),

  // Auth
  login: (email: string, password: string) =>
    fetchAPI('/api/v1/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  logout: () => fetchAPI('/api/v1/auth/logout', { method: 'POST' }),

  me: () => fetchAPI('/api/v1/auth/me'),

  // Content
  listContent: (params?: { status?: string; page?: number; limit?: number }) => {
    const query = new URLSearchParams(params as any).toString();
    return fetchAPI(`/api/v1/content${query ? `?${query}` : ''}`);
  },

  // Media
  listMedia: (params?: { page?: number; limit?: number }) => {
    const query = new URLSearchParams(params as any).toString();
    return fetchAPI(`/api/v1/media${query ? `?${query}` : ''}`);
  },

  // Stock
  listStock: () => fetchAPI('/api/v1/stock'),

  createStock: (data: {
    product_name: string;
    species: string;
    quantity: number;
    unit: string;
    location: string;
    temperature?: number;
    status: string;
  }) =>
    fetchAPI('/api/v1/stock', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateStock: (id: string, data: {
    product_name: string;
    species: string;
    quantity: number;
    unit: string;
    location: string;
    temperature?: number;
    status: string;
  }) =>
    fetchAPI(`/api/v1/stock/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteStock: (id: string) =>
    fetchAPI(`/api/v1/stock/${id}`, {
      method: 'DELETE',
    }),

  // Cold Chain
  listColdChain: () => fetchAPI('/api/v1/cold-chain'),

  createColdChain: (data: {
    product_name: string;
    batch_id: string;
    location: string;
    temperature: number;
    humidity?: number;
    status: string;
  }) =>
    fetchAPI('/api/v1/cold-chain', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateColdChain: (id: string, data: {
    product_name: string;
    batch_id: string;
    location: string;
    temperature: number;
    humidity?: number;
    status: string;
  }) =>
    fetchAPI(`/api/v1/cold-chain/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteColdChain: (id: string) =>
    fetchAPI(`/api/v1/cold-chain/${id}`, {
      method: 'DELETE',
    }),

  // Shipments
  listShipments: () => fetchAPI('/api/v1/shipments'),

  createShipment: (data: {
    tracking_number: string;
    customer: string;
    destination: string;
    departure_date: string;
    estimated_arrival: string;
    status: string;
    carrier: string;
    weight: number;
    temperature?: number;
  }) =>
    fetchAPI('/api/v1/shipments', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateShipment: (id: string, data: {
    tracking_number: string;
    customer: string;
    destination: string;
    departure_date: string;
    estimated_arrival: string;
    status: string;
    carrier: string;
    weight: number;
    temperature?: number;
  }) =>
    fetchAPI(`/api/v1/shipments/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteShipment: (id: string) =>
    fetchAPI(`/api/v1/shipments/${id}`, {
      method: 'DELETE',
    }),

  // Documents
  listDocuments: () => fetchAPI('/api/v1/documents'),

  createDocument: (data: {
    document_type: string;
    document_number: string;
    shipment_id?: string;
    customer: string;
    issue_date: string;
    expiry_date: string;
    status: string;
    issuer: string;
  }) =>
    fetchAPI('/api/v1/documents', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateDocument: (id: string, data: {
    document_type: string;
    document_number: string;
    shipment_id?: string;
    customer: string;
    issue_date: string;
    expiry_date: string;
    status: string;
    issuer: string;
  }) =>
    fetchAPI(`/api/v1/documents/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteDocument: (id: string) =>
    fetchAPI(`/api/v1/documents/${id}`, {
      method: 'DELETE',
    }),

  // Certificates
  listCertificates: () => fetchAPI('/api/v1/certificates'),

  createCertificate: (data: {
    certificate_type: string;
    certificate_number: string;
    standard: string;
    issue_date: string;
    expiry_date: string;
    status: string;
    issuer: string;
    scope: string;
  }) =>
    fetchAPI('/api/v1/certificates', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  updateCertificate: (id: string, data: {
    certificate_type: string;
    certificate_number: string;
    standard: string;
    issue_date: string;
    expiry_date: string;
    status: string;
    issuer: string;
    scope: string;
  }) =>
    fetchAPI(`/api/v1/certificates/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    }),

  deleteCertificate: (id: string) =>
    fetchAPI(`/api/v1/certificates/${id}`, {
      method: 'DELETE',
    }),

  // Reports
  listReports: () => fetchAPI('/api/v1/reports'),

  createReport: (data: {
    name: string;
    description?: string;
    category: string;
    format: string;
    parameters?: any;
  }) =>
    fetchAPI('/api/v1/reports', {
      method: 'POST',
      body: JSON.stringify(data),
    }),

  deleteReport: (id: string) =>
    fetchAPI(`/api/v1/reports/${id}`, {
      method: 'DELETE',
    }),
};
