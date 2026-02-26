import 'package:cloud_firestore/cloud_firestore.dart';

enum BroadcastTarget { all, parents, drivers, gateOfficers }

class BroadcastMessage {
  final String id;
  final String title;
  final String body;
  final BroadcastTarget target;
  final DateTime createdAt;
  final String senderId;

  BroadcastMessage({
    required this.id,
    required this.title,
    required this.body,
    required this.target,
    required this.createdAt,
    required this.senderId,
  });

  factory BroadcastMessage.fromMap(Map<String, dynamic> map, String id) {
    return BroadcastMessage(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      target: BroadcastTarget.values.firstWhere(
        (e) => e.toString().split('.').last == map['target'],
        orElse: () => BroadcastTarget.all,
      ),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      senderId: map['senderId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'target': target.toString().split('.').last,
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': senderId,
    };
  }
}

abstract class BroadcastRepository {
  Future<void> sendBroadcast(BroadcastMessage message);
  Stream<List<BroadcastMessage>> getBroadcasts();
  Future<void> deleteBroadcast(String id);
}
