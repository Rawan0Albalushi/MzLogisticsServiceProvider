import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/save_bytes.dart';
import '../../../shared/models/fleet_import.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class FleetImportRequest {
  const FleetImportRequest({
    required this.namespace,
    required this.templateFilename,
    required this.downloadTemplate,
    required this.importFile,
    required this.onImported,
  });

  final String namespace;
  final String templateFilename;
  final Future<List<int>> Function() downloadTemplate;
  final Future<FleetImportResult> Function({
    required List<int> bytes,
    required String filename,
  }) importFile;
  final void Function(WidgetRef ref) onImported;
}

Future<void> showFleetImportSheet(
  BuildContext context,
  WidgetRef ref,
  FleetImportRequest request,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _FleetImportDialog(request: request),
  );
}

class _FleetImportDialog extends ConsumerStatefulWidget {
  const _FleetImportDialog({required this.request});

  final FleetImportRequest request;

  @override
  ConsumerState<_FleetImportDialog> createState() => _FleetImportDialogState();
}

class _FleetImportDialogState extends ConsumerState<_FleetImportDialog> {
  PlatformFile? _file;
  FleetImportResult? _result;
  bool _downloading = false;
  bool _uploading = false;

  String _tr(String key, [Map<String, String>? params]) {
    return context.tr('${widget.request.namespace}.$key', params);
  }

  Future<void> _downloadTemplate() async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await widget.request.downloadTemplate();
      if (bytes.isEmpty) {
        throw const ApiException(message: 'error');
      }
      await saveBytes(
        bytes: bytes,
        filename: widget.request.templateFilename,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        dialogTitle: _tr('downloadTemplate'),
      );
      if (mounted) {
        showAppSnack(context, _tr('templateDownloaded'));
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.message);
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(context, context.tr('common.error'));
      }
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    setState(() {
      _file = picked.files.first;
      _result = null;
    });
  }

  Future<void> _upload() async {
    final file = _file;
    if (file == null) {
      showAppSnack(context, _tr('noFile'));
      return;
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      showAppSnack(context, _tr('noFile'));
      return;
    }
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final result = await widget.request.importFile(
        bytes: bytes,
        filename: file.name,
      );
      widget.request.onImported(ref);
      if (mounted) {
        setState(() => _result = result);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showAppSnack(context, error.firstFieldError('file') ?? error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: Text(_tr('importTitle')),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_tr('importHint')),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton(
                    label: _tr('downloadTemplate'),
                    outlined: true,
                    icon: Icons.download_outlined,
                    loading: _downloading,
                    onPressed: _downloadTemplate,
                  ),
                  AppButton(
                    label: _file?.name ?? _tr('chooseFile'),
                    outlined: true,
                    icon: Icons.upload_file_outlined,
                    onPressed: _pickFile,
                  ),
                ],
              ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Text(
                  _tr('importSummary', {
                    'created': '${result.created}',
                    'failed': '${result.failed}',
                  }),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                for (final item in result.items) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.label),
                    subtitle: Text(_tr('row', {'row': '${item.row}'})),
                  ),
                ],
                for (final error in result.errors) ...[
                  const SizedBox(height: 8),
                  _ImportErrorTile(
                    namespace: widget.request.namespace,
                    error: error,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('common.close')),
        ),
        FilledButton(
          onPressed: _uploading ? null : _upload,
          child: Text(_uploading ? _tr('uploading') : _tr('import')),
        ),
      ],
    );
  }
}

class _ImportErrorTile extends StatelessWidget {
  const _ImportErrorTile({required this.namespace, required this.error});

  final String namespace;
  final FleetImportError error;

  @override
  Widget build(BuildContext context) {
    final title = error.detailText.isEmpty
        ? context.tr('$namespace.row', {'row': '${error.row}'})
        : context.tr('$namespace.rowDetails', {
            'row': '${error.row}',
            'details': error.detailText,
          });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 2),
          Text(
            _localizedMessage(context),
            style: const TextStyle(color: AppColors.danger, height: 1.4),
          ),
        ],
      ),
    );
  }

  String _localizedMessage(BuildContext context) {
    final message = error.message.toLowerCase();
    if (namespace == 'trucks') {
      if (error.field == 'plate_number' &&
          (message.contains('already') || message.contains('taken'))) {
        return context.tr('trucks.importPlateTaken');
      }
      if (error.field == 'type') {
        return context.tr('trucks.importTypeInvalid');
      }
      if (error.field == 'capacity_tons') {
        return context.tr('trucks.importCapacityInvalid');
      }
    }
    if (namespace == 'equipment') {
      if (error.field == 'truck_plate') {
        return context.tr('equipment.importTruckMissing');
      }
      if (error.field == 'quantity') {
        return context.tr('equipment.importQuantityInvalid');
      }
      if (error.field == 'name') {
        return context.tr('validation.required');
      }
    }
    return error.message;
  }
}
