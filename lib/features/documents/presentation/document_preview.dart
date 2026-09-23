import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/session_provider.dart';

final documentBytesProvider = FutureProvider.autoDispose.family<Uint8List, int>((ref, id) async {
  final bytes = await ref.watch(fleetRepositoryProvider).downloadDocument(id);
  return Uint8List.fromList(bytes);
});

bool isDocumentImage(String? filename) {
  final extension = filename?.split('.').last.toLowerCase();
  return extension == 'jpg' || extension == 'jpeg' || extension == 'png' || extension == 'webp';
}

class DocumentImagePreview extends ConsumerWidget {
  const DocumentImagePreview({
    super.key,
    this.bytes,
    this.documentId,
    this.height = 168,
    this.onTap,
  });

  final Uint8List? bytes;
  final int? documentId;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppColors.radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: _ImageBytes(bytes: bytes, documentId: documentId, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

Future<void> showDocumentImage(
  BuildContext context, {
  Uint8List? bytes,
  int? documentId,
  String? filename,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final viewport = MediaQuery.sizeOf(dialogContext);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 840,
            maxHeight: viewport.height * 0.86,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: dialogContext.tr('common.close'),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: _ImageBytes(bytes: bytes, documentId: documentId, fit: BoxFit.contain),
                ),
              ),
              if (filename != null && filename.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(filename.trim(), textAlign: TextAlign.center),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      );
    },
  );
}

class _ImageBytes extends ConsumerWidget {
  const _ImageBytes({
    required this.bytes,
    required this.documentId,
    required this.fit,
  });

  final Uint8List? bytes;
  final int? documentId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bytes != null) {
      return Image.memory(bytes!, fit: fit);
    }
    final id = documentId;
    if (id == null) {
      return const SizedBox.shrink();
    }
    return ref.watch(documentBytesProvider(id)).when(
          data: (data) => Image.memory(data, fit: fit),
          loading: () => const Center(
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const Center(child: Icon(Icons.broken_image_outlined, color: AppColors.muted)),
        );
  }
}
