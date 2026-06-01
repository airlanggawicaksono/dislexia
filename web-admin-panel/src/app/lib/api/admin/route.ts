// app/api/admin/login/route.ts
import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

export async function POST(request: Request) {
  try {
    const { username, password } = await request.json();

    // Validasi input dasar
    if (!username || !password) {
      return NextResponse.json(
        { error: 'Username and password are required' },
        { status: 400 }
      );
    }

    // Server-side fetch ke backend API - no CORS issues
    const response = await fetch('https://dev.dyslexic.app/api/v1/admin/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({ username, password }),
    });

    // Parse response dengan error handling
    let data: any;
    const contentType = response.headers.get('content-type');
    
    try {
      data = contentType?.includes('application/json')
        ? await response.json()
        : await response.text();
    } catch {
      data = { error: 'Failed to parse server response' };
    }

    // Handle error dari backend
    if (!response.ok) {
      return NextResponse.json(
        { 
          error: typeof data === 'string' 
            ? data 
            : data?.detail || data?.message || `HTTP ${response.status}` 
        },
        { status: response.status }
      );
    }

    // Return sukses dengan token
    return NextResponse.json({ 
      success: true, 
      data: {
        access_token: data.access_token,
        token_type: data.token_type,
        expires_in: data.expires_in,
        admin: data.admin,
      }
    });
    
  } catch (error: any) {
    console.error('Proxy login error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}

// Handle OPTIONS preflight request untuk CORS
export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Origin': '*',
    },
  });
}