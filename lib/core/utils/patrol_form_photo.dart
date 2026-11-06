import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// A photo attached to a digital form's ATTACHMENT item. [path] is a
/// compressed `.webp` copy in the app documents folder (kept until it's
/// uploaded via `/patrol/addpatrolrecordimage`); [name] is the original
/// photo name with a `.webp` extension, sent as `json_image.document_name`.
class PatrolFormPhoto {
  final String path;
  final String name;

  /// `itemno` of the ATTACHMENT item this photo belongs to.
  final String itemNo;

  const PatrolFormPhoto({
    required this.path,
    required this.name,
    this.itemNo = '',
  });

  factory PatrolFormPhoto.fromJson(Map<String, dynamic> json) {
    return PatrolFormPhoto(
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      itemNo: json['itemno']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'itemno': itemNo,
      };
}

/// Decodes a JSON-encoded photo list; empty when [raw] is empty/malformed.
List<PatrolFormPhoto> decodePatrolFormPhotos(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => PatrolFormPhoto.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.path.isNotEmpty)
        .toList();
  } catch (_) {
    return [];
  }
}

String encodePatrolFormPhotos(List<PatrolFormPhoto> photos) =>
    photos.isEmpty ? '' : jsonEncode(photos.map((p) => p.toJson()).toList());

/// Compresses picked photos to small `.webp` files and cleans them up.
class PatrolFormPhotoStore {
  PatrolFormPhotoStore._();

  static const _folder = 'patrol_form_photos';

  /// Upload limit per photo.
  static const maxBytes = 200 * 1024;

  // Tried in order until the output fits [maxBytes]; the last step (640px,
  // quality 40) is far below the limit for any normal photo.
  static const _sizes = [1600, 1200, 900, 640];
  static const _qualities = [80, 60, 40];

  /// Compresses [sourcePath] to a `.webp` under [maxBytes] in the app
  /// documents folder and deletes [sourcePath] if it's the picker's cache
  /// copy.
  /// Returns null if the image couldn't be converted.
  static Future<PatrolFormPhoto?> compressAndSave(
    String sourcePath, {
    required String originalName,
    required String itemNo,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}/$_folder');
    if (!await dir.exists()) await dir.create(recursive: true);
    final targetPath = '${dir.path}/${const Uuid().v4()}.webp';

    // File-to-file compression, so the full image is never held in Dart
    // memory.
    File? output;
    try {
      outer:
      for (final size in _sizes) {
        for (final quality in _qualities) {
          final result = await FlutterImageCompress.compressAndGetFile(
            sourcePath,
            targetPath,
            format: CompressFormat.webp,
            quality: quality,
            minWidth: size,
            minHeight: size,
          );
          if (result == null) break outer;
          output = File(result.path);
          if (await output.length() <= maxBytes) break outer;
        }
      }
    } catch (_) {
      output = null;
    }

    // image_picker hands back a temp copy inside the app's own sandbox —
    // drop it once converted. Anything outside the sandbox (e.g. an
    // original gallery file) is left alone.
    try {
      if (sourcePath.startsWith(docsDir.parent.path)) {
        await deleteFiles([sourcePath]);
      }
    } catch (_) {}

    if (output == null || !await output.exists()) return null;
    return PatrolFormPhoto(
      path: output.path,
      name: _webpName(originalName),
      itemNo: itemNo,
    );
  }

  /// "IMG_001.jpg" → "IMG_001.webp".
  static String _webpName(String originalName) {
    final base = originalName.split(RegExp(r'[\\/]')).last;
    final dot = base.lastIndexOf('.');
    final stem = dot > 0 ? base.substring(0, dot) : base;
    return '${stem.isEmpty ? const Uuid().v4() : stem}.webp';
  }

  /// Best-effort delete; missing files are ignored.
  static Future<void> deleteFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // A leftover file isn't worth failing the caller over.
      }
    }
  }
}
