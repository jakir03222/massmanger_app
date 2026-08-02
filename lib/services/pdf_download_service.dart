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

/// Saves report files and opens them with a reliable local path.
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

    // Always write a local copy first so OpenFilex has a real filesystem path.
    final dir = await getTemporaryDirectory();
    final localFile = File('${dir.path}/$safeName.$ext');
    await localFile.writeAsBytes(bytes, flush: true);
    final localPath = localFile.path;

    var savedToDownloads = false;
    try {
      final savedPath = await FileSaver.instance.saveFile(
        name: safeName,
        bytes: bytes,
        fileExtension: ext,
        mimeType: mimeType,
      );
      savedToDownloads = savedPath.trim().isNotEmpty;
    } catch (_) {
      // Downloads folder save failed — local temp file still works.
      savedToDownloads = false;
    }

    try {
      await OpenFilex.open(localPath);
    } catch (_) {
      // Ignore open errors; file is still saved.
    }

    return PdfDownloadResult(
      path: localPath,
      savedToDownloads: savedToDownloads,
    );
  }
}
