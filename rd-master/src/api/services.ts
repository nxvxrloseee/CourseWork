import api from './client';

export const getActiveServices = () => api.get('/services');

export const getAllServices = () => api.get('/services/all');

export const createService = (data: { name: string; description?: string; price: number }) =>
  api.post('/services', data);

export const updateService = (id: number, data: { name: string; description?: string; price: number }) =>
  api.put(`/services/${id}`, data);

export const deactivateService = (id: number) => api.patch(`/services/${id}/deactivate`);

export const activateService = (id: number) => api.patch(`/services/${id}/activate`);
