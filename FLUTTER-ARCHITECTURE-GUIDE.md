# 📱 Yazıhanem Flutter Mobil Uygulama — Mimari Anlatım Dokümantasyonu

> Bu döküman, `bedotecture.md` dosyasında tanımlanan Flutter mobil uygulama mimarisini **sade Türkçe** ile adım adım açıklamaktadır. Teknik terimlerin yanına Türkçe karşılıkları da eklenmiştir.

---

## 📖 1. Uygulama Ne Yapıyor?

Yazıhanem mobil uygulaması, bir **içerik yönetim sistemidir (CMS)**. Basitçe düşünürsek, bir **blog yönetim uygulaması** gibi çalışır ama çok daha güçlüdür:

- ✍️ Yazılar (içerikler) oluşturabilirsiniz
- 📸 Fotoğraf, video, PDF gibi dosyalar yükleyebilirsiniz
- 📝 Yazıları taslak olarak kaydedip, daha sonra yayınlayabilirsiniz
- 👥 Admin olarak diğer kullanıcıları yönetebilirsiniz
- 🏢 Her firma (tenant) kendi verilerini izole şekilde görür

Uygulama **Flutter** ile yazılacağından hem **Android** hem **iOS** üzerinde tek bir kod tabanıyla çalışır.

---

## 🏗️ 2. Mimari Nedir ve Neden Önemlidir?

Mimari, uygulamanın **nasıl organize edileceğinin planıdır**. Tıpkı bir binanın mimari çizimi gibi; hangi oda nerede olacak, borular nereden geçecek, elektrik hatları nasıl döşenecek — bunları önceden planlarsınız.

Yazıhanem mobil uygulamasında **Clean Architecture (Temiz Mimari)** kullanıyoruz. Bunun temel fikri şudur:

> Kodunuzu **katmanlara** ayırın ve her katmanın sadece **bir işi** olsun.

### Neden bu kadar önemli?

| Sorun | Mimari Olmadan | Mimari ile |
|-------|---------------|------------|
| Yeni özellik ekleme | Her şey birbirine bağlı, bir yeri değiştirince başka yer bozuluyor | Sadece ilgili katmanı değiştirirsiniz |
| Hata bulma | 2000 satırlık dosyada hata aramak | Her dosya kendi işini yapar, hata lokalize |
| Test yazma | Test yazmak imkansız | Her katman bağımsız test edilebilir |
| Kişi değişikliği | Yeni geliştirici kodu anlamakta zorlanır | Yapı standart, herkes anlayabilir |

---

## 🧅 3. Katmanlar — Soğan Gibi Düşünün

Uygulamamız 4 ana katmandan oluşur. Bir soğanın katmanları gibi düşünün — en dıştan en içe:

```
┌────────────────────────────────────────────┐
│          📱 SUNUM KATMANI                  │
│   (Kullanıcının gördüğü ekranlar)          │
│   Ekranlar, butonlar, formlar              │
└──────────────┬─────────────────────────────┘
               │ "Bu veriyi göster" der
               ▼
┌────────────────────────────────────────────┐
│        🔄 SAĞLAYICI KATMANI (Providers)    │
│   (Veriyi yönetir, ekrana hazırlar)        │
│   "Yükleniyor", "Hata", "Başarılı"        │
└──────────────┬─────────────────────────────┘
               │ "Veriyi getir" der
               ▼
┌────────────────────────────────────────────┐
│          💾 VERİ KATMANI                   │
│   (Veriyi nereden alacağını bilir)         │
│   API'den mi? Yerel cache'den mi?          │
└──────────┬──────────┬──────────────────────┘
           │          │
           ▼          ▼
      🌐 API      📦 Yerel Depo
   (Backend)     (Telefon hafızası)
```

### Her katman ne yapar?

**📱 Sunum Katmanı (Presentation)**
- Kullanıcının gördüğü her şey burada: ekranlar, butonlar, formlar, listeler
- Bu katman **sadece gösterir**, iş mantığı bilmez
- Örnek: "İçerik listesi ekranı", "Giriş formu"

**🔄 Sağlayıcı Katmanı (Providers — Riverpod)**
- Verinin durumunu yönetir: yükleniyor mu? Hata mı var? Veri geldi mi?
- Ekranla veri arasında **köprü** görevi görür
- Örnek: "İçerik listesini getir, yüklenirken spinner göster, hata olursa mesaj göster"

