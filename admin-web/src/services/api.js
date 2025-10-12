import axios from 'axios';

const API_BASE_URL = 'http://localhost:8000/api/v1';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Intercepteur pour ajouter le token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const adminAPI = {
  // Auth
  login: (email, password) => api.post('/auth/admin/login', { email, password }),
  
  // Dashboard Stats
  getStats: () => api.get('/admin/stats'),
  
  // Drivers
  getDrivers: (params) => api.get('/admin/drivers', { params }),
  getDriver: (id) => api.get(`/admin/drivers/${id}`),
  updateDriverStatus: (id, status) => api.put(`/admin/drivers/${id}/status`, { status }),
  suspendDriver: (id, reason) => api.put(`/admin/drivers/${id}/suspend`, { reason }),
  
  // Rides
  getRides: (params) => api.get('/admin/rides', { params }),
  getRide: (id) => api.get(`/admin/rides/${id}`),
  cancelRide: (id, reason) => api.put(`/admin/rides/${id}/cancel`, { reason }),
  
  // Real-time monitoring
  getActiveRides: () => api.get('/admin/rides/active'),
  getOnlineDrivers: () => api.get('/admin/drivers/online'),
  
  // Reports
  getRevenueReport: (startDate, endDate) => 
    api.get('/admin/reports/revenue', { params: { startDate, endDate } }),
  getDriverPerformance: (startDate, endDate) => 
    api.get('/admin/reports/drivers', { params: { startDate, endDate } }),
};

export default api;

