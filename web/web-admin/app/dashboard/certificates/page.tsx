'use client';

import { useState, useEffect } from 'react';

interface Certificate {
  id: string;
  certificate_type: string;
  certificate_number: string;
  standard: string;
  issue_date: string;
  expiry_date: string;
  status: 'active' | 'expiring_soon' | 'expired' | 'pending_renewal';
  issuer: string;
  scope: string;
}

export default function CertificatesPage() {
  const [certificates, setCertificates] = useState<Certificate[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState<string>('all');

  useEffect(() => {
    // Mock data - backend entegrasyonu için hazır
    const mockCertificates: Certificate[] = [
      {
        id: '1',
        certificate_type: 'ISO 22000',
        certificate_number: 'ISO-22000-2024-001',
        standard: 'Gıda Güvenliği Yönetim Sistemi',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 180).toISOString(),
        expiry_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 185).toISOString(),
        status: 'active',
        issuer: 'TÜV SÜD Türkiye',
        scope: 'Taze ve donmuş balık üretimi, işleme ve dağıtım',
      },
      {
        id: '2',
        certificate_type: 'ISO 9001',
        certificate_number: 'ISO-9001-2024-002',
        standard: 'Kalite Yönetim Sistemi',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 200).toISOString(),
        expiry_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 165).toISOString(),
        status: 'active',
        issuer: 'Bureau Veritas',
        scope: 'Su ürünleri işleme ve ihracat hizmetleri',
      },
      {
        id: '3',
        certificate_type: 'BRC',
        certificate_number: 'BRC-GS-2024-003',
        standard: 'British Retail Consortium Global Standard',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 300).toISOString(),
        expiry_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 45).toISOString(),
        status: 'expiring_soon',
        issuer: 'SGS Türkiye',
        scope: 'Gıda güvenliği ve kalite yönetimi',
      },
      {
        id: '4',
        certificate_type: 'ASC',
        certificate_number: 'ASC-2024-004',
        standard: 'Aquaculture Stewardship Council',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 100).toISOString(),
        expiry_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 265).toISOString(),
        status: 'active',
        issuer: 'Control Union',
        scope: 'Sürdürülebilir yetiştiricilik sertifikasyonu',
      },
      {
        id: '5',
        certificate_type: 'HACCP',
        certificate_number: 'HACCP-2024-005',
        standard: 'Hazard Analysis Critical Control Points',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 400).toISOString(),
        expiry_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 5).toISOString(),
        status: 'expired',
        issuer: 'TÜV NORD Türkiye',
        scope: 'Gıda güvenliği kritik kontrol noktaları',
      },
      {
        id: '6',
        certificate_type: 'MSC',
        certificate_number: 'MSC-2024-006',
        standard: 'Marine Stewardship Council',
        issue_date: new Date(Date.now() - 1000 * 60 * 60 * 24 * 50).toISOString(),
        expiry_date: new Date(Date.now() + 1000 * 60 * 60 * 24 * 315).toISOString(),
        status: 'pending_renewal',
        issuer: 'DNV GL',
        scope: 'Sürdürülebilir deniz ürünleri sertifikasyonu',
      },
    ];

    setTimeout(() => {
      setCertificates(mockCertificates);
      setLoading(false);
    }, 500);
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'expiring_soon':
        return 'bg-yellow-100 text-yellow-800';
      case 'expired':
        return 'bg-red-100 text-red-800';
      case 'pending_renewal':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusText = (status: string) => {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'expiring_soon':
        return 'Yakında Sona Erecek';
      case 'expired':
        return 'Süresi Doldu';
      case 'pending_renewal':
        return 'Yenileme Bekliyor';
      default:
        return status;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'active':
        return (
          <svg className="w-6 h-6 text-green-600" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
          </svg>
        );
      case 'expiring_soon':
        return (
          <svg className="w-6 h-6 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        );
      case 'expired':
        return (
          <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        );
      case 'pending_renewal':
        return (
          <svg className="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
        );
      default:
        return null;
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('tr-TR', {
      day: '2-digit',
      month: 'long',
      year: 'numeric',
    });
  };

  const getDaysUntilExpiry = (expiryDate: string) => {
    const today = new Date();
    const expiry = new Date(expiryDate);
    const diffTime = expiry.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  };

  const filteredCertificates = filterStatus === 'all'
    ? certificates
    : certificates.filter(cert => cert.status === filterStatus);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Sertifikalar</h1>
          <p className="text-slate-600 mt-1">Tüm kalite ve uyumluluk sertifikalarınız</p>
        </div>
        <button className="px-4 py-2 bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition-colors">
          + Yeni Sertifika Ekle
        </button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-green-100 rounded-lg">
              {getStatusIcon('active')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Aktif</p>
              <p className="text-2xl font-bold text-slate-900">{certificates.filter(c => c.status === 'active').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-yellow-100 rounded-lg">
              {getStatusIcon('expiring_soon')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Yakında Sona Erecek</p>
              <p className="text-2xl font-bold text-slate-900">{certificates.filter(c => c.status === 'expiring_soon').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-red-100 rounded-lg">
              {getStatusIcon('expired')}
            </div>
            <div>
              <p className="text-sm text-slate-600">Süresi Doldu</p>
              <p className="text-2xl font-bold text-slate-900">{certificates.filter(c => c.status === 'expired').length}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="flex items-center gap-4">
            <div className="p-3 bg-cyan-100 rounded-lg">
              <svg className="w-6 h-6 text-cyan-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
              </svg>
            </div>
            <div>
              <p className="text-sm text-slate-600">Toplam</p>
              <p className="text-2xl font-bold text-slate-900">{certificates.length}</p>
            </div>
          </div>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow-sm p-4">
        <div className="flex gap-4 items-center">
          <label className="text-sm font-medium text-slate-700">Durum:</label>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="px-4 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-600"
          >
            <option value="all">Tümü</option>
            <option value="active">Aktif</option>
            <option value="expiring_soon">Yakında Sona Erecek</option>
            <option value="expired">Süresi Doldu</option>
            <option value="pending_renewal">Yenileme Bekliyor</option>
          </select>
        </div>
      </div>

      {/* Certificates Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {loading ? (
          <div className="col-span-2 text-center py-12 text-slate-500">Yükleniyor...</div>
        ) : filteredCertificates.length === 0 ? (
          <div className="col-span-2 text-center py-12 text-slate-500">Sertifika bulunamadı</div>
        ) : (
          filteredCertificates.map((cert) => (
            <div key={cert.id} className="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden hover:shadow-md transition-shadow">
              {/* Certificate Header */}
              <div className="bg-gradient-to-r from-cyan-600 to-cyan-700 p-6 text-white">
                <div className="flex items-start justify-between">
                  <div>
                    <h3 className="text-2xl font-bold">{cert.certificate_type}</h3>
                    <p className="text-cyan-100 mt-1">{cert.standard}</p>
                  </div>
                  <div className="p-2 bg-white/20 rounded-lg">
                    <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                    </svg>
                  </div>
                </div>
                <div className="mt-4 font-mono text-sm bg-white/20 px-3 py-2 rounded inline-block">
                  {cert.certificate_number}
                </div>
              </div>

              {/* Certificate Details */}
              <div className="p-6 space-y-4">
                <div>
                  <p className="text-xs text-slate-500 uppercase tracking-wider">Kapsam</p>
                  <p className="text-sm text-slate-900 mt-1">{cert.scope}</p>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wider">Düzenleyen</p>
                    <p className="text-sm text-slate-900 mt-1">{cert.issuer}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wider">Durum</p>
                    <span className={`inline-block mt-1 px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(cert.status)}`}>
                      {getStatusText(cert.status)}
                    </span>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wider">Düzenlenme Tarihi</p>
                    <p className="text-sm text-slate-900 mt-1">{formatDate(cert.issue_date)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 uppercase tracking-wider">Son Geçerlilik</p>
                    <p className={`text-sm mt-1 font-medium ${cert.status === 'expired' ? 'text-red-600' : cert.status === 'expiring_soon' ? 'text-yellow-600' : 'text-slate-900'}`}>
                      {formatDate(cert.expiry_date)}
                    </p>
                  </div>
                </div>

                {cert.status !== 'expired' && (
                  <div className="pt-2 border-t border-slate-100">
                    <p className="text-xs text-slate-500">
                      {getDaysUntilExpiry(cert.expiry_date) > 0
                        ? `${getDaysUntilExpiry(cert.expiry_date)} gün kaldı`
                        : 'Bugün sona eriyor'}
                    </p>
                  </div>
                )}

                {/* Actions */}
                <div className="flex gap-2 pt-4 border-t border-slate-100">
                  <button className="flex-1 px-4 py-2 text-sm bg-cyan-600 text-white rounded-lg hover:bg-cyan-700 transition-colors">
                    Görüntüle
                  </button>
                  <button className="px-4 py-2 text-sm border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}