**💾 Veri Katmanı (Data — Repository)**
- Verinin **nereden** geleceğine karar verir
- İnternet varsa API'den çeker, yoksa telefonun hafızasından (cache) okur
- Örnek: "Önce cache'e bak, 5 dakikadan eskiyse API'den yenile"

**🌐 Uzak Kaynak (Remote — API) ve 📦 Yerel Kaynak (Local — Hive)**
- Uzak kaynak: Go backend'e HTTP istekleri gönderir
- Yerel kaynak: Telefonun kendi hafızasında veri saklar (offline kullanım için)

---

## 📂 4. Klasör Yapısı — Her Şeyin Yeri Belli

Dosyalar **özellik bazlı (feature-first)** organize edilir. Yani "auth ile ilgili her şey auth klasöründe" mantığı:

```
lib/
├── core/          → 🔧 Tüm uygulamanın ortak altyapısı
│   ├── api/       → HTTP istemcisi (API'ye bağlanma)
│   ├── config/    → Ayarlar (API adresi, tema renkleri)
│   ├── routing/   → Sayfa geçişleri (hangi URL hangi ekranı açar)
│   └── storage/   → Güvenli depolama (JWT token saklama)
│
├── features/      → 📦 Her özellik kendi klasöründe
│   ├── auth/      → 🔐 Giriş/Çıkış işlemleri
│   ├── content/   → 📝 İçerik yönetimi (yazı yazma, düzenleme)
│   ├── media/     → 📸 Medya yönetimi (fotoğraf/video yükleme)
│   ├── admin/     → 👤 Admin paneli (kullanıcı yönetimi)
│   ├── profile/   → 🧑 Profil ekranı
│   └── settings/  → ⚙️ Ayarlar ekranı
│
└── shared/        → 🎨 Paylaşılan arayüz parçaları
    ├── widgets/   → Ortak butonlar, yükleme göstergeleri
    └── theme/     → Renkler, yazı tipleri, boşluklar
```

### Her feature'ın iç yapısı:

```
features/content/
├── data/                    → 💾 Veri işlemleri
│   ├── content_repository.dart   → Veriyi nereden alacağına karar verir
│   ├── content_remote_source.dart → API'den veri çeker
│   └── content_local_source.dart  → Cache'den veri okur
│
├── domain/                  → 📐 Veri modelleri
│   └── models/
│       └── content_model.dart     → "İçerik nedir?" tanımı
│
├── providers/               → 🔄 Durum yönetimi
│   ├── content_list_provider.dart → İçerik listesi state'i
│   └── content_detail_provider.dart → Tek içerik state'i
│
└── presentation/            → 📱 Ekranlar
    ├── screens/
    │   ├── content_list_screen.dart    → İçerik listesi sayfası
    │   ├── content_detail_screen.dart  → İçerik detay sayfası
    │   └── content_editor_screen.dart  → İçerik yazma/düzenleme
    └── widgets/
        ├── content_card.dart          → Liste kartı
        └── status_badge.dart          → "Taslak" / "Yayında" rozeti
```

---

## 🔄 5. Veri Akışı — Bir Yazı Nasıl Oluşturulur?

Kullanıcı "Yeni Yazı" butonuna bastığında arka planda neler olur:

```
1️⃣ Kullanıcı → "Yeni Yazı" butonuna basar
                     │
2️⃣ ContentEditorScreen → Formu gösterir (başlık, içerik, slug)
                     │
3️⃣ Kullanıcı → Formu doldurup "Kaydet" butonuna basar
                     │
4️⃣ ContentListProvider → createContent() metodunu çağırır
    ├── State → "Yükleniyor..." (loading spinner gösterilir)
    │                │
5️⃣ │  ContentRepository → API'ye gönderilecek mi, cache'e mi yazılacak?
    │                │
    │                ├── 🌐 Online → API'ye POST isteği gönder
    │                │       │
    │                │       ├── ✅ Başarılı → State → "Tamamlandı!"
    │                │       │                 → Listeye geri dön
    │                │       │
    │                │       └── ❌ Hata → State → "Hata: Sunucuya ulaşılamadı"
    │                │                    → Hata mesajı gösterilir
    │                │
    │                └── 📴 Offline → Yerel cache'e kaydet
    │                        → "Bağlantı gelince gönderilecek" mesajı
```

