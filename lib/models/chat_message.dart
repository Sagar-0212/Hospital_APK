import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatMessage(
      id: documentId,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
