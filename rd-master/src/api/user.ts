import api from './client';

export const getProfile = () => api.get('/users/me');

export const updateProfile = (data: { surname?: string; name?: string; patronymic?: string }) =>
  api.put('/users/me', data);

export const changePassword = (data: { currentPassword: string; newPassword: string; confirmPassword: string }) =>
  api.put('/users/me/password', data);
