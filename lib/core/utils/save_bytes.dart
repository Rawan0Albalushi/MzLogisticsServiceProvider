import 'save_bytes_stub.dart'
    if (dart.library.html) 'save_bytes_web.dart'
    if (dart.library.io) 'save_bytes_io.dart' as impl;

Future<void> saveBytes({
  required List<int> bytes,
  required String filename,
  required String mimeType,
  String? dialogTitle,
}) {
  return impl.saveBytes(
    bytes: bytes,
    filename: filename,
    mimeType: mimeType,
    dialogTitle: dialogTitle,
  );
}
