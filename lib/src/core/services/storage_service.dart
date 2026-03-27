import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/minio.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  late Minio _minio;
  final String _bucketName;
  final String _endpoint;
  final String _region;

  StorageService()
    : _bucketName = dotenv.env['R2_BUCKET_NAME'] ?? '',
      _endpoint = dotenv.env['R2_ENDPOINT'] ?? '',
      _region = dotenv.env['R2_REGION'] ?? 'auto' {
    _minio = Minio(
      endPoint: _endpoint,
      accessKey: dotenv.env['R2_ACCESS_KEY'] ?? '',
      secretKey: dotenv.env['R2_SECRET_KEY'] ?? '',
      region: _region,
      useSSL: true, // R2 requires SSL
    );
  }

  /// Uploads a file to R2 and returns its public (or presigned) URL.
  Future<String> uploadFile(File file, String folder) async {
    if (_bucketName.isEmpty) throw Exception('Bucket name not configured');

    final fileName = '${const Uuid().v4()}${path.extension(file.path)}';
    final objectName = '$folder/$fileName';

    // R2 doesn't always strictly require content type, but it's good practice.
    // We can use the mime package to detect it if needed, or let minio handle it.

    // Read file as bytes
    final stream = file.openRead();
    final length = await file.length();

    await _minio.putObject(
      _bucketName,
      objectName,
      stream.map((chunk) => Uint8List.fromList(chunk)),
      size: length,
    );

    // Return the permanent URL if public access is enabled,
    // OR return a presigned URL if it's private.
    // For R2, the public URL structure usually depends on a custom domain.
    // If no custom domain, we might need to use presigned URLs for viewing
    // OR user might have enabled public access on the bucket URL directly (rare for R2).

    // For this implementation, I'll generate a presigned GET URL valid for 7 days (max).
    // Note: R2/S3 presigned URLs are great for private buckets.

    // However, for a "marketing asset" used in a public app, we usually want a permanent public URL.
    // Since I don't have the public domain prefix, I will assume presigned for now
    // or try to construct a URL if the user provides a public domain later.

    // Return the permanent URL using the custom domain
    return 'https://poster.librarypenerbitkbm.science/$objectName';
  }

  /// Uploads data directly (for web or memory bytes)
  Future<String> uploadBytes(
    Uint8List bytes,
    String fileName,
    String folder,
  ) async {
    if (_bucketName.isEmpty) throw Exception('Bucket name not configured');

    final objectName = '$folder/$fileName';

    // Note: putObject requires a Stream<Uint8List>.
    final stream = Stream<Uint8List>.value(bytes);

    await _minio.putObject(_bucketName, objectName, stream, size: bytes.length);

    return 'https://poster.librarypenerbitkbm.science/$objectName';
  }

  Future<void> deleteFileByUrl(String url) async {
    if (_bucketName.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isEmpty) return;

      String objectName;
      if (segments.contains(_bucketName)) {
        final bucketIndex = segments.indexOf(_bucketName);
        if (bucketIndex + 1 < segments.length) {
          objectName = segments.sublist(bucketIndex + 1).join('/');
        } else {
          return;
        }
      } else {
        // Fallback: assume everything is the object key
        objectName = segments.join('/');
      }

      await _minio.removeObject(_bucketName, objectName);
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  Future<void> deleteFile(String objectName) async {
    if (_bucketName.isEmpty) return;
    try {
      await _minio.removeObject(_bucketName, objectName);
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  Future<List<StorageItem>> listFiles({String? prefix}) async {
    if (_bucketName.isEmpty) return [];

    final List<StorageItem> items = [];

    try {
      // listObjectsV2 returns a Stream<List<Object>> usually, or similar.
      // Minio dart package: listObjectsV2 returns Stream<ListObjectsResult>
      // We need to collect the stream.

      await for (final result in _minio.listObjectsV2(
        _bucketName,
        prefix: prefix ?? '',
        recursive: true,
      )) {
        // Optimistic Parallel Loading of Presigned URLs
        final batchFutures = result.objects.map((obj) async {
          if (obj.key == null) return null;

          try {
            final url = 'https://poster.librarypenerbitkbm.science/${obj.key!}';

            return StorageItem(
              key: obj.key!,
              url: url,
              lastModified: obj.lastModified,
              size: obj.size ?? 0,
            );
          } catch (e) {
            return null; // Skip invalid items
          }
        });

        final loadedItems = await Future.wait(batchFutures);
        items.addAll(loadedItems.whereType<StorageItem>());
      }
    } catch (e) {
      debugPrint('Error listing files: $e');
    }

    // Sort by newest first
    items.sort(
      (a, b) => (b.lastModified ?? DateTime(0)).compareTo(
        a.lastModified ?? DateTime(0),
      ),
    );

    return items;
  }
}

class StorageItem {
  final String key;
  final String url;
  final DateTime? lastModified;
  final int size;

  StorageItem({
    required this.key,
    required this.url,
    this.lastModified,
    required this.size,
  });

  String get filename => key.split('/').last;
}
