import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

abstract class FileDownloadHelper {
  static void downloadBytes({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) {
    downloadBytesPlatform(bytes: bytes, filename: filename, mimeType: mimeType);
  }
}