---

## 🔐 6. Kimlik Doğrulama — Güvenlik Nasıl Çalışır?

### JWT Token Nedir?

JWT (JSON Web Token), bir **dijital kimlik kartı** gibidir. Kullanıcı giriş yaptığında backend bu kartı verir, her API isteğinde bu kart gösterilir.

```
Giriş Akışı:

1. Kullanıcı → Email + Şifre girer
2. Uygulama → Backend'e POST /api/v1/auth/login gönderir
3. Backend → Doğruysa JWT token döndürür
4. Uygulama → Token'ı güvenli depoda saklar (Keychain/Keystore)
5. Sonraki her istek → Token otomatik eklenir ("Ben bu kişiyim" der)
```

### Token Yenileme

```
Access Token  → 15 dakika geçerli (kısa ömürlü, güvenlik için)
Refresh Token → 7 gün geçerli (uzun ömürlü, yenileme için)

Akış:
1. API isteği gönderilir
2. Backend "401 - Token süresi dolmuş" der
3. Uygulama otomatik olarak refresh token ile yeni access token ister
4. Yeni token alınır, istek tekrar gönderilir
5. Kullanıcı hiçbir şey fark etmez ✨
```

### Güvenli Saklama

```
✅ DOĞRU: flutter_secure_storage kullanmak
   → iOS'ta Keychain'e, Android'de Keystore'a kaydeder
   → Şifrelenmiş, diğer uygulamalar okuyamaz

❌ YANLIŞ: SharedPreferences kullanmak
   → Düz metin olarak kaydeder
   → Root/jailbreak'li cihazda okunabilir
```

---

## 🏢 7. Multi-Tenant (Çok Kiracılı) Yapı

### Bu ne demek?

Düşünün ki bir **apartman binası** yapıyorsunuz. Her daire (tenant) birbirinden tamamen bağımsız. 3. kattaki kişi 5. katın odasına giremez.

Yazıhanem'de de her firma bir "tenant"tır:

```
Firma A (tenant_acme)     → Kendi yazıları, kullanıcıları, medyaları
Firma B (tenant_widget)   → Kendi yazıları, kullanıcıları, medyaları
                            ↕ Birbirlerinin verilerini GÖREMEZLER
```

### Mobilde nasıl çalışır?

```dart
// Her API isteğine tenant bilgisi eklenir
// Böylece backend hangi firmanın verisini döneceğini bilir

Headers: {
  "Authorization": "Bearer eyJhbGci...",     // Kim olduğun
  "X-Tenant-Domain": "acme.yazihanem.com"    // Hangi firmadan olduğun
}
```

---

## 🧭 8. Ekranlar ve Sayfa Geçişleri

Uygulama **4 ana sekme** ile çalışır (altta navigasyon çubuğu):

```
┌─────────────────────────────────────────┐
│                                         │
│            [Ekran İçeriği]              │
│                                         │
├─────────┬──────────┬──────────┬─────────┤
│ 🏠 Ana  │ 📝 İçerik│ 📸 Medya │ 👤 Profil│
│  Sayfa  │          │          │         │
└─────────┴──────────┴──────────┴─────────┘
```

### Ekran Hiyerarşisi

```
🔓 Giriş Öncesi:
   └── /login → Giriş Ekranı

🔑 Giriş Sonrası:
   ├── /dashboard → Ana Sayfa (istatistikler, son yazılar)
   │
   ├── /content → İçerik Listesi
   │   ├── /content/new → Yeni İçerik Oluştur
   │   ├── /content/123 → İçerik Detayı
   │   └── /content/123/edit → İçerik Düzenle
   │
   ├── /media → Medya Galerisi (fotoğraf/video grid)
   │
   └── /profile → Profil
       ├── /profile/settings → Ayarlar
       ├── /profile/change-password → Şifre Değiştir
       └── /profile/admin → [Sadece Admin]
           ├── Kullanıcı Yönetimi
           └── Denetim Kayıtları (Audit Logs)
```

### Sayfa Koruma (Route Guard)

```
Kullanıcı /content sayfasına gitmek istiyor
    │
    ├── Giriş yapmış mı? → EVET → Sayfayı göster ✅
    │
    └── Giriş yapmamış mı? → HAYIR → /login'e yönlendir 🔒

Kullanıcı /profile/admin sayfasına gitmek istiyor
    │
    ├── Rolü "admin" mi? → EVET → Sayfayı göster ✅
    │
    └── Rolü "editor/viewer" mı? → HAYIR → 403 Yetkisiz 🚫
```

