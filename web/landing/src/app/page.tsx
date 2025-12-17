'use client';

import { useState } from 'react';

export default function Home() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    company: '',
    phone: '',
    message: '',
  });
  const [formStatus, setFormStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [formMessage, setFormMessage] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormStatus('loading');
    setFormMessage('');

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (response.ok) {
        setFormStatus('success');
        setFormMessage(data.message || 'Mesajınız başarıyla gönderildi!');
        setFormData({ name: '', email: '', company: '', phone: '', message: '' });
      } else {
        setFormStatus('error');
        setFormMessage(data.error || 'Bir hata oluştu. Lütfen tekrar deneyin.');
      }
    } catch (error) {
      setFormStatus('error');
      setFormMessage('Bir hata oluştu. Lütfen daha sonra tekrar deneyin.');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };
  return (
    <div className="min-h-screen bg-white">
      {/* Navigation */}
      <nav className="border-b border-slate-200 bg-white sticky top-0 z-50 shadow-sm">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <svg className="w-8 h-8 text-cyan-600" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2C9.243 2 7 4.243 7 7v1H6c-1.103 0-2 .897-2 2v10c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2V10c0-1.103-.897-2-2-2h-1V7c0-2.757-2.243-5-5-5zm6 18H6V10h12v10zm-9-13c0-1.654 1.346-3 3-3s3 1.346 3 3v1H9V7z"/>
                <path d="M12 14c-1.103 0-2 .897-2 2s.897 2 2 2 2-.897 2-2-.897-2-2-2z"/>
              </svg>
              <span className="text-2xl font-bold text-slate-900">Yazıhanem</span>
            </div>
            <div className="hidden md:flex gap-8">
              <a href="#features" className="text-slate-700 hover:text-blue-700 transition-colors font-medium">Özellikler</a>
              <a href="#pricing" className="text-slate-700 hover:text-blue-700 transition-colors font-medium">Fiyatlandırma</a>
              <a href="#contact" className="text-slate-700 hover:text-blue-700 transition-colors font-medium">İletişim</a>
            </div>
            <div className="flex gap-4">
              <button className="px-6 py-2 text-blue-700 hover:text-blue-900 transition-colors font-medium">Giriş Yap</button>
              <button className="px-6 py-2 bg-blue-700 text-white rounded-md hover:bg-blue-800 transition-colors font-medium shadow-sm">Demo Talep Et</button>
            </div>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="bg-gradient-to-br from-cyan-900 via-teal-800 to-cyan-700 text-white py-20 lg:py-28 relative overflow-hidden">
        {/* Ocean wave pattern overlay */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute bottom-0 left-0 right-0 h-32">
            <svg className="w-full h-full" viewBox="0 0 1440 320" fill="currentColor">
              <path d="M0,96L48,112C96,128,192,160,288,165.3C384,171,480,149,576,133.3C672,117,768,107,864,122.7C960,139,1056,181,1152,181.3C1248,181,1344,139,1392,117.3L1440,96L1440,320L1392,320C1344,320,1248,320,1152,320C1056,320,960,320,864,320C768,320,672,320,576,320C480,320,384,320,288,320C192,320,96,320,48,320L0,320Z"></path>
            </svg>
          </div>
        </div>

        <div className="container mx-auto px-6 relative z-10">
          <div className="max-w-4xl mx-auto text-center">
            {/* Trust Badge */}
            <div className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-sm px-4 py-2 rounded-full mb-6 border border-white/20">
              <svg className="w-5 h-5 text-emerald-400" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd"/>
              </svg>
              <span className="text-sm font-medium text-white">ISO 22000 Uyumlu • Soğuk Zincir Sertifikalı • 7/24 Destek</span>
            </div>

            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold mb-6 leading-tight">
              Balıkçılık Sektörünün <br/>
              <span className="text-cyan-300">Dijital Dönüşüm Platformu</span>
            </h1>
            <p className="text-lg md:text-xl mb-8 text-cyan-100 leading-relaxed max-w-3xl mx-auto">
              Balık ihracatçıları ve su ürünleri işletmeleri için özel geliştirilmiş bulut tabanlı yönetim sistemi.
              Stok takibi, soğuk zincir kontrolü, nakliye yönetimi ve detaylı raporlama tek platformda.
            </p>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-8 max-w-2xl mx-auto mb-10">
              <div>
                <div className="text-3xl font-bold text-white">50+</div>
                <div className="text-sm text-cyan-200">İhracatçı Firma</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-white">10M+ kg</div>
                <div className="text-sm text-cyan-200">Yıllık Ürün Takibi</div>
              </div>
              <div>
                <div className="text-3xl font-bold text-white">%99.8</div>
                <div className="text-sm text-cyan-200">Soğuk Zincir Başarı</div>
              </div>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
              <button className="px-8 py-4 bg-white text-cyan-900 font-semibold rounded-lg hover:bg-cyan-50 transition-colors shadow-lg">
                Ücretsiz Demo Talep Edin
              </button>
              <button className="px-8 py-4 border-2 border-white text-white font-semibold rounded-lg hover:bg-white/10 transition-colors">
                Referanslarımızı Görün
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Customer Logos */}
      <section className="py-16 bg-white border-b border-cyan-100">
        <div className="container mx-auto px-6">
          <p className="text-center text-sm font-medium text-slate-600 mb-8 uppercase tracking-wider">
            Türkiye'nin öncü balık ihracatçıları Yazıhanem ile çalışıyor
          </p>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 items-center opacity-60">
            {/* Placeholder for fishing company logos */}
            <div className="flex items-center justify-center h-16 bg-cyan-50 rounded-lg border border-cyan-100">
              <span className="text-cyan-600 font-semibold text-sm">Deniz Ürünleri A.Ş.</span>
            </div>
            <div className="flex items-center justify-center h-16 bg-cyan-50 rounded-lg border border-cyan-100">
              <span className="text-cyan-600 font-semibold text-sm">Akuatik Ltd.</span>
            </div>
            <div className="flex items-center justify-center h-16 bg-cyan-50 rounded-lg border border-cyan-100">
              <span className="text-cyan-600 font-semibold text-sm">Ocean Export</span>
            </div>
            <div className="flex items-center justify-center h-16 bg-cyan-50 rounded-lg border border-cyan-100">
              <span className="text-cyan-600 font-semibold text-sm">SeaFood Co.</span>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 bg-cyan-50/30">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-foreground mb-4">Balıkçılık Sektörüne Özel Çözümler</h2>
            <p className="text-xl text-muted max-w-2xl mx-auto">
              İhracat süreçlerinizi baştan sona dijitalleştirin, tam kontrol sağlayın
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">Stok Takibi & Envanter</h3>
              <p className="text-muted leading-relaxed">
                Tüm ürünlerinizi gerçek zamanlı takip edin. Balık türü, boy, kilo, paketleme durumu ve raf ömrü bilgilerini yönetin.
              </p>
            </div>

            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">Soğuk Zincir Kontrolü</h3>
              <p className="text-muted leading-relaxed">
                Sıcaklık sensörlerinden otomatik veri alın. ISO 22000 standartlarına uygun sıcaklık kayıtları tutun, alarm sistemi ile uyarı alın.
              </p>
            </div>

            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">İhracat Dokümantasyonu</h3>
              <p className="text-muted leading-relaxed">
                Sağlık sertifikaları, gümrük evrakları, faturalar ve sevkiyat belgelerini otomatik oluşturun. Dijital arşivleme ile her an erişilebilir.
              </p>
            </div>

            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">Nakliye & Lojistik Takibi</h3>
              <p className="text-muted leading-relaxed">
                Sevkiyat rotalarını planlayın, araç takibi yapın. Teslimat zamanı, mesafe ve maliyet optimizasyonu sağlayın.
              </p>
            </div>

            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">Kalite & Sertifika Yönetimi</h3>
              <p className="text-muted leading-relaxed">
                MSC, ASC, IFS, BRC sertifikalarınızı dijital ortamda yönetin. Kalite kontrol formları ve laboratuvar test sonuçlarını kaydedin.
              </p>
            </div>

            <div className="bg-white p-8 rounded-xl border border-cyan-200 hover:shadow-xl transition-shadow">
              <div className="w-12 h-12 bg-cyan-100 rounded-lg flex items-center justify-center mb-6">
                <svg className="w-6 h-6 text-cyan-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-foreground mb-3">Canlı Raporlama & Analitik</h3>
              <p className="text-muted leading-relaxed">
                Satış trendleri, karlılık analizleri, ihracat istatistikleri ve stok devir hızı raporları ile stratejik kararlar alın.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-white">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-foreground mb-4">Müşterilerimiz Ne Diyor?</h2>
            <p className="text-xl text-muted">Yazıhanem ile işlerini nasıl büyüttüklerini öğrenin</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <div className="bg-slate-50 p-8 rounded-xl border border-slate-200">
              <div className="flex items-center gap-1 mb-4">
                {[...Array(5)].map((_, i) => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                  </svg>
                ))}
              </div>
              <p className="text-slate-700 mb-6 leading-relaxed">
                "Soğuk zincir takibi ve sıcaklık kayıtlarını otomatik yönetmek ihracat süreçlerimizi %75 hızlandırdı. ISO 22000 denetimlerinde büyük kolaylık sağladı."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-cyan-100 rounded-full flex items-center justify-center">
                  <span className="text-cyan-700 font-bold text-lg">MY</span>
                </div>
                <div>
                  <div className="font-semibold text-slate-900">Mehmet Yıldız</div>
                  <div className="text-sm text-slate-600">Genel Müdür, Deniz Ürünleri A.Ş.</div>
                </div>
              </div>
            </div>

            <div className="bg-slate-50 p-8 rounded-xl border border-slate-200">
              <div className="flex items-center gap-1 mb-4">
                {[...Array(5)].map((_, i) => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                  </svg>
                ))}
              </div>
              <p className="text-slate-700 mb-6 leading-relaxed">
                "İhracat dokümantasyonunu otomatik oluşturmak gümrük işlemlerimizi çok kolaylaştırdı. MSC ve ASC sertifikalarımızı dijital ortamda yönetmek harika."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-cyan-100 rounded-full flex items-center justify-center">
                  <span className="text-cyan-700 font-bold text-lg">AK</span>
                </div>
                <div>
                  <div className="font-semibold text-slate-900">Ayşe Kara</div>
                  <div className="text-sm text-slate-600">İhracat Müdürü, Akuatik Export Ltd.</div>
                </div>
              </div>
            </div>

            <div className="bg-slate-50 p-8 rounded-xl border border-slate-200">
              <div className="flex items-center gap-1 mb-4">
                {[...Array(5)].map((_, i) => (
                  <svg key={i} className="w-5 h-5 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                  </svg>
                ))}
              </div>
              <p className="text-slate-700 mb-6 leading-relaxed">
                "Stok takibi ve nakliye yönetimi sayesinde 500+ ton/ay ürün hareketini hatasız yönetiyoruz. Canlı raporlama özellikleri stratejik kararlarımızı güçlendirdi."
              </p>
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 bg-cyan-100 rounded-full flex items-center justify-center">
                  <span className="text-cyan-700 font-bold text-lg">CÖ</span>
                </div>
                <div>
                  <div className="font-semibold text-slate-900">Can Öztürk</div>
                  <div className="text-sm text-slate-600">Operasyon Direktörü, Ocean Seafood A.Ş.</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section id="pricing" className="py-20 bg-slate-50">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-foreground mb-4">İşinize Uygun Plan Seçin</h2>
            <p className="text-xl text-muted">Şeffaf fiyatlandırma, gizli maliyet yok</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <div className="border border-border rounded-xl p-8 hover:shadow-lg transition-shadow">
              <h3 className="text-2xl font-bold text-foreground mb-2">Başlangıç</h3>
              <p className="text-muted mb-6">Küçük işletmeler için</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-foreground">₺2.999</span>
                <span className="text-muted">/ay</span>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">5 kullanıcı, 100 ton/ay kapasite</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Temel stok takibi</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Soğuk zincir kayıtları</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Email destek</span>
                </li>
              </ul>
              <button className="w-full py-3 border border-primary text-primary rounded-lg hover:bg-primary/5 transition-colors">
                Başla
              </button>
            </div>

            <div className="border-2 border-primary rounded-xl p-8 relative shadow-xl">
              <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-primary text-white px-4 py-1 rounded-full text-sm font-semibold">
                Popüler
              </div>
              <h3 className="text-2xl font-bold text-foreground mb-2">Profesyonel</h3>
              <p className="text-muted mb-6">İhracatçı firmalar için</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-primary">₺6.999</span>
                <span className="text-muted">/ay</span>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">20 kullanıcı, 500 ton/ay kapasite</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">İhracat dokümantasyon otomasyonu</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Sertifika yönetimi (MSC, ASC, IFS)</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Nakliye & lojistik takibi</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Öncelikli destek & API erişimi</span>
                </li>
              </ul>
              <button className="w-full py-3 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors">
                Başla
              </button>
            </div>

            <div className="border border-border rounded-xl p-8 hover:shadow-lg transition-shadow">
              <h3 className="text-2xl font-bold text-foreground mb-2">Kurumsal</h3>
              <p className="text-muted mb-6">Büyük ihracat grupları için</p>
              <div className="mb-6">
                <span className="text-4xl font-bold text-foreground">Özel</span>
              </div>
              <ul className="space-y-3 mb-8">
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Sınırsız kullanıcı & kapasite</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Çoklu tesis yönetimi</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Özel IoT sensör entegrasyonu</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">7/24 destek & SLA garantisi</span>
                </li>
                <li className="flex items-start gap-2">
                  <svg className="w-5 h-5 text-success mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-foreground">Özel raporlama & BI entegrasyonu</span>
                </li>
              </ul>
              <button className="w-full py-3 border border-primary text-primary rounded-lg hover:bg-primary/5 transition-colors">
                İletişime Geçin
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* Contact/Demo Section */}
      <section id="contact" className="py-20 bg-background-gray">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto bg-white rounded-2xl shadow-xl p-8 md:p-12">
            <div className="text-center mb-10">
              <h2 className="text-4xl font-bold text-foreground mb-4">Hemen Başlayın</h2>
              <p className="text-xl text-muted">
                Ücretsiz demo için formu doldurun, ekibimiz en kısa sürede sizinle iletişime geçsin
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-6">
              {formStatus === 'success' && (
                <div className="p-4 bg-green-50 border border-green-200 rounded-lg text-green-800">
                  {formMessage}
                </div>
              )}
              {formStatus === 'error' && (
                <div className="p-4 bg-red-50 border border-red-200 rounded-lg text-red-800">
                  {formMessage}
                </div>
              )}

              <div className="grid md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">Ad Soyad *</label>
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    className="w-full px-4 py-3 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="Adınız ve soyadınız"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">E-posta *</label>
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    required
                    className="w-full px-4 py-3 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="ornek@sirket.com"
                  />
                </div>
              </div>

              <div className="grid md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">Şirket</label>
                  <input
                    type="text"
                    name="company"
                    value={formData.company}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="Şirket adınız"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-foreground mb-2">Telefon</label>
                  <input
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    className="w-full px-4 py-3 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent"
                    placeholder="+90 5XX XXX XX XX"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-foreground mb-2">Mesajınız *</label>
                <textarea
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  required
                  rows={4}
                  className="w-full px-4 py-3 border border-border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent resize-none"
                  placeholder="Projeniz hakkında bize bilgi verin..."
                ></textarea>
              </div>

              <button
                type="submit"
                disabled={formStatus === 'loading'}
                className="w-full py-4 bg-primary text-white font-semibold rounded-lg hover:bg-primary-dark transition-colors shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {formStatus === 'loading' ? 'Gönderiliyor...' : 'Demo Talep Et'}
              </button>
            </form>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-50 text-slate-900 py-12 border-t border-slate-200">
        <div className="container mx-auto px-6">
          <div className="grid md:grid-cols-4 gap-8 mb-8">
            <div>
              <h3 className="text-xl font-bold mb-4 text-slate-900">Yazıhanem</h3>
              <p className="text-slate-600">
                Balıkçılık sektörünün dijital dönüşüm platformu. Su ürünleri işletmeleri için özel geliştirilmiş yönetim sistemi.
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-slate-900">Ürün</h4>
              <ul className="space-y-2 text-slate-600">
                <li><a href="#features" className="hover:text-slate-900 transition-colors">Özellikler</a></li>
                <li><a href="#pricing" className="hover:text-slate-900 transition-colors">Fiyatlandırma</a></li>
                <li><a href="#" className="hover:text-slate-900 transition-colors">Güvenlik</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-slate-900">Şirket</h4>
              <ul className="space-y-2 text-slate-600">
                <li><a href="#" className="hover:text-slate-900 transition-colors">Hakkımızda</a></li>
                <li><a href="#" className="hover:text-slate-900 transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-slate-900 transition-colors">Kariyer</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4 text-slate-900">Destek</h4>
              <ul className="space-y-2 text-slate-600">
                <li><a href="#" className="hover:text-slate-900 transition-colors">Dokümantasyon</a></li>
                <li><a href="#contact" className="hover:text-slate-900 transition-colors">İletişim</a></li>
                <li><a href="#" className="hover:text-slate-900 transition-colors">SSS</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-slate-200 pt-8 text-center text-slate-600">
            <p>&copy; 2025 Yazıhanem. Tüm hakları saklıdır.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
