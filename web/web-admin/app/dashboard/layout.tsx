'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { auth } from '@/lib/utils/auth';
import WhatsAppButton from '@/components/WhatsAppButton';

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const router = useRouter();
  const [user, setUser] = useState<any>(null);
  const [remainingTime, setRemainingTime] = useState(0);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);

    // Check authentication
    const isAuth = auth.isAuthenticated();
    console.log('[Dashboard Layout] isAuthenticated:', isAuth);
    console.log('[Dashboard Layout] Token:', localStorage.getItem('auth_token')?.substring(0, 20) + '...');
    console.log('[Dashboard Layout] User:', auth.getUser());
    console.log('[Dashboard Layout] Login time:', localStorage.getItem('login_time'));

    if (!isAuth) {
      console.log('[Dashboard Layout] Not authenticated, redirecting to login');
      router.push('/');
      return;
    }

    setUser(auth.getUser());
    setRemainingTime(auth.getRemainingTime());

    // Update activity on any user interaction
    const updateActivity = () => {
      auth.updateActivity();
      setRemainingTime(auth.getRemainingTime());
    };

    // Listen to user activity
    window.addEventListener('click', updateActivity);
    window.addEventListener('keypress', updateActivity);
    window.addEventListener('scroll', updateActivity);

    // Check session timeout every minute
    const interval = setInterval(() => {
      if (!auth.isAuthenticated()) {
        alert('Oturumunuz sona erdi. Lütfen tekrar giriş yapın.');
        router.push('/');
      } else {
        setRemainingTime(auth.getRemainingTime());
      }
    }, 60000); // Check every minute

    return () => {
      window.removeEventListener('click', updateActivity);
      window.removeEventListener('keypress', updateActivity);
      window.removeEventListener('scroll', updateActivity);
      clearInterval(interval);
    };
  }, [router]);

  const handleLogout = () => {
    auth.logout();
    router.push('/');
  };

  // Format remaining time
  const formatTime = (ms: number) => {
    const minutes = Math.floor(ms / 60000);
    return `${minutes} dakika`;
  };

  return (
    <div className="min-h-screen bg-background-gray">
      {/* Top Navigation */}
      <nav className="bg-white border-b border-slate-200 sticky top-0 z-50 shadow-sm">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <svg className="w-8 h-8 text-cyan-600" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
              <span className="text-2xl font-bold text-slate-900">Yazıhanem</span>
            </div>

            <div className="flex items-center gap-6">
              {mounted && (
                <div className="hidden md:flex items-center gap-2 text-sm text-slate-600">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <span>Oturum süresi: {formatTime(remainingTime)}</span>
                </div>
              )}

              <div className="flex items-center gap-3">
                {mounted && user && (
                  <div className="text-right hidden md:block">
                    <div className="text-sm font-medium text-slate-900">{user.name}</div>
                    <div className="text-xs text-slate-500">{user.role}</div>
                  </div>
                )}
                <button
                  onClick={handleLogout}
                  className="px-4 py-2 text-sm text-slate-700 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Çıkış Yap
                </button>
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <div className="flex">
        {/* Sidebar */}
        <aside className="w-64 bg-white border-r border-slate-200 min-h-[calc(100vh-73px)] p-4">
          <nav className="space-y-1">
            <a
              href="/dashboard"
              className="flex items-center gap-3 px-4 py-3 text-cyan-700 bg-cyan-50 rounded-lg font-medium"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
              </svg>
              Dashboard
            </a>
            <a
              href="/dashboard/stock"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
              </svg>
              Stok Yönetimi
            </a>
            <a
              href="/dashboard/cold-chain"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              Soğuk Zincir
            </a>
            <a
              href="/dashboard/shipments"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
              </svg>
              Nakliye Takibi
            </a>
            <a
              href="/dashboard/documents"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              İhracat Belgeleri
            </a>
            <a
              href="/dashboard/certificates"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
              Sertifikalar
            </a>
            <a
              href="/dashboard/reports"
              className="flex items-center gap-3 px-4 py-3 text-slate-700 hover:bg-slate-50 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
              </svg>
              Raporlar
            </a>
          </nav>
        </aside>

        {/* Page Content */}
        <main className="flex-1 p-8">
          {children}
        </main>
      </div>

      {/* WhatsApp Support Button */}
      <WhatsAppButton />
    </div>
  );
}
