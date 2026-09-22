import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/save_bytes.dart';
import '../../../shared/models/driver_invite.dart';
import '../../../shared/providers/session_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import 'drivers_screen.dart';
import '../../fleet/presentation/fleet_screen.dart';

Future<void> showImportDriversSheet(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _ImportDriversDialog(),
  );
}

class _ImportDriversDialog extends ConsumerStatefulWidget {
  const _ImportDriversDialog();

  @override
  ConsumerState<_ImportDriversDialog> createState() => _ImportDriversDialogState();
}

class _ImportDriversDialogState extends ConsumerState<_ImportDriversDialog> {
  PlatformFile? _file;
  DriverImportResult? _result;
  bool _downloading = false;
  bool _uploading = false;

  Future<void> _downloadTemplate() async {
    if (_downloading) return;
    final title = context.tr('drivers.downloadTemplate');
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(fleetRepositoryProvider).downloadDriverImportTemplate();
      if (bytes.isEmpty) {
        throw const ApiException(message: 'error');
      }
      await saveBytes(
        bytes: bytes,
        filename: 'drivers-import-template.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        dialogTitle: title,
      );
      if (mounted) {
        showAppSnack(context, context.tr('drivers.templateDownloaded'));
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
      showAppSnack(context, context.tr('drivers.noFile'));
      return;
    }
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      showAppSnack(context, context.tr('drivers.noFile'));
      return;
    }
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final result = await ref.read(fleetRepositoryProvider).importDrivers(
            bytes: bytes,
            filename: file.name,
          );
      ref.invalidate(driversListProvider);
      ref.invalidate(fleetDriversProvider);
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

  Future<void> _copyUnsent() async {
    final result = _result;
    if (result == null) return;
    final links = result.drivers
        .where((driver) => !driver.whatsappSent && driver.inviteUrl.isNotEmpty)
        .map((driver) => '${driver.name}\t${driver.phone ?? ''}\t${driver.inviteUrl}')
        .join('\n');
    if (links.isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: links));
    if (mounted) {
      showAppSnack(context, context.tr('drivers.inviteCopied'));
    }
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      showAppSnack(context, context.tr('drivers.inviteCopied'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return AlertDialog(
      title: Text(context.tr('drivers.importTitle')),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('drivers.importHint')),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton(
                    label: context.tr('drivers.downloadTemplate'),
                    outlined: true,
                    icon: Icons.download_outlined,
                    loading: _downloading,
                    onPressed: _downloadTemplate,
                  ),
                  AppButton(
                    label: _file?.name ?? context.tr('drivers.chooseFile'),
                    outlined: true,
                    icon: Icons.upload_file_outlined,
                    onPressed: _pickFile,
                  ),
                ],
              ),
              if (result != null) ...[
                const SizedBox(height: 20),
                Text(
                  context.tr('drivers.importSummary', {
                    'created': '${result.created}',
                    'failed': '${result.failed}',
                  }),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (result.drivers.any((driver) => !driver.whatsappSent)) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _copyUnsent,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: Text(context.tr('drivers.copyUnsent')),
                    ),
                  ),
                ],
                for (final driver in result.drivers) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(driver.name),
                    subtitle: Text(
                      driver.whatsappSent
                          ? context.tr('drivers.whatsappSent')
                          : (driver.phone ?? driver.inviteUrl),
                    ),
                    trailing: driver.inviteUrl.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('drivers.copyInvite'),
                            onPressed: () => _copyLink(driver.inviteUrl),
                            icon: const Icon(Icons.copy_outlined),
                          ),
                  ),
                ],
                for (final error in result.errors) ...[
                  const SizedBox(height: 8),
                  _ImportErrorTile(error: error),
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
          child: Text(_uploading ? context.tr('drivers.uploading') : context.tr('drivers.import')),
        ),
      ],
    );
  }
}

class _ImportErrorTile extends StatelessWidget {
  const _ImportErrorTile({required this.error});

  final DriverImportError error;

  @override
  Widget build(BuildContext context) {
    final title = error.details.isEmpty
        ? context.tr('drivers.row', {'row': '${error.row}'})
        : context.tr('drivers.rowDetails', {
            'row': '${error.row}',
            'details': error.details,
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
    if (error.field == 'phone' && message.contains('already exists')) {
      return context.tr('drivers.importPhoneTaken');
    }
    if (error.field == 'phone' && (message.contains('valid') || message.contains('required'))) {
      return context.tr('drivers.importPhoneInvalid');
    }
    if (error.field == 'email' && message.contains('taken')) {
      return context.tr('drivers.importEmailTaken');
    }
    return error.message;
  }
}
