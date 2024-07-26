import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a file to Firebase Storage
  Future<String?> uploadFile(File file, String folder) async {
    try {
      String fileName = path.basename(file.path);
      Reference ref = _storage.ref().child('$folder/$fileName');
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // Download a file from Firebase Storage
  Future<File?> downloadFile(String downloadURL, String localPath) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      final File file = File(localPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      debugPrint('Error downloading file: $e');
      return null;
    }
  }

  // Delete a file from Firebase Storage
  Future<bool> deleteFile(String downloadURL) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // List all files in a specific folder
  Future<List<String>> listFiles(String folder) async {
    try {
      final ListResult result = await _storage.ref(folder).listAll();
      List<String> fileUrls = [];
      for (var item in result.items) {
        String downloadUrl = await item.getDownloadURL();
        fileUrls.add(downloadUrl);
      }
      return fileUrls;
    } catch (e) {
      debugPrint('Error listing files: $e');
      return [];
    }
  }

  // Get metadata of a file
  Future<Map<String, dynamic>?> getFileMetadata(String downloadURL) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      final FullMetadata metadata = await ref.getMetadata();
      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
        'customMetadata': metadata.customMetadata,
      };
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  // Update metadata of a file
  Future<bool> updateFileMetadata(
      String downloadURL, Map<String, String> newMetadata) async {
    try {
      final ref = _storage.refFromURL(downloadURL);
      await ref.updateMetadata(SettableMetadata(customMetadata: newMetadata));
      return true;
    } catch (e) {
      debugPrint('Error updating file metadata: $e');
      return false;
    }
  }
}
