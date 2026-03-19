import 'package:dio/dio.dart';

import '../domain/models/cari_model.dart';

/// Netsis REST API entegrasyon servisi.
///
/// Dev modda mock yanıt döner; prod modda gerçek Netsis NSService API'ye bağlanır.
/// Netsis REST API endpoint yapısı:
///   POST {baseUrl}/api/Cari          – yeni cari oluştur
///   POST {baseUrl}/api/token         – auth token al
class NetsisService {
  final bool useMock;
  final NetsisConfig? config;

  const NetsisService({this.useMock = true, this.config});

  /// Netsis'e yeni cari gönderir.
  Future<NetsisResult> createCari(CariModel cari) async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 900));
      return NetsisResult(
        success: true,
        netsisKod: cari.kod,
        message: "Netsis'e başarıyla aktarıldı. Cari Kodu: ${cari.kod}",
      );
    }

    if (config == null) {
      return const NetsisResult(
        success: false,
        message: 'Netsis bağlantı ayarları yapılandırılmamış. '
            'Lütfen yöneticinizle iletişime geçin.',
      );
    }

    try {
      final dio = Dio()
        ..options.connectTimeout = const Duration(seconds: 10)
        ..options.receiveTimeout = const Duration(seconds: 30);

      final token = await _getToken(dio);

      final response = await dio.post(
        '${config!.baseUrl}/api/Cari',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
        data: _buildPayload(cari),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return NetsisResult(
          success: true,
          netsisKod: cari.kod,
          message: "Netsis'e başarıyla aktarıldı. Cari Kodu: ${cari.kod}",
        );
      }
      return NetsisResult(
        success: false,
        message: 'Netsis hatası (HTTP ${response.statusCode})',
      );
    } on DioException catch (e) {
      return NetsisResult(
        success: false,
        message: 'Netsis bağlantı hatası: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      return NetsisResult(success: false, message: 'Hata: $e');
    }
  }

  // ── Private ────────────────────────────────────────────────────

  Future<String> _getToken(Dio dio) async {
    final response = await dio.post(
      '${config!.baseUrl}/api/token',
      data: {
        'username': config!.username,
        'password': config!.password,
        'grant_type': 'password',
      },
    );
    final data = response.data as Map<String, dynamic>;
    return data['access_token'] as String;
  }

  Map<String, dynamic> _buildPayload(CariModel cari) => {
        'CariKodu': cari.kod,
        'CariUnvani': cari.unvan,
        'VergiNo': cari.vergiNo,
        'VergiDairesi': cari.vergiDairesi,
        'Telefon': cari.telefon ?? '',
        'Adres': cari.adres ?? '',
        'EFaturaKullanici': cari.eFaturaMukellef ? 'E' : 'H',
        'Aktif': cari.isActive ? 'E' : 'H',
      };
}

// ── Config & Result ────────────────────────────────────────────────────────

class NetsisConfig {
  final String baseUrl;
  final String username;
  final String password;

  const NetsisConfig({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  /// Örnek: NetsisConfig.fromEnv()
  ///   baseUrl  → http://192.168.1.100:8080/NSServiceApi
  ///   username → admin
  ///   password → secret
}

class NetsisResult {
  final bool success;
  final String? netsisKod;
  final String message;

  const NetsisResult({
    required this.success,
    this.netsisKod,
    required this.message,
  });
}
