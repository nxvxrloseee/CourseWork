import api from './client';

export const getMessages = (ticketId: number) => api.get(`/chat/${ticketId}`);

export const sendMessage = (ticketId: number, text: string) =>
  api.post('/chat/send', { ticketId, text });
