import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> saveBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  String? dialogTitle,
}) async {
  await FilePicker.platform.saveFile(
    dialogTitle: dialogTitle,
    fileName: filename,
    bytes: Uint8List.fromList(bytes),
  );
}
