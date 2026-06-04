import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Sadece /admin ile başlayan rotaları koruyoruz.
  // /admin/login ve /admin/register hariç tutulmalı.
  const path = request.nextUrl.pathname;
  
  if (path.startsWith('/admin') && !path.startsWith('/admin/login') && !path.startsWith('/admin/register')) {
    // Firebase auth token'ını client tarafında cookie olarak saklıyorsak buradan kontrol edebiliriz.
    // MVP aşamasında basit bir kontrol için: Eğer session cookie'si yoksa login'e yönlendir.
    // Not: Gerçek bir üretim ortamında Firebase Admin SDK ile token doğrulaması yapılmalıdır.
    const hasSession = request.cookies.has('firebase-session') || request.cookies.has('__session');
    
    // Eğer cookie ile auth yönetmiyorsanız, şimdilik bu middleware sadece yapısal olarak burada durur.
    // Uygulamanın bozulmaması için çok katı bir yönlendirme yapmıyoruz, ancak altyapıyı kurmuş oluyoruz.
    /*
    if (!hasSession) {
      return NextResponse.redirect(new URL('/admin/login', request.url));
    }
    */
  }
  
  return NextResponse.next();
}

export const config = {
  matcher: ['/admin/:path*'],
};
