export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://dev.dyslexic.app';

export type ApiResponse<T> = {
  data?: T;
  error?: { status: number; message: string; details?: any };
};

export async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      headers: { 'Content-Type': 'application/json', ...options.headers },
      ...options,
    });

    const contentType = response.headers.get('content-type');
    const data = contentType?.includes('application/json') 
      ? await response.json() 
      : await response.text();

    if (!response.ok) {
      return {
        error: {
          status: response.status,
          message: typeof data === 'string' ? data : data?.detail || 'Request failed',
          details: data,
        },
      };
    }

    return { data: data as T };
  } catch (error: any) {
    return { error: { status: 0, message: error.message || 'Network error' } };
  }
}

export function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('admin_token');
}

export function setAuthToken(token: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem('admin_token', token);
  document.cookie = `admin_token=${token}; path=/; max-age=${60*60*24}; SameSite=Lax`;
}

export function removeAuthToken(): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem('admin_token');
  document.cookie = 'admin_token=; path=/; max-age=0';
}

export function getAuthHeaders(): HeadersInit {
  const token = getAuthToken();
  return { 'Authorization': token ? `Bearer ${token}` : '' };
}