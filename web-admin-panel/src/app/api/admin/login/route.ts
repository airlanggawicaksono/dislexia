// app/api/admin/login/route.ts
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';
export const runtime = 'nodejs'; // ✅ Pastikan menggunakan runtime Node.js

export async function POST(request: Request) {
  try {
    // ✅ Parse body dengan error handling
    let body: { username?: string; password?: string };
    try {
      body = await request.json();
    } catch (parseError) {
      console.error('Failed to parse request body:', parseError);
      return NextResponse.json(
        { error: 'Invalid request body' },
        { status: 400 }
      );
    }

    const { username, password } = body;

    // ✅ Validasi input
    if (!username || !password) {
      return NextResponse.json(
        { error: 'Username and password are required' },
        { status: 400 }
      );
    }

    console.log('🔄 Proxy: Forwarding login request to backend...');

    // ✅ Add timeout untuk mencegah hang
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 30000); // 30 detik

    try {
      // ✅ Server-side fetch ke backend API
      const backendResponse = await fetch('https://dev.dyslexic.app/api/v1/admin/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({ username, password }),
        signal: controller.signal,
        // ✅ Tambahkan cache: 'no-store' untuk mencegah caching
        cache: 'no-store',
      });

      clearTimeout(timeoutId);

      console.log('📡 Backend response status:', backendResponse.status);

      // ✅ Parse response dengan safe handling
      let data: any;
      const contentType = backendResponse.headers.get('content-type');
      
      try {
        if (contentType?.includes('application/json')) {
          data = await backendResponse.json();
        } else {
          const text = await backendResponse.text();
          // Coba parse sebagai JSON jika mungkin
          try {
            data = JSON.parse(text);
          } catch {
            data = { raw: text };
          }
        }
      } catch (parseError) {
        console.error('Failed to parse backend response:', parseError);
        data = { error: 'Failed to parse server response' };
      }

      // ✅ Handle error dari backend
      if (!backendResponse.ok) {
        console.log('❌ Backend returned error:', backendResponse.status, data);
        return NextResponse.json(
          { 
            error: typeof data === 'string' 
              ? data 
              : data?.detail || data?.message || data?.error || `HTTP ${backendResponse.status}` 
          },
          { 
            status: backendResponse.status,
            headers: {
              'Content-Type': 'application/json',
            }
          }
        );
      }

      // ✅ Return sukses dengan token
      console.log('✅ Login successful, returning token');
      return NextResponse.json(
        { 
          success: true, 
          data: {
            access_token: data.access_token,
            token_type: data.token_type,
            expires_in: data.expires_in,
            admin: data.admin,
          }
        },
        {
          headers: {
            'Content-Type': 'application/json',
          }
        }
      );
      
    } catch (fetchError: any) {
      clearTimeout(timeoutId);
      
      console.error('🌐 Fetch error to backend:', fetchError);
      
      // ✅ Handle specific fetch errors
      let errorMessage = 'Failed to connect to authentication server';
      if (fetchError.name === 'AbortError') {
        errorMessage = 'Request to authentication server timed out';
      } else if (fetchError.message?.includes('fetch failed')) {
        errorMessage = 'Unable to reach authentication server. Please check your network.';
      }
      
      return NextResponse.json(
        { error: errorMessage },
        { 
          status: 503, // Service Unavailable
          headers: { 'Content-Type': 'application/json' }
        }
      );
    }
    
  } catch (error: any) {
    console.error('💥 Unexpected error in proxy route:', error);
    
    return NextResponse.json(
      { error: 'Internal server error' },
      { 
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  }
}

// ✅ Handle OPTIONS preflight request
export async function OPTIONS(request: Request) {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Origin': request.headers.get('origin') || '*',
      'Access-Control-Max-Age': '86400',
    },
  });
}