import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';
import 'package:yazihanem_mobile/features/auction/presentation/widgets/auction_item_row.dart';
import 'package:yazihanem_mobile/features/auction/providers/auction_provider.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/cari/presentation/widgets/cari_select_sheet.dart';
import 'package:yazihanem_mobile/features/fish/domain/models/fish_model.dart';
import 'package:yazihanem_mobile/features/fish/providers/fish_provider.dart';
import 'package:yazihanem_mobile/features/boat/domain/models/boat_model.dart';
import 'package:yazihanem_mobile/features/boat/providers/boat_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

class AuctionFormScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionFormScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionFormScreen> createState() => _AuctionFormScreenState();
}

class _AuctionFormScreenState extends ConsumerState<AuctionFormScreen> {
  FishModel? _selectedFish;
  BoatModel? _selectedBoat;
  final _miktarController = TextEditingController();
  final _fiyatController = TextEditingController();
  bool _isAdding = false;
  bool _isAssigningCari = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishListProvider.notifier).load();
      ref.read(boatListProvider.notifier).load();
      ref.read(auctionListProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _miktarController.dispose();
    _fiyatController.dispose();
    super.dispose();
  }

  AuctionModel? _getAuction() {
    final state = ref.watch(auctionListProvider);
    try {
      return state.items.firstWhere((a) => a.id == widget.auctionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectCari(AuctionModel auction) async {
    final cari = await showCariSelectSheet(context);
    if (cari == null || !mounted) return;
    setState(() => _isAssigningCari = true);
    try {
      await ref.read(auctionListProvider.notifier).assignCari(auction.id, cari);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isAssigningCari = false);
  }

  Future<void> _clearCari(AuctionModel auction) async {
    await ref.read(auctionListProvider.notifier).assignCari(auction.id, null);
  }

  Future<void> _addItem() async {
    if (_selectedFish == null || _selectedBoat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Balık ve tekne seçimi gerekli'),
            backgroundColor: AppColors.warning),
      );
      return;
    }
    final miktar = double.tryParse(_miktarController.text.trim());
    final fiyat = double.tryParse(_fiyatController.text.trim());
    if (miktar == null || miktar <= 0 || fiyat == null || fiyat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Geçerli miktar ve fiyat girin'),
            backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      await ref.read(auctionListProvider.notifier).addItem(
            widget.auctionId,
            balik: _selectedFish!,
            tekne: _selectedBoat!,
            miktar: miktar,
            birimFiyat: fiyat,
          );
      _miktarController.clear();
      _fiyatController.clear();
      setState(() {
        _selectedFish = null;
        _selectedBoat = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final auction = _getAuction();
    final fishState = ref.watch(fishListProvider);
    final boatState = ref.watch(boatListProvider);

    if (auction == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(),
        body:
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final isOpen = auction.durum == AuctionDurum.acik;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(auction.fisNo),
        actions: [
          // PDF önizleme butonu — her zaman görünür
          IconButton(
            onPressed: () => context.go('/auction/${auction.id}/preview'),
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Fişi Görüntüle / PDF İndir',
            color: AppColors.primary,
          ),
          if (isOpen)
            TextButton.icon(
              onPressed: () async {
                await ref
                    .read(auctionListProvider.notifier)
                    .closeAuction(auction.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Mezat kapatıldı'),
                      backgroundColor: AppColors.success),
                );
                context.go('/auction');
              },
              icon: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success),
              label: const Text('Kapat',
                  style: TextStyle(color: AppColors.success)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Toplam Tutar ───
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              ),
              child: Column(
                children: [
                  Text('Toplam Tutar',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    '₺${auction.toplamTutar.toStringAsFixed(2)}',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: AppColors.success,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text('${auction.kalemSayisi} kalem',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Cari (Alıcı) Bölümü ───
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                border: Border.all(
                  color: auction.cari != null
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : (isOpen
                          ? AppColors.warning.withValues(alpha: 0.4)
                          : AppColors.divider),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.store_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'ALICI (CARİ)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      if (isOpen) ...[
                        if (auction.cari != null)
                          TextButton.icon(
                            onPressed: _isAssigningCari
                                ? null
                                : () => _clearCari(auction),
                            icon: const Icon(Icons.close_rounded,
                                size: 14, color: AppColors.error),
                            label: const Text('Kaldır',
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 12)),
                            style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero),
                          ),
                        TextButton.icon(
                          onPressed: _isAssigningCari
                              ? null
                              : () => _selectCari(auction),
                          icon: Icon(
                            auction.cari != null
                                ? Icons.swap_horiz_rounded
                                : Icons.add_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            auction.cari != null ? 'Değiştir' : 'Seç',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 12),
                          ),
                          style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_isAssigningCari)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ))
                  else if (auction.cari != null)
                    _CariInfoCard(cari: auction.cari!)
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: isOpen
                              ? AppColors.warning
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOpen
                              ? 'Alıcı seçilmedi — fişi kapatmadan önce ekleyin'
                              : 'Alıcı belirtilmemiş',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isOpen
                                ? AppColors.warning
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ─── Kalem Ekleme Formu (sadece açık fişlerde) ───
            if (isOpen) ...[
              Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.borderRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Kalem Ekle',
                        style:
                            AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                    const SizedBox(height: AppSpacing.sm),

                    // Balık dropdown
                    DropdownButtonFormField<FishModel>(
                      initialValue: _selectedFish,
                      onChanged: (v) => setState(() => _selectedFish = v),
                      decoration: const InputDecoration(
                        labelText: 'Balık Seç',
                        prefixIcon: Icon(Icons.set_meal_rounded),
                        isDense: true,
                      ),
                      items: fishState.items.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text('${f.tur} (${f.miktarLabel})'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Tekne dropdown
                    DropdownButtonFormField<BoatModel>(
                      initialValue: _selectedBoat,
                      onChanged: (v) => setState(() => _selectedBoat = v),
                      decoration: const InputDecoration(
                        labelText: 'Tekne Seç',
                        prefixIcon: Icon(Icons.sailing_rounded),
                        isDense: true,
                      ),
                      items: boatState.items.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text('${b.ad} (${b.komisyonLabel})'),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Miktar + Fiyat
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _miktarController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Miktar',
                              suffixText:
                                  _selectedFish?.birimTuru.label ?? '',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _fiyatController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Birim Fiyat',
                              prefixText: '₺',
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isAdding ? null : _addItem,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        icon: _isAdding
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.add_rounded,
                                color: Colors.white),
                        label: const Text('Ekle',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ─── Kalemler Listesi ───
            if (auction.kalemler.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Henüz kalem eklenmedi',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(
                    bottom: AppSpacing.sm, left: 2),
                child: Text(
                  'KALEMLER',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontSize: 11,
                  ),
                ),
              ),
              ...auction.kalemler.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AuctionItemRow(
                    item: item,
                    onDelete: isOpen
                        ? () => ref
                            .read(auctionListProvider.notifier)
                            .removeItem(auction.id, item.id)
                        : null,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact card showing selected cari info inside auction form.
class _CariInfoCard extends StatelessWidget {
  final CariModel cari;

  const _CariInfoCard({required this.cari});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius:
                  BorderRadius.circular(AppSpacing.borderRadiusSm),
            ),
            child: const Icon(Icons.store_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cari.unvan,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${cari.kod} • VN: ${cari.vergiNo} • ${cari.vergiDairesi}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (cari.eFaturaMukellef)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'e-Fatura',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.info,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

