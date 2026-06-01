'use client';

import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Button from "@/components/ui/button/Button";
import { ChevronLeftIcon, EyeCloseIcon, EyeIcon } from "@/icons";
import Link from "next/link";
import { useRouter } from "next/navigation";
import React, { useState } from "react";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://dev.dyslexic.app';


const ADMIN_CREDENTIALS = {
  username: process.env.NEXT_PUBLIC_ADMIN_USERNAME || '',
  password: process.env.NEXT_PUBLIC_ADMIN_PASSWORD || '',
};

type AdminLoginRequest = {
  username: string;
  password: string;
};

type AdminInfo = {
  admin_id: string;
  username: string;
  must_change_password: boolean;
  is_active: boolean;
  created_at: string;
  last_login?: string;
};

type AdminTokenResponse = {
  access_token: string;
  token_type: string;
  expires_in: number;
  admin: AdminInfo;
};

// ✅ Validasi credentials lokal sebelum call API
function validateCredentials(credentials: AdminLoginRequest): boolean {
  if (!ADMIN_CREDENTIALS.username || !ADMIN_CREDENTIALS.password) {
    return false;
  }
  return (
    credentials.username === ADMIN_CREDENTIALS.username &&
    credentials.password === ADMIN_CREDENTIALS.password
  );
}

async function adminLogin(
  credentials: { username: string; password: string }
): Promise<{ data?: any; error?: { status: number; message: string } }> {
  try {
    // ✅ Gunakan relative path ke proxy Next.js (bukan full URL)
    const response = await fetch('/api/admin/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
      cache: 'no-store', // Pastikan tidak di-cache
    });

    const result = await response.json();

    if (!response.ok) {
      return {
        error: {
          status: response.status,
          message: result.error || 'Login failed',
        },
      };
    }

    return { data: result.data };
  } catch (error: any) {
    return {
      error: {
        status: 0,
        message: error.message || 'Network error',
      },
    };
  }
}

function setAdminToken(token: string, adminInfo: AdminInfo): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem('admin_token', token);
  localStorage.setItem('admin_info', JSON.stringify(adminInfo));
  document.cookie = `admin_token=${token}; path=/; max-age=${60 * 60 * 24}; SameSite=Lax${process.env.NODE_ENV === 'production' ? '; Secure' : ''}`;
}

export default function SignInForm() {
  const router = useRouter();
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({ username: '', password: '' });

  const handleChange = (field: 'username' | 'password') => (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData(prev => ({ ...prev, [field]: e.target.value }));
    setError(null);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    try {
      const response = await adminLogin(formData);
      
      if (response.error) {
        setError(response.error.message || 'Login failed.');
        return;
      }

      if (response.data?.access_token) {
        setAdminToken(response.data.access_token, response.data.admin);
        await new Promise(resolve => setTimeout(resolve, 100));
        
        if (response.data.admin.must_change_password) {
          router.push('/admin/change-password?first_login=true');
        } else {
          router.push('/admin/dashboard');
        }
        router.refresh();
      }
    } catch (err: any) {
      setError(err.message || 'An unexpected error occurred');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col flex-1 lg:w-1/2 w-full">
      <div className="w-full max-w-md sm:pt-10 mx-auto mb-5">
        <Link href="/" className="inline-flex items-center gap-2 text-sm text-gray-500 transition-colors hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300">
          <ChevronLeftIcon className="w-4 h-4" />
          Back to Home
        </Link>
      </div>

      <div className="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
        <div>
          <div className="mb-5 sm:mb-8">
            <h1 className="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md">
              Admin Sign In
            </h1>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              Enter your admin credentials to access the dashboard
            </p>
          </div>

          {error && (
            <div className="mb-4 p-3 rounded-lg bg-red-50 border border-red-200 dark:bg-red-900/20 dark:border-red-800">
              <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="space-y-6">
              <div>
                <Label>Username <span className="text-error-500">*</span></Label>
                <Input
                  placeholder="Enter username"
                  type="text"
                  value={formData.username}
                  onChange={handleChange('username')}
                  disabled={isLoading}
                  autoComplete="username"
                />
              </div>

              <div>
                <Label>Password <span className="text-error-500">*</span></Label>
                <div className="relative">
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
                    className="absolute z-30 -translate-y-1/2 cursor-pointer right-4 top-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                    aria-label={showPassword ? "Hide password" : "Show password"}
                    disabled={isLoading}
                  >
                    {showPassword ? <EyeIcon className="w-5 h-5" /> : <EyeCloseIcon className="w-5 h-5" />}
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <input type="checkbox" id="remember" className="w-4 h-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500" />
                  <label htmlFor="remember" className="block font-normal text-gray-700 text-theme-sm dark:text-gray-400 cursor-pointer">
                    Keep me logged in
                  </label>
                </div>
                <Link href="/admin/reset-password" className="text-sm text-brand-500 hover:text-brand-600 dark:text-brand-400">
                  Forgot password?
                </Link>
              </div>

              <div>
                <Button type="submit" className="w-full" size="sm" disabled={isLoading || !formData.username || !formData.password}>
                  {isLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                      </svg>
                      Signing in...
                    </span>
                  ) : 'Sign in'}
                </Button>
              </div>
            </div>
          </form>

          <div className="mt-5">
            <p className="text-sm font-normal text-center text-gray-700 dark:text-gray-400 sm:text-start">
              Not an admin?{' '}
              <Link href="/signup" className="text-brand-500 hover:text-brand-600 dark:text-brand-400">
                Sign up as user
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}