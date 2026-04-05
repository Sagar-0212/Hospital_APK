import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _getChatId(String u1, String u2) {
    final ids = [u1, u2]..sort();
    return ids.join('_');
  }

  Stream<List<ChatMessage>> getMessages(String user1, String user2) {
    final chatId = _getChatId(user1, user2);
    return _db
        .collection('messages')
        .where('chatId', isEqualTo: chatId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort client-side to bypass Firestore composite index requirement
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;
    
    final chatId = _getChatId(senderId, receiverId);
    
    await _db.collection('messages').add({
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': trimmedText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
