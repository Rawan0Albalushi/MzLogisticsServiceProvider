import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/save_bytes.dart';
import '../../../shared/models/document.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'document_preview.dart';

const documentFileExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];
const documentMaxBytes = 5 * 1024 * 1024;

class PendingUpload {
  const PendingUpload({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;
}

class RequiredDocumentsSection extends ConsumerStatefulWidget {
  const RequiredDocumentsSection({
    super.key,
    required this.types,
    required this.documents,
    this.pending = const {},
    this.canUpload = false,
    this.showHeading = true,
    this.onUpload,
  });

  final List<String> types;
  final List<CompanyDocument> documents;
  final Map<String, PendingUpload> pending;
  final bool canUpload;
  final bool showHeading;
  final Future<void> Function(String type, List<int> bytes, String filename)? onUpload;

  @override
  ConsumerState<RequiredDocumentsSection> createState() => _RequiredDocumentsSectionState();
}

class _RequiredDocumentsSectionState extends ConsumerState<RequiredDocumentsSection> {
  String? _busyType;
  int? _openingId;

  CompanyDocument? _existing(String type) {
    for (final document in widget.documents) {
      if (document.type == type) {
        return document;
      }
    }
    return null;
  }

  Future<void> _pick(String type) async {
    final upload = widget.onUpload;
    if (upload == null || _busyType != null) {
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: documentFileExtensions,
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      showAppSnack(context, context.tr('common.error'));
      return;
    }
    if (bytes.length > documentMaxBytes) {
      showAppSnack(context, context.tr('documents.tooLarge'));
      return;
    }
    setState(() => _busyType = type);
    try {
      await upload(type, bytes, file.name);
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.firstFieldError('file') ?? error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busyType = null);
      }
    }
  }

  Future<void> _open(CompanyDocument document, {Uint8List? bytes}) async {
    final filename = document.title ?? '';
    if (bytes != null || isDocumentImage(filename)) {
      await showDocumentImage(
        context,
        bytes: bytes,
        documentId: bytes == null ? document.id : null,
        filename: filename,
      );
      return;
    }
    if (_openingId != null) {
      return;
    }
    setState(() => _openingId = document.id);
    try {
      await openStoredDocument(ref, context, document);
    } finally {
      if (mounted) {
        setState(() => _openingId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeading) ...[
          Text(
            context.tr('documents.requiredTitle'),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          context.tr('documents.requiredHint'),
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 12),
        for (final type in widget.types) ...[
          _slot(context, type),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _slot(BuildContext context, String type) {
    final pending = widget.pending[type];
    final existing = _existing(type);
    final filename = pending?.filename ?? existing?.title;
    final pendingBytes = pending == null ? null : Uint8List.fromList(pending.bytes);
    final image = isDocumentImage(filename);
    return _DocumentSlot(
      label: context.tr('documents.types.$type'),
      filename: filename,
      missingLabel: context.tr('documents.notUploaded'),
      canUpload: widget.canUpload && widget.onUpload != null,
      uploadLabel: existing == null && pending == null
          ? context.tr('documents.upload')
          : context.tr('documents.replace'),
      openLabel: context.tr('documents.open'),
      busy: _busyType == type,
      opening: _openingId == existing?.id,
      onUpload: () => _pick(type),
      onOpen: image || existing == null
          ? null
          : () => _open(existing),
      preview: image
          ? DocumentImagePreview(
              bytes: pendingBytes,
              documentId: pendingBytes == null ? existing?.id : null,
              onTap: () => showDocumentImage(
                context,
                bytes: pendingBytes,
                documentId: pendingBytes == null ? existing?.id : null,
                filename: filename,
              ),
            )
          : null,
    );
  }
}

class _DocumentSlot extends StatelessWidget {
  const _DocumentSlot({
    required this.label,
    required this.filename,
    required this.missingLabel,
    required this.canUpload,
    required this.uploadLabel,
    required this.openLabel,
    required this.busy,
    required this.opening,
    required this.onUpload,
    required this.onOpen,
    this.preview,
  });

  final String label;
  final String? filename;
  final String missingLabel;
  final bool canUpload;
  final String uploadLabel;
  final String openLabel;
  final bool busy;
  final bool opening;
  final VoidCallback onUpload;
  final VoidCallback? onOpen;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final storedName = filename?.trim();
    final hasFile = storedName != null && storedName.isNotEmpty;
    final actions = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (onOpen != null)
          TextButton.icon(
            onPressed: opening ? null : onOpen,
            icon: opening
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.open_in_new, size: 18),
            label: Text(openLabel),
          ),
        if (canUpload)
          TextButton.icon(
            onPressed: busy ? null : onUpload,
            icon: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(uploadLabel),
          ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppColors.radius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 8, 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: label,
                    children: const [
                      TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                if (!hasFile || preview == null)
                  Text(
                    hasFile ? storedName : missingLabel,
                    style: TextStyle(color: hasFile ? AppColors.ink : AppColors.muted, height: 1.3),
                  ),
              ],
            );
            final body = constraints.maxWidth < 460
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      details,
                      actions,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: details),
                      actions,
                    ],
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                body,
                if (preview != null) ...[
                  const SizedBox(height: 10),
                  preview!,
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> openStoredDocument(
  WidgetRef ref,
  BuildContext context,
  CompanyDocument document,
) async {
  try {
    final bytes = await ref.read(fleetRepositoryProvider).downloadDocument(document.id);
    if (!context.mounted) {
      return;
    }
    final filename = document.title?.trim().isNotEmpty == true ? document.title!.trim() : 'document';
    await saveBytes(
      bytes: bytes,
      filename: filename,
      mimeType: documentMimeType(filename),
    );
  } on ApiException catch (error) {
    if (context.mounted) {
      showAppSnack(
        context,
        error.message == 'network' ? context.tr('common.networkError') : error.message,
      );
    }
  }
}

String documentMimeType(String filename) {
  final extension = filename.split('.').last.toLowerCase();
  return switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'application/octet-stream',
  };
}
