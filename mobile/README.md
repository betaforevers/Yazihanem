# Yazıhanem Mobil Uygulama

Flutter ile yazılmış çok kiracılı (multi-tenant) içerik yönetim sistemi mobil uygulaması.

## Gereksinimler

- **Flutter SDK**: 3.38.5+ (`C:\flutter`)
- **Dart SDK**: 3.10.4+
- **Android SDK**: 36.0.0 (`C:\Android\Sdk`)
- **JDK**: 17+ (`C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot`)

## Kurulum

```bash
# PATH'e ekle (her terminal oturumunda)
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.18.8-hotspot"
$env:Path = "$env:JAVA_HOME\bin;C:\flutter\bin;" + $env:Path

# Bağımlılıkları yükle
flutter pub get

# Kod üretimi (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Analiz
flutter analyze

# Çalıştır (Chrome)
flutter run -d chrome

# Çalıştır (Android emülatör)
flutter run -d emulator-5554
```

## Mimari

**Clean Architecture + Feature-First** yapı kullanılır.

```
lib/
├── core/       → API client, config, routing, storage, utils
├── features/   → auth, content, media, admin, profile, settings
└── shared/     → theme, widgets
```

Detaylı mimari: [`bedotecture.md`](../bedotecture.md)  
Türkçe anlatım: [`FLUTTER-ARCHITECTURE-GUIDE.md`](../FLUTTER-ARCHITECTURE-GUIDE.md)
