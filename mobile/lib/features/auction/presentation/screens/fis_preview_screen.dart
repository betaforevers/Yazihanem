import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yazihanem_mobile/features/auction/domain/models/auction_model.dart';
import 'package:yazihanem_mobile/features/auction/providers/auction_provider.dart';
import 'package:yazihanem_mobile/features/auction/services/fis_pdf_service.dart';
import 'package:yazihanem_mobile/shared/theme/app_colors.dart';

/// Full-screen PDF preview and download screen for an auction slip.
class FisPreviewScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const FisPreviewScreen({super.key, required this.auctionId});

  @override
  ConsumerState<FisPreviewScreen> createState() => _FisPreviewScreenState();
}

class _FisPreviewScreenState extends ConsumerState<FisPreviewScreen> {
  bool _isDownloading = false;

  AuctionModel? _getAuction() {
    final state = ref.watch(auctionListProvider);
    try {
      return state.items.firstWhere((a) => a.id == widget.auctionId);
    } catch (_) {
      return null;
    }
  }

  Future<String> _savePdf(AuctionModel auction) async {
    final bytes = await FisPdfService.generate(auction);
    final dir = await getApplicationDocumentsDirectory();
    final fileName = '${auction.fisNo.replaceAll('/', '-')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _sharePdf(AuctionModel auction) async {
    setState(() => _isDownloading = true);
    try {
      final path = await _savePdf(auction);
      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(path, mimeType: 'application/pdf')],
        subject: 'Mezat Fişi: ${auction.fisNo}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF hatası: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _isDownloading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auction = _getAuction();

    if (auction == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('Fatura — ${auction.fisNo}'),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                )
              : IconButton(
                  onPressed: () => _sharePdf(auction),
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'PDF İndir / Paylaş',
                ),
        ],
      ),
      body: PdfPreview(
        build: (_) async {
          final bytes = await FisPdfService.generate(auction);
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
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.share_rounded),
            onPressed: (ctx, build, pageFormat) async {
              final bytes = await build(pageFormat);
              if (!ctx.mounted) return;
              final dir = await getApplicationDocumentsDirectory();
              final fileName =
                  '${auction.fisNo.replaceAll('/', '-')}.pdf';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              if (ctx.mounted) {
                await Share.shareXFiles(
                  [XFile(file.path, mimeType: 'application/pdf')],
                  subject: 'Mezat Fişi: ${auction.fisNo}',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
