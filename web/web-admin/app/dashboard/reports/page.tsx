'use client';

import { useState } from 'react';

interface Report {
  id: string;
  name: string;
  description: string;
  category: 'stock' | 'sales' | 'quality' | 'compliance' | 'finance';
  format: 'pdf' | 'excel' | 'csv';
  icon: string;
}

export default function ReportsPage() {
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 1000 * 60 * 60 * 24 * 30).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });

  const reports: Report[] = [
    {
      id: '1',
      name: 'Stok Durum Raporu',
      description: 'Tüm ürünlerin güncel stok durumu ve hareketleri',
      category: 'stock',
      format: 'excel',
      icon: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4',
    },
    {
      id: '2',
      name: 'Satış Analizi',
      description: 'Müşteri bazlı satış performansı ve trend analizi',
      category: 'sales',
      format: 'pdf',
      icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z',
    },
    {
      id: '3',
      name: 'Soğuk Zincir İzleme Raporu',
      description: 'Sıcaklık kayıtları ve soğuk zincir uyumluluk raporu',
      category: 'quality',
      format: 'pdf',
      icon: 'M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 2 0 01-2 2h-2a2 2 0 01-2-2z',
    },
    {
      id: '4',
      name: 'İhracat Belgeleri Raporu',
      description: 'Tüm ihracat belgeleri ve onay durumları',
      category: 'compliance',
      format: 'excel',
      icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
    },
    {
      id: '5',
      name: 'Sevkiyat Performans Raporu',
      description: 'Teslimat süreleri, gecikmeler ve nakliye analizi',
      category: 'sales',
      format: 'pdf',
      icon: 'M13 10V3L4 14h7v7l9-11h-7z',
    },
    {
      id: '6',
      name: 'Kalite Kontrol Raporu',
      description: 'Ürün kalite testleri ve sertifika durumları',
      category: 'quality',
      format: 'pdf',
      icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z',
    },
    {
      id: '7',
      name: 'Finansal Özet Raporu',
      description: 'Gelir, gider ve karlılık analizi',
      category: 'finance',
      format: 'excel',
      icon: 'M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z',
    },
    {
      id: '8',
      name: 'Sertifika Geçerlilik Raporu',
      description: 'Tüm sertifikaların durumu ve yenileme takvimleri',
      category: 'compliance',
      format: 'pdf',
      icon: 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z',
    },
    {
      id: '9',
      name: 'Stok Hareket Raporu',
      description: 'Giriş, çıkış ve envanter değişimleri',
      category: 'stock',
      format: 'csv',
      icon: 'M7 16V4m0 0L3 8m4-4l4 4m6 0v12m0 0l4-4m-4 4l-4-4',
    },
    {
      id: '10',
      name: 'Müşteri Analiz Raporu',
      description: 'Müşteri segmentasyonu ve sipariş davranışları',
      category: 'sales',
      format: 'excel',
      icon: 'M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z',
    },
  ];

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'stock':
        return 'bg-blue-100 text-blue-800';
      case 'sales':
        return 'bg-purple-100 text-purple-800';
      case 'quality':
        return 'bg-green-100 text-green-800';
      case 'compliance':
        return 'bg-yellow-100 text-yellow-800';
      case 'finance':
        return 'bg-cyan-100 text-cyan-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getCategoryText = (category: string) => {
    switch (category) {
      case 'stock':
        return 'Stok';
      case 'sales':
        return 'Satış';
      case 'quality':
        return 'Kalite';
      case 'compliance':
        return 'Uyumluluk';
      case 'finance':
        return 'Finans';
      default:
        return category;
    }
  };

  const getFormatBadge = (format: string) => {
    const colors: Record<string, string> = {
      pdf: 'bg-red-100 text-red-800',
      excel: 'bg-green-100 text-green-800',
      csv: 'bg-orange-100 text-orange-800',
    };
    return colors[format] || 'bg-gray-100 text-gray-800';
  };

  const filteredReports = selectedCategory === 'all'
    ? reports
    : reports.filter(r => r.category === selectedCategory);

  const categories = [
    { id: 'all', name: 'Tümü', count: reports.length },
    { id: 'stock', name: 'Stok', count: reports.filter(r => r.category === 'stock').length },
    { id: 'sales', name: 'Satış', count: reports.filter(r => r.category === 'sales').length },
    { id: 'quality', name: 'Kalite', count: reports.filter(r => r.category === 'quality').length },
    { id: 'compliance', name: 'Uyumluluk', count: reports.filter(r => r.category === 'compliance').length },
    { id: 'finance', name: 'Finans', count: reports.filter(r => r.category === 'finance').length },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Raporlar</h1>
          <p className="text-slate-600 mt-1">İş zekası ve analitik raporlarınız</p>
        </div>
      </div>

      {/* Date Range Filter */}
      <div className="bg-white rounded-lg shadow-sm p-6">
        <div className="flex gap-6 items-end flex-wrap">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Başlangıç Tarihi</label>
            <input
              type="date"
              value={dateRange.start}
              onChange={(e) => setDateRange({ ...dateRange, start: e.target.value })}
              className="px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Bitiş Tarihi</label>
            <input
              type="date"
              value={dateRange.end}
              onChange={(e) => setDateRange({ ...dateRange, end: e.target.value })}
              className="px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
            />
          </div>
          <button className="px-6 py-2 bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition-colors">
            Tarihe Göre Filtrele
          </button>
        </div>
      </div>

      {/* Category Tabs */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex gap-2 flex-wrap">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setSelectedCategory(cat.id)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                selectedCategory === cat.id
                  ? 'bg-cyan-600 text-white'
                  : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
              }`}
            >
              {cat.name} ({cat.count})
            </button>
          ))}
        </div>
      </div>

      {/* Reports Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredReports.map((report) => (
          <div
            key={report.id}
            className="bg-white rounded-lg shadow-sm border border-slate-200 p-6 hover:shadow-md transition-shadow"
          >
            {/* Icon */}
            <div className="flex items-start justify-between mb-4">
              <div className="p-3 bg-cyan-100 rounded-lg">
                <svg className="w-8 h-8 text-cyan-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={report.icon} />
                </svg>
              </div>
              <div className="flex gap-2">
                <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getCategoryColor(report.category)}`}>
                  {getCategoryText(report.category)}
                </span>
              </div>
            </div>

            {/* Content */}
            <h3 className="text-lg font-semibold text-slate-900 mb-2">{report.name}</h3>
            <p className="text-sm text-slate-600 mb-4">{report.description}</p>

            {/* Format */}
            <div className="mb-4">
              <span className={`px-2 py-1 text-xs font-semibold rounded ${getFormatBadge(report.format)}`}>
                {report.format.toUpperCase()}
              </span>
            </div>

            {/* Actions */}
            <div className="flex gap-2">
              <button className="flex-1 px-4 py-2 bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition-colors text-sm font-medium">
                <svg className="w-4 h-4 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                </svg>
                İndir
              </button>
              <button className="px-4 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors text-sm">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                </svg>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Quick Actions */}
      <div className="bg-gradient-to-r from-cyan-600 to-cyan-700 rounded-lg shadow-lg p-6 text-white">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-xl font-bold mb-2">Özel Rapor Talebi</h3>
            <p className="text-cyan-100">İhtiyacınız olan özel bir rapor mu var? Bizimle iletişime geçin.</p>
          </div>
          <button className="px-6 py-3 bg-white text-cyan-700 rounded-lg hover:bg-cyan-50 transition-colors font-semibold">
            Talep Oluştur
          </button>
        </div>
      </div>
    </div>
  );
}
