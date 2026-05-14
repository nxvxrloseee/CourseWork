import api from './client';

export const getTickets = (params?: {
  status?: string;
  categoryId?: number;
  search?: string;
  sort?: string;
  excludeCompleted?: boolean;
}) => api.get('/tickets', { params });

export const getTicket = (id: number) => api.get(`/tickets/${id}`);

export const getMasterHistory = (params?: {
  status?: string;
  search?: string;
  sort?: string;
}) => api.get('/tickets/history', { params });

export const takeTicket = (id: number) => api.post(`/tickets/${id}/take`);

export const updateStatus = (id: number, status: string, comment?: string) =>
  api.patch(`/tickets/${id}/status`, { status, comment });

export const reschedule = (id: number, newDatetime: string) =>
  api.patch(`/tickets/${id}/reschedule`, { newDatetime });

export const getStatusHistory = (id: number) =>
  api.get(`/tickets/${id}/history`);

export const addServiceToTicket = (ticketId: number, serviceId: number, quantity: number) =>
  api.post(`/tickets/${ticketId}/services`, { serviceId, quantity });

export const removeServiceFromTicket = (ticketId: number, serviceId: number) =>
  api.delete(`/tickets/${ticketId}/services/${serviceId}`);

export const updateTicketServiceQuantity = (ticketId: number, ticketServiceId: number, quantity: number) =>
  api.patch(`/tickets/${ticketId}/services/${ticketServiceId}`, { quantity });
