import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? error;

  UploadResult({
    required this.success,
    this.downloadUrl,
    this.error,
  });
}

class AppFileUploader {
  AppFileUploader._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const int maxFileSizeInMB = 10;

  /// =====================================================
  /// PICK IMAGE FROM GALLERY
  /// =====================================================

  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      debugPrint('pickImageFromGallery Error: $e');
      return null;
    }
  }

  /// =====================================================
  /// PICK IMAGE FROM CAMERA
  /// =====================================================

  static Future<File?> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      debugPrint('pickImageFromCamera Error: $e');
      return null;
    }
  }

  /// =====================================================
  /// PICK PDF / DOCUMENT
  /// =====================================================

  static Future<File?> pickDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      return File(result.files.single.path!);
    } catch (e) {
      debugPrint('pickDocument Error: $e');
      return null;
    }
  }

  /// =====================================================
  /// VALIDATE FILE SIZE
  /// =====================================================

  static bool isValidFileSize(File file) {
    final sizeInBytes = file.lengthSync();

    final sizeInMB = sizeInBytes / (1024 * 1024);

    return sizeInMB <= maxFileSizeInMB;
  }

  /// =====================================================
  /// CHECK IMAGE FILE
  /// =====================================================

  static bool isImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();

    return [
      '.jpg',
      '.jpeg',
      '.png',
      '.webp',
    ].contains(extension);
  }

  /// =====================================================
  /// CHECK PDF FILE
  /// =====================================================

  static bool isPdfFile(File file) {
    final extension = path.extension(file.path).toLowerCase();

    return extension == '.pdf';
  }

  /// =====================================================
  /// COMPRESS IMAGE
  /// =====================================================

  // static Future<File?> compressImage(
  //   File file,
  // ) async {
  //   try {
  //     if (!isImageFile(file)) {
  //       return file;
  //     }

  //     final targetPath =
  //         '${file.parent.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

  //     final compressedFile =
  //         await FlutterImageCompress.compressAndGetFile(
  //       file.absolute.path,
  //       targetPath,
  //       quality: 70,
  //       minWidth: 1080,
  //       minHeight: 1080,
  //     );

  //     if (compressedFile == null) {
  //       return file;
  //     }

  //     return File(compressedFile.path);
  //   } catch (e) {
  //     debugPrint('compressImage Error: $e');
  //     return file;
  //   }
  // }

  /// =====================================================
  /// UPLOAD FILE
  /// =====================================================

  static Future<UploadResult> uploadFile({
    required File file,
    required String storagePath,
    Function(double progress)? onProgress,
  }) async {
    try {
      /// FILE SIZE VALIDATION
      if (!isValidFileSize(file)) {
        return UploadResult(
          success: false,
          error: 'File size exceeds $maxFileSizeInMB MB',
        );
      }

      /// COMPRESS IMAGE
      File uploadableFile = file;

      // if (isImageFile(file)) {
      //   final compressed =
      //       await compressImage(file);

      //   if (compressed != null) {
      //     uploadableFile = compressed;
      //   }
      // }

      final reference = _storage.ref().child(storagePath);

      final uploadTask = reference.putFile(uploadableFile);

      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;

        onProgress?.call(progress);
      });

      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult(
        success: true,
        downloadUrl: downloadUrl,
      );
    } catch (e) {
      debugPrint('uploadFile Error: $e');

      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// =====================================================
  /// DELETE FILE
  /// =====================================================

  static Future<void> deleteFile(
    String fileUrl,
  ) async {
    try {
      await _storage.refFromURL(fileUrl).delete();
    } catch (e) {
      debugPrint('deleteFile Error: $e');
    }
  }

  /// =====================================================
  /// REPLACE FILE
  /// =====================================================

  static Future<UploadResult> replaceFile({
    required File newFile,
    required String storagePath,
    String? oldFileUrl,
    Function(double progress)? onProgress,
  }) async {
    try {
      if (oldFileUrl != null && oldFileUrl.isNotEmpty) {
        await deleteFile(oldFileUrl);
      }

      return await uploadFile(
        file: newFile,
        storagePath: storagePath,
        onProgress: onProgress,
      );
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// =====================================================
  /// GENERATE STORAGE PATH
  /// =====================================================

  static String generateBusinessKycPath({
    required String userId,
    required String fileName,
  }) {
    return 'business_kyc/$userId/$fileName';
  }
}