---

## 📴 9. Offline (Çevrimdışı) Çalışma

### Neden önemli?

Kullanıcı metroda, uçakta veya bağlantısı zayıf bir yerde olabilir. Uygulama bu durumlarda da çalışabilmelidir.

### Nasıl çalışır?

```
📦 Hive (Yerel Veritabanı) — telefonda veri saklar

Strateji:
┌──────────────────┬────────────────────────────────────┐
│ Veri Tipi        │ Önbellek Stratejisi                │
├──────────────────┼────────────────────────────────────┤
│ İçerik Listesi   │ Önce cache'e bak, 5 dk eskiyse    │
│                  │ arka planda API'den güncelle        │
├──────────────────┼────────────────────────────────────┤
│ İçerik Detayı    │ Önce cache'e bak, 1 saat TTL      │
├──────────────────┼────────────────────────────────────┤
│ Medya Listesi    │ Her zaman API'den çek              │
│                  │ (medya sık değişir)                 │
├──────────────────┼────────────────────────────────────┤
│ Kullanıcı Profili│ Önce cache'e bak, 24 saat TTL     │
└──────────────────┴────────────────────────────────────┘

Offline'dayken yazı yazma:
1. Kullanıcı çevrimdışıyken yeni yazı oluşturur
2. Yazı telefonun hafızasına kaydedilir (Hive)
3. "Bekleyen İşlemler" kuyruğuna eklenir
4. İnternet geldiğinde SyncManager otomatik gönderir
5. Kullanıcıya "Yazınız yayınlandı" bildirimi gelir
```

---

## 🔄 10. State Management — Riverpod

### State (Durum) nedir?

Ekranda gördüğünüz her şey bir **durum**dur:

- "Yükleniyor..." → **Loading** durumu
- İçerik listesi gösteriliyor → **Loaded** durumu  
- "Bir hata oluştu" → **Error** durumu
- "Henüz içerik yok" → **Empty** durumu

### Riverpod neden seçildi?

| Alternatif | Dezavantaj | Riverpod Avantajı |
|-----------|------------|-------------------|
| **setState** | Sadece tek widget'ta çalışır, paylaşım yok | Global state, her yerden erişim |
| **Provider** | Compile-time güvenlik yok | Derleme zamanında hata yakalar |
| **BLoC** | Çok fazla dosya, boilerplate | Daha az kod, daha okunabilir |
| **Redux** | Aşırı karmaşık, öğrenme eğrisi yüksek | Basit API, hızlı öğrenme |

### Nasıl çalışır? (Basit Örnek)

```
1. Provider tanımla:
   "İçerik listesi provider'ı" → API'den listeleri çeker

2. Ekronda kullan:
   Ekran provider'ı "dinler" (watch)
   → Provider yükleniyor → Ekran spinner gösterir
   → Provider veri döndü → Ekran listeyi gösterir
   → Provider hata döndü → Ekran hata mesajı gösterir

3. Otomatik güncelleme:
   Yeni içerik oluşturulduğunda provider tetiklenir
   → Liste otomatik yenilenir
   → Tüm ekranlar güncellenir
```

---

## 🌐 11. Backend ile İletişim

### API İstemcisi (Dio)

Uygulama backend'e **HTTP istekleri** gönderir. Bunu **Dio** kütüphanesi ile yapar:

```
Uygulama                              Backend (Go + Fiber)
   │                                       │
   │ POST /api/v1/auth/login              │
   │ {"email": "x", "password": "y"}  ──→ │
   │                                       │ Doğrula → Token oluştur
   │ ←── {"token": "eyJ...", "user":{}} ──│
   │                                       │
   │ GET /api/v1/content?page=1           │
   │ Headers: Authorization: Bearer eyJ....│
   │ ──────────────────────────────────→   │
   │                                       │ Token'ı doğrula
   │                                       │ Tenant'ı çöz
   │ ←── {"contents": [...], "page": 1}   │ İçerikleri getir
```

### Interceptor Zinciri (Otomatik İşlemler)

Her API isteği gönderilmeden önce 3 "interceptor" (araya giren) çalışır:

