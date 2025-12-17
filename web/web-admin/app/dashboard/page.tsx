'use client';

import { useEffect, useState } from 'react';
import { auth } from '@/lib/utils/auth';
import { api, APIError } from '@/lib/api/client';

interface Stats {
  tenant: { id: string; name: string };
  users: { total: number; active: number };
  content: { total: number; published: number; draft: number };
  media: { total: number; total_size: number };
}

export default function DashboardPage() {
  const [user, setUser] = useState(auth.getUser());
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setUser(auth.getUser());

    // Fetch stats
    api.getStats()
      .then(setStats)
      .catch((err: APIError) => {
        if (err.status === 401) {
          auth.logout();
          window.location.href = '/';
        } else {
          setError(err.message);
        }
      })
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      {/* Welcome Header */}
      <div className="bg-gradient-to-r from-cyan-600 to-teal-600 text-white rounded-2xl p-8 shadow-lg">
        <h1 className="text-3xl font-bold mb-2">Hoş geldiniz, {user?.name}!</h1>
        <p className="text-cyan-100">Balıkçılık yönetim sisteminize genel bakış</p>
      </div>

      {/* Stats Grid */}
      {loading && (
        <div className="text-center py-12">
          <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-cyan-600 border-r-transparent"></div>
          <p className="mt-2 text-slate-600">Yükleniyor...</p>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-xl p-4 text-red-800">
          <p className="font-medium">Hata:</p>
          <p className="text-sm">{error}</p>
        </div>
      )}

      {stats && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
              </div>
              <span className="text-2xl font-bold text-success">{stats.users.active}</span>
            </div>
            <h3 className="text-sm font-medium text-slate-600 mb-1">Aktif Kullanıcı</h3>
            <p className="text-2xl font-bold text-slate-900">{stats.users.total} Toplam</p>
          </div>

          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-teal-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-teal-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <span className="text-2xl font-bold text-success">{stats.content.published}</span>
            </div>
            <h3 className="text-sm font-medium text-slate-600 mb-1">Yayınlanan İçerik</h3>
            <p className="text-2xl font-bold text-slate-900">{stats.content.total} Toplam</p>
          </div>

          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg className="w-6 h-6 text-blue-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
                </svg>
              </div>
              <span className="text-2xl font-bold text-orange-600">{stats.content.draft}</span>
            </div>
            <h3 className="text-sm font-medium text-slate-600 mb-1">Taslak İçerik</h3>
            <p className="text-2xl font-bold text-slate-900">{stats.content.draft} Bekliyor</p>
          </div>

          <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <div className="w-12 h-12 bg-emerald-100 rounded-lg flex items-center justify-between">
                <svg className="w-6 h-6 text-emerald-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
              </div>
              <span className="text-2xl font-bold text-success">{stats.media.total}</span>
            </div>
            <h3 className="text-sm font-medium text-slate-600 mb-1">Medya Dosyası</h3>
            <p className="text-2xl font-bold text-slate-900">{(stats.media.total_size / 1024 / 1024).toFixed(1)} MB</p>
          </div>
        </div>
      )}

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <h2 className="text-lg font-bold text-slate-900 mb-4">Son Aktiviteler</h2>
          <div className="space-y-4">
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <div className="w-2 h-2 bg-cyan-600 rounded-full mt-2"></div>
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Yeni stok girişi</p>
                <p className="text-xs text-slate-600">1,250 kg Levrek - Soğuk hava deposu A</p>
                <p className="text-xs text-slate-400 mt-1">15 dakika önce</p>
              </div>
            </div>
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <div className="w-2 h-2 bg-emerald-600 rounded-full mt-2"></div>
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Sıcaklık kontrolü tamamlandı</p>
                <p className="text-xs text-slate-600">Tüm depolar normal sıcaklıkta</p>
                <p className="text-xs text-slate-400 mt-1">1 saat önce</p>
              </div>
            </div>
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <div className="w-2 h-2 bg-blue-600 rounded-full mt-2"></div>
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Sevkiyat başladı</p>
                <p className="text-xs text-slate-600">SHİP-2024-00342 - Almanya</p>
                <p className="text-xs text-slate-400 mt-1">3 saat önce</p>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-6">
          <h2 className="text-lg font-bold text-slate-900 mb-4">Yaklaşan Görevler</h2>
          <div className="space-y-4">
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <input type="checkbox" className="mt-1 rounded border-slate-300 text-cyan-600" />
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Sertifika yenileme</p>
                <p className="text-xs text-slate-600">MSC sertifikası - 15 gün sonra sona eriyor</p>
              </div>
            </div>
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <input type="checkbox" className="mt-1 rounded border-slate-300 text-cyan-600" />
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Kalite kontrol raporu</p>
                <p className="text-xs text-slate-600">Aylık rapor hazırlanacak</p>
              </div>
            </div>
            <div className="flex items-start gap-3 pb-4 border-b border-slate-100">
              <input type="checkbox" className="mt-1 rounded border-slate-300 text-cyan-600" />
              <div className="flex-1">
                <p className="text-sm font-medium text-slate-900">Stok sayımı</p>
                <p className="text-xs text-slate-600">Depo A ve B için haftalık sayım</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
