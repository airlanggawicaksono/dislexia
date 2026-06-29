'use client';

import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Button from "@/components/ui/button/Button";
import { EyeCloseIcon, EyeIcon } from "@/icons";
import { useRouter, useSearchParams } from "next/navigation";
import React, { useState, Suspense } from "react";

type AdminInfo = {
  admin_id: string;
  username: string;
  must_change_password: boolean;
  is_active: boolean;
  created_at: string;
  last_login?: string;
};

type AdminLoginResponse = {
  access_token: string;
  token_type: string;
  expires_in: number;
  admin: AdminInfo;
};

async function adminLogin(
  credentials: { username: string; password: string }
): Promise<{ data?: AdminLoginResponse; error?: string; status?: number }> {
  try {
    const response = await fetch('/api/proxy/api/v1/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
    });

    const result = await response.json();

    if (!response.ok) {
      let errorMessage = 'Login failed';
      
      if (response.status === 401) {
        errorMessage = 'Invalid username or password';
      } else if (response.status === 403) {
        errorMessage = 'Account has been deactivated';
      } else if (result.detail) {
        errorMessage = result.detail;
      }

      return { error: errorMessage, status: response.status };
    }

    return { data: result };
  } catch (error: any) {
    return {
      error: error.message || 'An error occurred',
      status: 0,
    };
  }
}

function setAdminToken(token: string, adminInfo: AdminInfo, rememberMe: boolean = false): void {
  if (typeof window === 'undefined') return;
  
  localStorage.setItem('admin_token', token);
  localStorage.setItem('admin_info', JSON.stringify(adminInfo));
  
  const days = rememberMe ? 30 : 1;
  const date = new Date();
  date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
  const expires = "; expires=" + date.toUTCString();
  document.cookie = `admin_token=${token}${expires}; path=/; SameSite=Lax${process.env.NODE_ENV === 'production' ? '; Secure' : ''}`;
}

function SignInFormContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const from = searchParams.get('from') || '/user-management';
  
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<{ username?: boolean; password?: boolean }>({});
  const [rememberMe, setRememberMe] = useState(false);
  const [formData, setFormData] = useState({ username: '', password: '' });

  const handleChange = (field: 'username' | 'password') => (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({ ...prev, [field]: e.target.value }));
    setError(null);
    setFieldErrors({});
  };

  const validateForm = (): string | null => {
    if (!formData.username.trim()) return 'Username is required';
    if (!formData.password) return 'Password is required';
    if (formData.username.length < 3) return 'Username must be at least 3 characters';
    if (formData.password.length < 8) return 'Password must be at least 8 characters';
    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setFieldErrors({});

    const validationError = validateForm();
    if (validationError) {
      setError(validationError);
      return;
    }

    setIsLoading(true);

    try {
      const response = await adminLogin(formData);
      
      if (response.error) {
        if (response.status === 401) {
          setError('❌ Invalid username or password. Please check your credentials and try again.');
          setFieldErrors({ username: true, password: true });
        } else if (response.status === 403) {
          setError('⚠️ Your account has been deactivated. Please contact the administrator.');
        } else {
          setError(response.error);
        }
        return;
      }

      if (response.data?.access_token) {
        setAdminToken(response.data.access_token, response.data.admin, rememberMe);
        
        await new Promise(resolve => setTimeout(resolve, 100));
        
        if (response.data.admin.must_change_password) {
          router.push('/change-password?first_login=true');
        } else {
          router.push(from);
        }
      }
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1 lg:w-1/2 w-full">
      <div className="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
        <div>
          <div className="mb-5 sm:mb-8">
            <h1 className="mb-2 font-semibold text-gray-800 text-title-sm sm:text-title-md">
              Admin Sign In
            </h1>
            <p className="text-sm text-gray-500">
              Enter your admin credentials to access the dashboard
            </p>
          </div>

          {error && (
            <div className={`mb-4 p-3 rounded-lg border ${
              error.includes('❌') 
                ? 'bg-red-50 border-red-200' 
                : error.includes('⚠️')
                ? 'bg-yellow-50 border-yellow-200'
                : 'bg-red-50 border-red-200'
            }`}>
              <p className={`text-sm ${
                error.includes('❌') 
                  ? 'text-red-600' 
                  : error.includes('⚠️')
                  ? 'text-yellow-700'
                  : 'text-red-600'
              }`}>
                {error}
              </p>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-6">
              <div>
                <Label>Username <span className="text-error-500">*</span></Label>
                <div className={fieldErrors.username ? 'ring-2 ring-red-500 rounded-lg' : ''}>
                  <Input
                    placeholder="Enter username"
                    type="text"
                    value={formData.username}
                    onChange={handleChange('username')}
                    disabled={isLoading}
                    autoComplete="username"
                    autoFocus
                  />
                </div>
                {fieldErrors.username && (
                  <p className="mt-1 text-xs text-red-500">Please check your username</p>
                )}
              </div>

              <div>
                <Label>Password <span className="text-error-500">*</span></Label>
                <div className={`relative ${fieldErrors.password ? 'ring-2 ring-red-500 rounded-lg' : ''}`}>
                  <Input
                    type={showPassword ? "text" : "password"}
                    placeholder="Enter your password"
                    value={formData.password}
                    onChange={handleChange('password')}
                    disabled={isLoading}
                    autoComplete="current-password"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2 text-gray-400"
                    disabled={isLoading}
                  >
                    {showPassword ? <EyeIcon className="w-5 h-5" /> : <EyeCloseIcon className="w-5 h-5" />}
                  </button>
                </div>
                {fieldErrors.password && (
                  <p className="mt-1 text-xs text-red-500">Please check your password</p>
                )}
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <input
                    type="checkbox"
                    id="remember"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                    disabled={isLoading}
                    className="w-4 h-4 rounded border-gray-300"
                  />
                  <label htmlFor="remember" className="text-sm text-gray-700 cursor-pointer">
                    Keep me logged in (30 days)
                  </label>
                </div>
              </div>

              <Button 
                type="submit" 
                className="w-full" 
                size="sm" 
                disabled={isLoading || !formData.username || !formData.password}
              >
                {isLoading ? 'Signing in...' : 'Sign in'}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default function SignInPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    }>
      <SignInFormContent />
    </Suspense>
  );
}