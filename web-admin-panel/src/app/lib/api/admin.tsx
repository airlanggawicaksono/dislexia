import { fetchApi, getAuthHeaders, setAuthToken, removeAuthToken } from './client';

export type AdminLoginRequest = { username: string; password: string };
export type AdminTokenResponse = { access_token: string; token_type: string; expires_in?: number };

export const adminApi = {
  async login(credentials: AdminLoginRequest) {
    return fetchApi<AdminTokenResponse>('/api/v1/admin/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  },
  
  async me() {
    return fetchApi('/api/v1/admin/me', { headers: getAuthHeaders() });
  },
  
  logout(): void {
    removeAuthToken();
  },
};