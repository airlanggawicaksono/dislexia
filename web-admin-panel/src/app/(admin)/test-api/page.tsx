"use client";

import React, { useState } from "react";

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "https://dev.dyslexic.app";
// ✅ Gunakan proxy untuk menghindari CORS
const PROXY_URL = "/api/proxy";

export default function TestApiPage() {
  const [manualToken, setManualToken] = useState("");
  const [response, setResponse] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // ✅ Credentials yang BENAR (dari Swagger)
  const CORRECT_USERNAME = "admin1231";
  const CORRECT_PASSWORD = "1dsn612u1jsy5u3";

  // Test 1: Health Check (tanpa token, langsung ke backend)
  const testHealthCheck = async () => {
    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      // Health check bisa langsung ke backend karena biasanya allow CORS
      const res = await fetch(`${API_BASE_URL}/health`);
      const data = await res.json().catch(() => null);
      
      setResponse({
        status: res.status,
        statusText: res.statusText,
        data: data,
      });
    } catch (err: any) {
      setError(`CORS Error: ${err.message}\n\n💡 Coba test login dulu, karena login menggunakan proxy.`);
    } finally {
      setLoading(false);
    }
  };

  // Test 2: Login Admin (menggunakan proxy)
  const testLogin = async () => {
    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      // ✅ Gunakan proxy untuk menghindari CORS
      const res = await fetch(`${PROXY_URL}/api/v1/admin/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          username: CORRECT_USERNAME,
          password: CORRECT_PASSWORD,
        }),
      });

      const data = await res.json().catch(() => null);
      
      setResponse({
        status: res.status,
        statusText: res.statusText,
        data: data,
      });

      // Auto-fill token jika login berhasil
      if (res.status === 200 && data?.access_token) {
        setManualToken(data.access_token);
        localStorage.setItem('admin_token', data.access_token);
        alert('✅ Login berhasil! Token disimpan ke localStorage');
      }
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Test 3: Create User (dengan proxy + token)
  const testCreateUser = async () => {
    if (!manualToken) {
      setError("Token kosong! Silakan login dulu.");
      return;
    }

    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      const res = await fetch(`${PROXY_URL}/api/v1/admin/users`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${manualToken}`,
        },
        body: JSON.stringify({}),
      });

      const data = await res.json().catch(() => null);
      
      setResponse({
        status: res.status,
        statusText: res.statusText,
        data: data,
      });
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Test 4: List Users (dengan proxy + token)
  const testListUsers = async () => {
    if (!manualToken) {
      setError("Token kosong! Silakan login dulu.");
      return;
    }

    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      const res = await fetch(`${PROXY_URL}/api/v1/admin/users`, {
        headers: {
          Authorization: `Bearer ${manualToken}`,
        },
      });

      const data = await res.json().catch(() => null);
      
      setResponse({
        status: res.status,
        statusText: res.statusText,
        data: data,
      });
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  // Test 5: Create User TANPA TOKEN (expect 401)
  const testCreateUserNoToken = async () => {
    setLoading(true);
    setError(null);
    setResponse(null);

    try {
      const res = await fetch(`${PROXY_URL}/api/v1/admin/users`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({}),
      });

      const data = await res.json().catch(() => null);
      
      setResponse({
        status: res.status,
        statusText: res.statusText,
        data: data,
        note: "⚠️ Ini seharusnya return 401 karena tidak ada token",
      });
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-4xl mx-auto space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">🧪 API Test Page (with Proxy)</h1>
        <p className="text-gray-600 mt-2">
          Test endpoint API menggunakan Next.js proxy untuk menghindari CORS
        </p>
      </div>

      {/* Info Box */}
      <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <h3 className="font-semibold text-blue-900 mb-2">📋 Informasi</h3>
        <ul className="text-sm text-blue-800 space-y-1">
          <li>• API Base URL: <code className="bg-blue-100 px-1 rounded">{API_BASE_URL}</code></li>
          <li>• Proxy URL: <code className="bg-blue-100 px-1 rounded">{PROXY_URL}</code></li>
          <li>• Menggunakan credentials: <strong>{CORRECT_USERNAME}</strong></li>
          <li>• Proxy akan forward request ke backend tanpa CORS issue</li>
        </ul>
      </div>

      {/* Manual Token Input */}
      <div className="bg-white p-4 rounded-lg shadow-sm border">
        <label className="block text-sm font-medium text-gray-700 mb-2">
          🔑 Manual Token (auto-fill setelah login)
        </label>
        <textarea
          value={manualToken}
          onChange={(e) => setManualToken(e.target.value)}
          placeholder="Paste JWT token di sini..."
          className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-xs"
          rows={3}
        />
        <div className="flex gap-2 mt-2">
          <button
            onClick={() => {
              const token = localStorage.getItem('admin_token');
              if (token) {
                setManualToken(token);
                alert('✅ Token loaded from localStorage');
              } else {
                alert('❌ No token in localStorage');
              }
            }}
            className="px-3 py-1 text-xs bg-gray-100 rounded hover:bg-gray-200"
          >
            Load from localStorage
          </button>
          <button
            onClick={() => {
              localStorage.setItem('admin_token', manualToken);
              alert('✅ Token saved to localStorage');
            }}
            className="px-3 py-1 text-xs bg-blue-100 rounded hover:bg-blue-200"
          >
            Save to localStorage
          </button>
        </div>
      </div>

      {/* Test Buttons */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <button
          onClick={testHealthCheck}
          disabled={loading}
          className="px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
        >
          🏥 Test Health Check (Direct)
        </button>

        <button
          onClick={testLogin}
          disabled={loading}
          className="px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
        >
          🔐 Test Login (via Proxy)
        </button>

        <button
          onClick={testListUsers}
          disabled={loading}
          className="px-4 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 disabled:opacity-50 transition-colors"
        >
          📋 Test List Users (via Proxy)
        </button>

        <button
          onClick={testCreateUser}
          disabled={loading}
          className="px-4 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors"
        >
          ➕ Test Create User (via Proxy)
        </button>

        <button
          onClick={testCreateUserNoToken}
          disabled={loading}
          className="px-4 py-3 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors md:col-span-2"
        >
          ❌ Test Create User (NO Token - Expect 401)
        </button>
      </div>

      {/* Loading */}
      {loading && (
        <div className="flex items-center justify-center p-8">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <span className="ml-4 text-gray-600">Loading...</span>
        </div>
      )}

      {/* Error */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <h3 className="font-semibold text-red-900 mb-2">❌ Error</h3>
          <pre className="text-sm text-red-800 font-mono whitespace-pre-wrap">{error}</pre>
        </div>
      )}

      {/* Response */}
      {response && (
        <div className="bg-white border rounded-lg overflow-hidden">
          <div className={`px-4 py-3 border-b ${
            response.status >= 200 && response.status < 300 
              ? 'bg-green-50 border-green-200' 
              : response.status >= 400 
              ? 'bg-red-50 border-red-200'
              : 'bg-yellow-50 border-yellow-200'
          }`}>
            <h3 className="font-semibold text-gray-900">
              📡 Response: {response.status} {response.statusText}
            </h3>
            {response.note && (
              <p className="text-sm text-yellow-800 mt-1">{response.note}</p>
            )}
          </div>
          <div className="p-4">
            <pre className="bg-gray-50 p-4 rounded-lg overflow-x-auto text-xs">
              {JSON.stringify(response.data, null, 2)}
            </pre>
          </div>
        </div>
      )}

      {/* Quick Guide */}
      <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
        <h3 className="font-semibold text-gray-900 mb-2">📖 Quick Guide</h3>
        <ol className="text-sm text-gray-700 space-y-2 list-decimal list-inside">
          <li>
            <strong>Test Login</strong> - Gunakan credentials yang benar
            <ul className="ml-6 mt-1 text-xs text-gray-600">
              <li>• Username: <code>{CORRECT_USERNAME}</code></li>
              <li>• Password: <code>{CORRECT_PASSWORD}</code></li>
              <li>• Jika 200 → token akan auto-fill</li>
            </ul>
          </li>
          <li>
            <strong>Test List Users</strong> - Cek apakah token valid
          </li>
          <li>
            <strong>Test Create User</strong> - Buat user baru
          </li>
        </ol>
      </div>
    </div>
  );
}