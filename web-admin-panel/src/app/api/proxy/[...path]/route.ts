import { NextRequest, NextResponse } from 'next/server';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://dev.dyslexic.app';

// ✅ Handler universal untuk semua HTTP methods
async function handleRequest(request: NextRequest, method: string) {
  try {
    // ✅ Parse path dari URL secara manual (lebih reliable)
    // URL format: /api/proxy/api/v1/admin/login
    // Kita butuh: api/v1/admin/login
    const url = new URL(request.url);
    const pathSegments = url.pathname.split('/');
    
    // Cari index 'proxy' dan ambil semua setelahnya
    const proxyIndex = pathSegments.indexOf('proxy');
    if (proxyIndex === -1) {
      return NextResponse.json(
        { error: 'Invalid proxy path' },
        { status: 400 }
      );
    }
    
    const targetPath = pathSegments.slice(proxyIndex + 1).join('/');
    const targetUrl = `${API_BASE_URL}/${targetPath}`;
    
    // Get query parameters
    const queryString = url.search;
    const fullUrl = queryString ? `${targetUrl}${queryString}` : targetUrl;

    console.log(`🔄 Proxy ${method}: ${fullUrl}`);

    // Prepare headers
    const headers = new Headers();
    
    // Copy important headers
    const contentType = request.headers.get('content-type');
    if (contentType) {
      headers.set('content-type', contentType);
    }

    const authHeader = request.headers.get('authorization');
    if (authHeader) {
      headers.set('authorization', authHeader);
    }

    // Prepare request options
    const options: RequestInit = {
      method,
      headers,
    };

    // Add body for POST/PUT/PATCH
    if (['POST', 'PUT', 'PATCH'].includes(method)) {
      const body = await request.text();
      if (body) {
        options.body = body;
        console.log(`📦 Body: ${body.substring(0, 100)}...`);
      }
    }

    // Make request to backend
    const response = await fetch(fullUrl, options);

    // Get response data
    const data = await response.text();

    console.log(`✅ Response: ${response.status} ${response.statusText}`);

    // Return response with same status
    return new NextResponse(data, {
      status: response.status,
      statusText: response.statusText,
      headers: {
        'content-type': response.headers.get('content-type') || 'application/json',
      },
    });
  } catch (error: any) {
    console.error('❌ Proxy error:', error);
    return NextResponse.json(
      { error: error.message || 'Proxy error' },
      { status: 500 }
    );
  }
}

// ✅ Export semua HTTP methods
export async function GET(request: NextRequest) {
  return handleRequest(request, 'GET');
}

export async function POST(request: NextRequest) {
  return handleRequest(request, 'POST');
}

export async function PUT(request: NextRequest) {
  return handleRequest(request, 'PUT');
}

export async function DELETE(request: NextRequest) {
  return handleRequest(request, 'DELETE');
}

export async function PATCH(request: NextRequest) {
  return handleRequest(request, 'PATCH');
}