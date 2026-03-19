import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';

/// Generates a Turkish-style e-Arşiv / e-Fatura PDF for an [AuctionModel].
///
/// Layout mirrors a standard Turkish invoice:
///   - Seller block (fish market info)
///   - Buyer block (cari info)
///   - Line items with KDV
///   - KDV breakdown table
///   - Grand total
class FisPdfService {
  // ── Satıcı sabit bilgileri (gerçek projede AppConfig'den gelir) ──
  static const _saticiUnvan = 'Yazıhanem Balık Hali ve Komisyonculuk A.Ş.';
  static const _saticiVergiNo = '9999999999';
  static const _saticiVergiDairesi = 'Trabzon Vergi Dairesi';
  static const _saticiAdres =
      'Trabzon Balık Hali, Sahil Cad. No:1, 61000 Trabzon';
  static const _saticiTel = '0462 000 00 00';

  /// KDV oranı — su ürünleri için %1 (2024 itibarıyla)
  static const double _kdvOrani = 1.0;

  static Future<List<int>> generate(AuctionModel auction) async {
    final doc = pw.Document();

    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();

    // ── Hesaplamalar ──
    final matrah = auction.toplamTutar;            // KDV hariç tutar
    final kdvTutari = matrah * _kdvOrani / 100;
    final genelToplam = matrah + kdvTutari;

    final faturaNo = 'FAT${auction.fisNo.replaceAll(RegExp(r'[^0-9]'), '')}';
    final tarih = _fmt(auction.mezatTarihi);
    final cariUnvan = auction.cari?.unvan ?? '— Alıcı belirtilmemiş —';
    final cariVergiNo = auction.cari?.vergiNo ?? '—';
    final cariVergiDairesi = auction.cari?.vergiDairesi ?? '—';
    final cariAdres = auction.cari?.adres ?? '—';
    final eFatura = auction.cari?.eFaturaMukellef ?? false;
    final faturaEtiketi =
        eFatura ? 'e-FATURA' : 'e-ARŞİV FATURA';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ══════════════════════════════════
            // BAŞLIK BANDI
            // ══════════════════════════════════
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F172A'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(_saticiUnvan,
                          style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 11,
                              color: PdfColors.white)),
                      pw.SizedBox(height: 2),
                      pw.Text('VKN: $_saticiVergiNo • $_saticiVergiDairesi',
                          style: pw.TextStyle(
                              font: ttf,
                              fontSize: 8,
                              color: PdfColor.fromHex('#94A3B8'))),
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
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#0D9488'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          faturaEtiketi,
                          style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 14,
                              color: PdfColors.white,
                              letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ══════════════════════════════════
            // FATURA NO & TARİH BANDI
            // ══════════════════════════════════
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E2E8F0'),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _labelValue('FATURA NO', faturaNo, ttf, ttfBold),
                  _labelValue('MEZAT FİŞ NO', auction.fisNo, ttf, ttfBold),
                  _labelValue('DÜZENLEME TARİHİ', tarih, ttf, ttfBold),
                  _labelValue('PARA BİRİMİ', 'TRY', ttf, ttfBold),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ══════════════════════════════════
            // ALICI BİLGİLERİ
            // ══════════════════════════════════
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('ALICI',
                            style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 8,
                                color: PdfColor.fromHex('#64748B'),
                                letterSpacing: 1)),
                        pw.SizedBox(height: 6),
                        pw.Text(cariUnvan,
                            style: pw.TextStyle(
                                font: ttfBold, fontSize: 11)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            'VKN/TCKN: $cariVergiNo',
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        pw.Text(
                            'Vergi Dairesi: $cariVergiDairesi',
                            style: pw.TextStyle(font: ttf, fontSize: 9)),
                        if (cariAdres != '—')
                          pw.Text(cariAdres,
                              style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 9,
                                  color: PdfColor.fromHex('#475569'))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ══════════════════════════════════
            // KALEMLER TABLOSU
            // ══════════════════════════════════
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(26),   // #
                1: const pw.FlexColumnWidth(3),     // Malzeme/Hizmet
                2: const pw.FlexColumnWidth(2.5),   // Tekne
                3: const pw.FlexColumnWidth(1.5),   // Miktar
                4: const pw.FlexColumnWidth(1.5),   // Birim Fiyat
                5: const pw.FlexColumnWidth(1),     // KDV %
                6: const pw.FlexColumnWidth(1.5),   // KDV Tutarı
                7: const pw.FlexColumnWidth(1.8),   // Tutar
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#1E293B')),
                  children: [
                    _th('#', ttfBold, align: pw.TextAlign.center),
                    _th('MAL/HİZMET ADI', ttfBold),
                    _th('TEKNE', ttfBold),
                    _th('MİKTAR', ttfBold, align: pw.TextAlign.right),
                    _th('BİRİM FİYAT', ttfBold, align: pw.TextAlign.right),
                    _th('KDV %', ttfBold, align: pw.TextAlign.center),
                    _th('KDV TUT.', ttfBold, align: pw.TextAlign.right),
                    _th('TUTAR (TRY)', ttfBold, align: pw.TextAlign.right),
                  ],
                ),
                // Rows
                ...auction.kalemler.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final rowKdv = item.toplamFiyat * _kdvOrani / 100;
                  final bg = i.isEven
                      ? PdfColors.white
                      : PdfColor.fromHex('#F8FAFC');
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _td('${i + 1}', ttf,
                          align: pw.TextAlign.center),
                      _td(item.balik.tur, ttfBold),
                      _td(item.tekne.ad, ttf),
                      _td(
                          '${item.miktar} ${item.balik.birimTuru.label}',
                          ttf,
                          align: pw.TextAlign.right),
                      _td(
                          '${item.birimFiyat.toStringAsFixed(2)} TRY',
                          ttf,
                          align: pw.TextAlign.right),
                      _td('%${_kdvOrani.toStringAsFixed(0)}', ttf,
                          align: pw.TextAlign.center),
                      _td(rowKdv.toStringAsFixed(2), ttf,
                          align: pw.TextAlign.right),
                      _td(item.toplamFiyat.toStringAsFixed(2), ttfBold,
                          align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),

            // ══════════════════════════════════
            // TOPLAM BÖLÜMÜ (sağa yaslanmış)
            // ══════════════════════════════════
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 240,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                      color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    _totalRow('MATRAH (KDV HARİÇ)',
                        '${matrah.toStringAsFixed(2)} TRY',
                        ttf, ttfBold),
                    pw.Divider(
                        color: PdfColor.fromHex('#E2E8F0'), thickness: 0.5),
                    _totalRow(
                        'HESAPLANAN KDV (%${_kdvOrani.toStringAsFixed(0)})',
                        '${kdvTutari.toStringAsFixed(2)} TRY',
                        ttf, ttfBold),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#0D9488'),
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(3),
                          bottomRight: pw.Radius.circular(3),
                        ),
                      ),
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('GENEL TOPLAM',
                              style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 11,
                                  color: PdfColors.white)),
                          pw.Text(
                              '${genelToplam.toStringAsFixed(2)} TRY',
                              style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 13,
                                  color: PdfColors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            pw.Spacer(),

            // ══════════════════════════════════
            // FOOTER
            // ══════════════════════════════════
            pw.Divider(
                color: PdfColor.fromHex('#CBD5E1'), thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bu belge $faturaEtiketi niteliğinde düzenlenmiştir.',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
                      color: PdfColor.fromHex('#94A3B8')),
                ),
                pw.Text(
                  'Oluşturulma: ${_fmt(DateTime.now())}',
                  style: pw.TextStyle(
                      font: ttf,
                      fontSize: 8,
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

  // ─── Yardımcı widget'lar ───────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static pw.Widget _labelValue(
      String label, String value, pw.Font ttf, pw.Font ttfBold) {
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
            style: pw.TextStyle(font: ttfBold, fontSize: 10)),
      ],
    );
  }

  static pw.Widget _th(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.white)),
    );
  }

  static pw.Widget _td(String text, pw.Font font,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(font: font, fontSize: 9)),
    );
  }

  static pw.Widget _totalRow(
      String label, String value, pw.Font ttf, pw.Font ttfBold) {
    return pw.Padding(
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  font: ttf,
                  fontSize: 9,
                  color: PdfColor.fromHex('#475569'))),
          pw.Text(value,
              style: pw.TextStyle(font: ttfBold, fontSize: 10)),
        ],
      ),
    );
  }
}
