import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;
  
  // ✅ Pages yang TIDAK perlu redirect (public routes)
  const publicRoutes = [
    '/signin',
    '/signup',
    '/change-password',
    '/',
    '/api',
  ];
  
  // Check if accessing protected route
  const isProtectedRoute = pathname.startsWith('/admin') || 
                           pathname.startsWith('/user-management') ||
                           pathname.startsWith('/data-screening');
  
  // Skip untuk public routes
  if (publicRoutes.some(route => pathname === route || pathname.startsWith(route + '/'))) {
    return NextResponse.next();
  }
  
  // Redirect protected route ke signin jika tidak ada token
  if (isProtectedRoute) {
    const token = request.cookies.get('admin_token')?.value;
    
    if (!token) {
      const loginUrl = new URL('/signin', request.url);
      loginUrl.searchParams.set('from', pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico|public).*)',
  ],
};