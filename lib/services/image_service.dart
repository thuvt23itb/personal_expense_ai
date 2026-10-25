import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageService {
  Future<String> persistImage(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw FileSystemException('Không tìm thấy ảnh nguồn', sourcePath);
    }
    final documents = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(documents.path, 'receipt_images'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final extension = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final targetPath = p.join(
      folder.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    final saved = await source.copy(targetPath);
    return saved.path;
  }

  Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    final file = File(imagePath);
    if (await file.exists()) await file.delete();
  }
}
