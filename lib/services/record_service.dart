import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final recordServiceProvider = Provider<RecordService>((ref) => RecordService());

class RecordService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Web-compatible upload using raw bytes (works on all platforms).
  Future<String> uploadRecordBytes(
    String patientId,
    Uint8List bytes,
    String originalFileName,
  ) async {
    try {
      final ext = originalFileName.contains('.')
          ? originalFileName.split('.').last
          : 'jpg';
      final fileName = '${const Uuid().v4()}.$ext';
      final ref = _storage
          .ref()
          .child('medical_records')
          .child(patientId)
          .child(fileName);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/$ext'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