```
İstek Hazırlanıyor
    │
    ▼
🔑 Auth Interceptor → JWT token'ı header'a ekler
    │
    ▼
🏢 Tenant Interceptor → Tenant domain bilgisini ekler
    │
    ▼
📝 Logging Interceptor → İsteği loglar (debug için)
    │
    ▼
🌐 API'ye Gönderilir
    │
    ▼
↩️ Cevap Geldi
    │
    ├── 200 OK → Veriyi dön ✅
    ├── 401 Unauthorized → Token yenile, tekrar dene 🔄
    ├── 429 Too Many Requests → Biraz bekle, tekrar dene ⏳
    └── 500 Server Error → 3 kez tekrar dene, sonra hata göster ❌
```

---

## 📦 12. Kullanılan Kütüphaneler

| Kütüphane | Ne İşe Yarar | Neden Seçildi |
|-----------|-------------|---------------|
| **flutter_riverpod** | Durum yönetimi | Type-safe, test edilebilir |
| **dio** | HTTP istekleri | Interceptor desteği, güçlü |
| **go_router** | Sayfa yönlendirme | Deklaratif, guard desteği |
| **freezed** | Değişmez veri modelleri | Otomatik kod üretimi, güvenli |
| **hive_flutter** | Yerel veritabanı | Hızlı, şema gerektirmez |
| **flutter_secure_storage** | Token saklama | iOS Keychain / Android Keystore |
| **flutter_quill** | Zengin metin editörü | Yazı yazma deneyimi |
| **cached_network_image** | Resim önbelleği | Resimleri cache'ler, hızlı |
| **firebase_messaging** | Push bildirimler | Anlık bildirim desteği |
| **image_picker** | Kamera/galeri erişimi | Medya seçimi |

---

## 🗓️ 13. Geliştirme Planı (Roadmap)

```
Hafta 1  ──→  🔧 Proje Altyapısı (iskelet, tema, Dio, routing)
Hafta 2  ──→  🔐 Kimlik Doğrulama (giriş, çıkış, token yönetimi)
Hafta 3-4 ──→ 📝 İçerik Yönetimi (yazı CRUD, editör, yayınlama)
Hafta 4  ──→  📸 Medya Yönetimi (yükleme, galeri, silme)
Hafta 5  ──→  👤 Admin Paneli (kullanıcı yönetimi, audit log)
Hafta 5-6 ──→ 📴 Offline + Polish (cache, sync, animasyonlar)
Hafta 6-7 ──→ 🚀 Yayınlama (store hazırlık, CI/CD, push)
```

**Toplam tahmin: 22-29 iş günü (~5-7 hafta)**

---

## ⚠️ 14. Altın Kurallar

### ✅ Her zaman yap:

1. **Her model `freezed` ile oluştur** — Otomatik `fromJson`, `copyWith`, immutable
2. **Her API çağrısını try-catch ile sar** — Hata durumunda uygulama çökmesin
3. **Her ekranda 4 durum göster** — Yükleniyor, Veri Var, Hata, Boş
4. **Formlarda validasyon yap** — Email geçerli mi? Şifre en az 8 karakter mi?
5. **Riverpod provider kullan** — setState() yerine her zaman Riverpod

### ❌ Asla yapma:

1. **Token'ı SharedPreferences'a kaydetme** — Güvenli değil
2. **API adresini koda gömme** — AppConfig ile yönet
3. **Widget içinde doğrudan API çağırma** — Repository pattern kullan
4. **`print()` ile debug yapma** — Logger sınıfı kullan
5. **Hata durumlarını görmezden gelme** — Her hata kullanıcıya gösterilmeli

---

## 🔑 Özet

```
Yazıhanem Mobil = Flutter + Clean Architecture + Riverpod

Yapı:     Feature-first (her özellik kendi klasöründe)
Veri:     Backend API (Dio) + Offline Cache (Hive)
Güvenlik: JWT + Secure Storage + Tenant izolasyonu
Ekranlar: 4 ana tab (Dashboard, İçerik, Medya, Profil)
Hedef:    Android 7.0+ ve iOS 13+
Süre:     ~5-7 hafta
```

> 💡 **Bu döküman `bedotecture.md` dosyasının Türkçe açıklamasıdır.** Teknik detaylar ve kod örnekleri için `bedotecture.md` dosyasına bakınız.
