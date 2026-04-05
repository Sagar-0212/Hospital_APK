import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ChatMessage>> getMessages(String user1, String user2) {
    // We use a specific collection for each chat pair or a global one with filters
    // For simplicity and efficiency, we'll use a global 'chats' collection
    return _db
        .collection('messages')
        .where(
          Filter.or(
            Filter.and(
              Filter('senderId', isEqualTo: user1),
              Filter('receiverId', isEqualTo: user2),
            ),
            Filter.and(
              Filter('senderId', isEqualTo: user2),
              Filter('receiverId', isEqualTo: user1),
            ),
          ),
        )
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
                  .toList(),
        );
  }

  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    if (text.trim().isEmpty) return;
    
    await _db.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
