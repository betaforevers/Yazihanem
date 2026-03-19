import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/cari/domain/models/cari_model.dart';
import 'package:yazihanem_mobile/features/cari/providers/cari_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Bottom sheet for selecting a cari (merchant) from the registered list.
///
/// Returns the selected [CariModel] via [Navigator.pop].
/// Usage:
/// ```dart
/// final cari = await showCariSelectSheet(context);
/// ```
Future<CariModel?> showCariSelectSheet(BuildContext context) {
  return showModalBottomSheet<CariModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.borderRadiusLg)),
    ),
    builder: (_) => const _CariSelectSheet(),
  );
}

class _CariSelectSheet extends ConsumerStatefulWidget {
  const _CariSelectSheet();

  @override
  ConsumerState<_CariSelectSheet> createState() => _CariSelectSheetState();
}

class _CariSelectSheetState extends ConsumerState<_CariSelectSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cariListProvider.notifier).load(activeOnly: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CariModel> _filtered(List<CariModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((c) =>
        c.unvan.toLowerCase().contains(q) ||
        c.vergiNo.contains(q) ||
        c.kod.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cariListProvider);
    final filtered = _filtered(state.items);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
              child: Row(
                children: [
                  const Icon(Icons.store_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Cari Seç',
                      style: AppTextStyles.headlineSmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/cari/new');
                    },
                    icon: const Icon(Icons.add_rounded,
                        size: 18, color: AppColors.primary),
                    label: const Text('Yeni Ekle',
                        style: TextStyle(color: AppColors.primary)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Unvan, vergi no veya kod...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                ),
              ),
            ),

            // List
            Expanded(
              child: state.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary))
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store_rounded,
                                  size: 48,
                                  color: AppColors.textMuted
                                      .withValues(alpha: 0.5)),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                _query.isEmpty
                                    ? 'Kayıtlı cari bulunamadı'
                                    : 'Eşleşen sonuç yok',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppSpacing.xs),
                          itemBuilder: (context, index) {
                            final cari = filtered[index];
                            return _CariTile(
                              cari: cari,
                              onTap: () => Navigator.pop(context, cari),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _CariTile extends StatelessWidget {
  final CariModel cari;
  final VoidCallback onTap;

  const _CariTile({required this.cari, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cari.unvan,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${cari.kod} • VN: ${cari.vergiNo}',
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
                child: Text('e-Fatura',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.info,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }
}
