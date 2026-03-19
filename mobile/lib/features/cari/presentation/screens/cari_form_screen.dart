import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/di/providers.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/cari/providers/cari_provider.dart';
import 'package:yazihanem_mobile/features/cari/services/cari_pdf_service.dart';
import 'package:yazihanem_mobile/features/cari/services/netsis_service.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Add / Edit cari (merchant) form screen.
class CariFormScreen extends ConsumerStatefulWidget {
  final String? cariId;

  const CariFormScreen({super.key, this.cariId});

  bool get isEdit => cariId != null;

  @override
  ConsumerState<CariFormScreen> createState() => _CariFormScreenState();
}

class _CariFormScreenState extends ConsumerState<CariFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unvanController = TextEditingController();
  final _vergiNoController = TextEditingController();
  final _vergiDairesiController = TextEditingController();
  final _telefonController = TextEditingController();
  final _adresController = TextEditingController();
  bool _eFaturaMukellef = false;
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final state = ref.read(cariListProvider);
    try {
      final cari = state.items.firstWhere((c) => c.id == widget.cariId);
      _unvanController.text = cari.unvan;
      _vergiNoController.text = cari.vergiNo;
      _vergiDairesiController.text = cari.vergiDairesi;
      _telefonController.text = cari.telefon ?? '';
      _adresController.text = cari.adres ?? '';
      setState(() {
        _eFaturaMukellef = cari.eFaturaMukellef;
        _isActive = cari.isActive;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _unvanController.dispose();
    _vergiNoController.dispose();
    _vergiDairesiController.dispose();
    _telefonController.dispose();
    _adresController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      CariModel savedCari;
      if (widget.isEdit) {
        await ref.read(cariListProvider.notifier).update(
              widget.cariId!,
              unvan: _unvanController.text.trim(),
              vergiNo: _vergiNoController.text.trim(),
              vergiDairesi: _vergiDairesiController.text.trim(),
              telefon: _telefonController.text.trim().isEmpty
                  ? null
                  : _telefonController.text.trim(),
              adres: _adresController.text.trim().isEmpty
                  ? null
                  : _adresController.text.trim(),
              eFaturaMukellef: _eFaturaMukellef,
              isActive: _isActive,
            );
        final state = ref.read(cariListProvider);
        savedCari = state.items.firstWhere((c) => c.id == widget.cariId);
      } else {
        savedCari = await ref.read(cariListProvider.notifier).create(
              unvan: _unvanController.text.trim(),
              vergiNo: _vergiNoController.text.trim(),
              vergiDairesi: _vergiDairesiController.text.trim(),
              telefon: _telefonController.text.trim().isEmpty
                  ? null
                  : _telefonController.text.trim(),
              adres: _adresController.text.trim().isEmpty
                  ? null
                  : _adresController.text.trim(),
              eFaturaMukellef: _eFaturaMukellef,
            );
      }

      if (mounted) {
        await _showPostSaveSheet(savedCari);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  /// Kaydet sonrası: Netsis aktarım + PDF indirme seçenekleri.
  Future<void> _showPostSaveSheet(CariModel cari) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _PostSaveSheet(cari: cari),
    );
    if (mounted) context.go('/cari');
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Cariyi Sil'),
        content: Text(
            '"${_unvanController.text}" kaydı silinsin mi? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(cariListProvider.notifier).delete(widget.cariId!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cari silindi'),
            backgroundColor: AppColors.warning),
      );
      context.go('/cari');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Cari Düzenle' : 'Yeni Cari'),
        actions: [
          if (widget.isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              onPressed: _isSaving ? null : _delete,
              tooltip: 'Sil',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // ── Zorunlu Alanlar ──
            const _SectionLabel(label: 'Firma Bilgileri'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _unvanController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Ünvan *',
                hintText: 'Ahmet Balıkçılık Ltd. Şti.',
                prefixIcon: Icon(Icons.store_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ünvan zorunludur' : null,
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _vergiNoController,
                    keyboardType: TextInputType.number,
                    maxLength: 11,
                    decoration: const InputDecoration(
                      labelText: 'Vergi / TC No *',
                      hintText: '1234567890',
                      prefixIcon: Icon(Icons.numbers_rounded),
                      counterText: '',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Vergi/TC no zorunludur';
                      }
                      if (v.trim().length != 10 && v.trim().length != 11) {
                        return '10 veya 11 hane olmalı';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _vergiDairesiController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Vergi Dairesi *',
                      hintText: 'Trabzon VD',
                      isDense: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Vergi dairesi zorunludur'
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── İletişim ──
            const _SectionLabel(label: 'İletişim (Opsiyonel)'),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                hintText: '0462 555 11 22',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _adresController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Adres',
                hintText: 'Trabzon Balık Hali, No:12',
                prefixIcon: Icon(Icons.location_on_rounded),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Fatura & Durum ──
            const _SectionLabel(label: 'Fatura & Durum'),
            const SizedBox(height: AppSpacing.sm),

            Container(
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('e-Fatura Mükellefi'),
                    subtitle: Text(
                      'GİB kayıtlı e-Fatura alıcısı',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                    secondary: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.info),
                    value: _eFaturaMukellef,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) => setState(() => _eFaturaMukellef = v),
                  ),
                  if (widget.isEdit) ...[
                    const Divider(height: 1, color: AppColors.divider),
                    SwitchListTile(
                      title: const Text('Aktif'),
                      subtitle: Text(
                        'Pasif cariler fişlerde seçilemez',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                      secondary: Icon(
                        Icons.toggle_on_rounded,
                        color: _isActive
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      value: _isActive,
                      activeThumbColor: AppColors.success,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Kaydet ──
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: Text(
                  widget.isEdit ? 'Güncelle' : 'Kaydet',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Kaydet sonrası bottom sheet: Netsis + PDF
// ══════════════════════════════════════════════════════════════════

class _PostSaveSheet extends ConsumerStatefulWidget {
  final CariModel cari;
  const _PostSaveSheet({required this.cari});

  @override
  ConsumerState<_PostSaveSheet> createState() => _PostSaveSheetState();
}

class _PostSaveSheetState extends ConsumerState<_PostSaveSheet> {
  _NetsisStatus _netsisStatus = _NetsisStatus.idle;
  String? _netsisMessage;
  bool _pdfLoading = false;

  NetsisService get _netsisService {
    final config = ref.read(appConfigProvider);
    return NetsisService(
        useMock: config.environment == AppEnvironment.dev);
  }

  Future<void> _netsisAktar() async {
    setState(() {
      _netsisStatus = _NetsisStatus.loading;
      _netsisMessage = null;
    });
    final result = await _netsisService.createCari(widget.cari);
    if (mounted) {
      setState(() {
        _netsisStatus =
            result.success ? _NetsisStatus.success : _NetsisStatus.error;
        _netsisMessage = result.message;
      });
    }
  }

  Future<void> _pdfIndir() async {
    setState(() => _pdfLoading = true);
    try {
      final bytes = await CariPdfService.generate(widget.cari);
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'cari-${widget.cari.kod}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Cari Bilgi Kartı: ${widget.cari.unvan}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF hatası: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _pdfLoading = false);
  }

  Future<void> _pdfOnizle() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CariPdfPreviewScreen(cari: widget.cari),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: AppColors.success, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cari Kaydedildi',
                          style: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        widget.cari.unvan,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 20),

            // ── Netsis Aktarım ──
            Text('NETSİS AKTARIM',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    fontSize: 11)),
            const SizedBox(height: 8),
            _NetsisButton(
              status: _netsisStatus,
              message: _netsisMessage,
              onPressed: _netsisStatus == _NetsisStatus.loading
                  ? null
                  : _netsisAktar,
            ),
            const SizedBox(height: 16),

            // ── PDF ──
            Text('PDF / ÇIKTI',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    fontSize: 11)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pdfLoading ? null : _pdfOnizle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius)),
                    ),
                    icon: const Icon(Icons.preview_rounded, size: 18),
                    label: const Text('Önizle'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pdfLoading ? null : _pdfIndir,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadius)),
                    ),
                    icon: _pdfLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download_rounded,
                            size: 18, color: Colors.white),
                    label: const Text('İndir / Paylaş', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Kapat
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam, Listeye Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Netsis Buton Widget ────────────────────────────────────────────

enum _NetsisStatus { idle, loading, success, error }

class _NetsisButton extends StatelessWidget {
  final _NetsisStatus status;
  final String? message;
  final VoidCallback? onPressed;

  const _NetsisButton(
      {required this.status, this.message, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Color bg;
    const Color fg = Colors.white;
    Widget icon;
    String label;

    switch (status) {
      case _NetsisStatus.idle:
        bg = const Color(0xFF1E40AF);
        icon = const Icon(Icons.sync_rounded, size: 18, color: Colors.white);
        label = "Netsis'e Aktar";
        break;
      case _NetsisStatus.loading:
        bg = const Color(0xFF1E40AF);
        icon = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white));
        label = 'Aktarılıyor…';
        break;
      case _NetsisStatus.success:
        bg = AppColors.success;
        icon =
            const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white);
        label = 'Netsis\'e Aktarıldı';
        break;
      case _NetsisStatus.error:
        bg = AppColors.error;
        icon = const Icon(Icons.error_rounded, size: 18, color: Colors.white);
        label = 'Hata — Tekrar Dene';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius)),
            ),
            icon: icon,
            label: Text(label,
                style: const TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                status == _NetsisStatus.success
                    ? Icons.check_rounded
                    : Icons.warning_rounded,
                size: 13,
                color: status == _NetsisStatus.success
                    ? AppColors.success
                    : AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  message!,
                  style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: status == _NetsisStatus.success
                          ? AppColors.success
                          : AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Tam Ekran PDF Önizleme
// ══════════════════════════════════════════════════════════════════

class _CariPdfPreviewScreen extends StatelessWidget {
  final CariModel cari;
  const _CariPdfPreviewScreen({required this.cari});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Cari Kartı — ${cari.kod}'),
      ),
      body: PdfPreview(
        build: (_) async {
          final bytes = await CariPdfService.generate(cari);
          return Uint8List.fromList(bytes);
        },
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        fontSize: 11,
      ),
    );
  }
}

