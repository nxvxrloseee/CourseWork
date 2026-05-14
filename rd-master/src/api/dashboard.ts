import api from './client';

export const getDashboard = () => api.get('/dashboard');

export const getRevenue = (from: string, to: string) =>
  api.get('/dashboard/revenue', { params: { from, to } });
