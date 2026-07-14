import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class PdfDownloadResult {
  const PdfDownloadResult({
    required this.path,
    required this.savedToDownloads,
  });

  final String path;
  final bool savedToDownloads;
}

/// Saves monthly statement PDF to the device Downloads/Files location.
class PdfDownloadService {
  Future<PdfDownloadResult> saveAndOpen({
    required Uint8List bytes,
    required String filename,
  }) async {
    final safeName = filename.toLowerCase().endsWith('.pdf')
        ? filename.substring(0, filename.length - 4)
        : filename;

    // Saves into public Downloads on Android; Files/Documents on iOS/desktop.
    final savedPath = await FileSaver.instance.saveFile(
      name: safeName,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );

    var path = savedPath.trim();
    var savedToDownloads = path.isNotEmpty;

    // Fallback: app documents directory if plugin returns empty.
    if (path.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$safeName.pdf');
      await file.writeAsBytes(bytes, flush: true);
      path = file.path;
      savedToDownloads = false;
    }

    await OpenFilex.open(path);
    return PdfDownloadResult(path: path, savedToDownloads: savedToDownloads);
  }
}
