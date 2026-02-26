import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadProfilePicture(File file, String userId) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$ext';
      final ref = _storage
          .ref()
          .child('profiles')
          .child(userId)
          .child(fileName);

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$ext'),
      );

      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // Ignore errors if file doesn't exist
    }
  }
}
