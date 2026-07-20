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

/// Saves report files to the device Downloads/Files location.
class PdfDownloadService {
  Future<PdfDownloadResult> saveAndOpen({
    required Uint8List bytes,
    required String filename,
  }) {
    return saveAndOpenFile(
      bytes: bytes,
      filename: filename,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<PdfDownloadResult> saveExcelAndOpen({
    required Uint8List bytes,
    required String filename,
  }) {
    return saveAndOpenFile(
      bytes: bytes,
      filename: filename,
      fileExtension: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  Future<PdfDownloadResult> saveAndOpenFile({
    required Uint8List bytes,
    required String filename,
    required String fileExtension,
    required MimeType mimeType,
  }) async {
    final ext = fileExtension.toLowerCase().replaceAll('.', '');
    final lower = filename.toLowerCase();
    final safeName = lower.endsWith('.$ext')
        ? filename.substring(0, filename.length - ext.length - 1)
        : filename;

    // Saves into public Downloads on Android; Files/Documents on iOS/desktop.
    final savedPath = await FileSaver.instance.saveFile(
      name: safeName,
      bytes: bytes,
      fileExtension: ext,
      mimeType: mimeType,
    );

    var path = savedPath.trim();
    var savedToDownloads = path.isNotEmpty;

    // Fallback: app documents directory if plugin returns empty.
    if (path.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$safeName.$ext');
      await file.writeAsBytes(bytes, flush: true);
      path = file.path;
      savedToDownloads = false;
    }

    await OpenFilex.open(path);
    return PdfDownloadResult(path: path, savedToDownloads: savedToDownloads);
  }
}
