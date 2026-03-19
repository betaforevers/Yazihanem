import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yazihanem_mobile/features/content/presentation/widgets/slug_field.dart';
import 'package:yazihanem_mobile/features/content/providers/content_provider.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';
import 'package:yazihanem_mobile/shared/theme/app_spacing.dart';
import 'package:yazihanem_mobile/shared/theme/app_text_styles.dart';

/// Content editor screen — create or edit content.
///
/// If [contentId] is null → create mode.
/// If [contentId] is provided → edit mode (loads existing content).
class ContentEditorScreen extends ConsumerStatefulWidget {
  final String? contentId;

  const ContentEditorScreen({super.key, this.contentId});

  bool get isEditing => contentId != null;

  @override
  ConsumerState<ContentEditorScreen> createState() =>
      _ContentEditorScreenState();
}

class _ContentEditorScreenState extends ConsumerState<ContentEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTitleChanged);
    if (widget.isEditing) {
      _loadContent();
    }
  }

  void _onTitleChanged() {
    if (!widget.isEditing || !_isDataLoaded) {
      _slugController.text = SlugField.generateSlug(_titleController.text);
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    try {
      final content =
          await ref.read(contentRepositoryProvider).getContent(widget.contentId!);
      _titleController.text = content.title;
      _slugController.text = content.slug;
      _bodyController.text = content.body;
      _isDataLoaded = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yükleme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _slugController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(contentRepositoryProvider);

      if (widget.isEditing) {
        await repo.updateContent(
          widget.contentId!,
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          body: _bodyController.text,
        );
      } else {
        await repo.createContent(
          title: _titleController.text.trim(),
          slug: _slugController.text.trim(),
          body: _bodyController.text,
        );
      }

      // Refresh list and go back
      await ref.read(contentListProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'İçerik güncellendi'
                : 'İçerik oluşturuldu'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/content');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'İçerik Düzenle' : 'Yeni İçerik'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : const Text('Kaydet',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading && widget.isEditing && !_isDataLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      enabled: !_isLoading,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Başlık gerekli' : null,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        hintText: 'İçerik başlığını girin',
                        prefixIcon: Icon(Icons.title_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Slug
                    SlugField(
                      controller: _slugController,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Body
                    TextFormField(
                      controller: _bodyController,
                      enabled: !_isLoading,
                      maxLines: 15,
                      minLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'İçerik',
                        hintText: 'İçeriğinizi buraya yazın...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Save button (bottom)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSave,
                        icon: Icon(
                          widget.isEditing
                              ? Icons.save_rounded
                              : Icons.add_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          widget.isEditing ? 'Güncelle' : 'Oluştur',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
