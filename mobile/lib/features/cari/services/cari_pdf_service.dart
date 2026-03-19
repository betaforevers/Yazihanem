import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/cari_model.dart';

/// Cari bilgi kartı PDF'i oluşturur.
///
/// Netsis'e aktarılan carinin resmi kayıt kartı formatında
/// yazdırılabilir / paylaşılabilir A4 belgesi üretir.
class CariPdfService {
  static const _saticiUnvan = 'Yazıhanem Balık Hali ve Komisyonculuk A.Ş.';
  static const _saticiAdres = 'Trabzon Balık Hali, Sahil Cad. No:1, 61000 Trabzon';
  static const _saticiTel = '0462 000 00 00';

  static Future<List<int>> generate(CariModel cari) async {
    final doc = pw.Document();
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    final tarih = _fmt(cari.createdAt);
    final guncelleme = _fmt(cari.updatedAt);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ═══════════════════════════════════
            // BAŞLIK
            // ═══════════════════════════════════
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F172A'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_saticiUnvan,
                          style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 11,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 3),
                      pw.Text(_saticiAdres,
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 8,
                              color: PdfColor.fromHex('#94A3B8'))),
                      pw.Text('Tel: $_saticiTel',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 8,
                              color: PdfColor.fromHex('#94A3B8'))),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#0D9488'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('CARİ BİLGİ KARTI',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 11,
                                color: PdfColors.white,
                                letterSpacing: 0.8)),
                        pw.SizedBox(height: 2),
                        pw.Text('Netsis Kayıt Belgesi',
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 8,
                                color: PdfColor.fromHex('#CCFBF1'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ═══════════════════════════════════
            // CARİ KOD / TARİH BANDI
            // ═══════════════════════════════════
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E2E8F0'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _label('CARİ KODU', cari.kod, ttf, ttfBold),
                  _label('KAYIT TARİHİ', tarih, ttf, ttfBold),
                  _label('SON GÜNCELLEME', guncelleme, ttf, ttfBold),
                  _label(
                    'DURUM',
                    cari.isActive ? 'AKTİF' : 'PASİF',
                    ttf,
                    ttfBold,
                    valueColor: cari.isActive
                        ? PdfColor.fromHex('#059669')
                        : PdfColor.fromHex('#DC2626'),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ═══════════════════════════════════
            // FİRMA / KİŞİ BİLGİLERİ
            // ═══════════════════════════════════
            _sectionTitle('FİRMA / KİŞİ BİLGİLERİ', ttfBold),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  _infoRow('Ünvan', cari.unvan, ttf, ttfBold,
                      valueSize: 13),
                  pw.Divider(
                      color: PdfColor.fromHex('#F1F5F9'), thickness: 0.5),
                  _infoRow('Vergi / TC No', cari.vergiNo, ttf, ttfBold),
                  pw.Divider(
                      color: PdfColor.fromHex('#F1F5F9'), thickness: 0.5),
                  _infoRow(
                      'Vergi Dairesi', cari.vergiDairesi, ttf, ttfBold),
                  if (cari.telefon != null) ...[
                    pw.Divider(
                        color: PdfColor.fromHex('#F1F5F9'), thickness: 0.5),
                    _infoRow('Telefon', cari.telefon!, ttf, ttfBold),
                  ],
                  if (cari.adres != null) ...[
                    pw.Divider(
                        color: PdfColor.fromHex('#F1F5F9'), thickness: 0.5),
                    _infoRow('Adres', cari.adres!, ttf, ttfBold),
                  ],
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ═══════════════════════════════════
            // FATURA & NETSİS BİLGİLERİ
            // ═══════════════════════════════════
            _sectionTitle('FATURA & NETSİS BİLGİLERİ', ttfBold),
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('e-Fatura Mükellefi',
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 8,
                                color: PdfColor.fromHex('#64748B'))),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: cari.eFaturaMukellef
                                ? PdfColor.fromHex('#DCFCE7')
                                : PdfColor.fromHex('#F1F5F9'),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text(
                            cari.eFaturaMukellef ? 'EVET (GİB Kayıtlı)' : 'HAYIR',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 10,
                                color: cari.eFaturaMukellef
                                    ? PdfColor.fromHex('#059669')
                                    : PdfColor.fromHex('#475569')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Netsis Cari Kodu',
                            style: pw.TextStyle(
                                font: ttf,
                                fontSize: 8,
                                color: PdfColor.fromHex('#64748B'))),
                        pw.SizedBox(height: 3),
                        pw.Text(cari.kod,
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 13,
                                color: PdfColor.fromHex('#0F172A'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // ═══════════════════════════════════
            // FOOTER
            // ═══════════════════════════════════
            pw.Divider(
                color: PdfColor.fromHex('#CBD5E1'), thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bu belge Yazıhanem sistemi tarafından otomatik oluşturulmuştur.',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 7,
                      color: PdfColor.fromHex('#94A3B8')),
                ),
                pw.Text(
                  'Yazdırma: ${_fmt(DateTime.now())}',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 7,
                      color: PdfColor.fromHex('#94A3B8')),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─── Yardımcılar ──────────────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static pw.Widget _sectionTitle(String text, pw.Font font) =>
      pw.Text(text,
          style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColor.fromHex('#64748B'),
              letterSpacing: 0.6));

  static pw.Widget _label(
      String label, String value, pw.Font ttf, pw.Font ttfBold,
      {PdfColor? valueColor}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                font: ttf,
                fontSize: 7,
                color: PdfColor.fromHex('#64748B'))),
        pw.SizedBox(height: 1),
        pw.Text(value,
            style: pw.TextStyle(
                font: ttfBold,
                fontSize: 10,
                color: valueColor ?? PdfColor.fromHex('#0F172A'))),
      ],
    );
  }

  static pw.Widget _infoRow(
      String label, String value, pw.Font ttf, pw.Font ttfBold,
      {double valueSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: pw.TextStyle(
                    font: ttf,
                    fontSize: 9,
                    color: PdfColor.fromHex('#475569'))),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(font: ttfBold, fontSize: valueSize)),
          ),
        ],
      ),
    );
  }
}
