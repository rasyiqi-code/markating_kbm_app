import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  static const String typeInfo = 'info';
  static const String typeSuccess = 'success';
  static const String typeWarning = 'warning';
  static const String typeError = 'error';

  final String id;
  final String title;
  final String body;
  final String type; // info, success, warning, error
  final String recipientId; // userId or 'role:admin'
  final String? relatedId; // e.g. transactionId
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.recipientId,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'recipientId': recipientId,
      'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? typeInfo,
      recipientId: map['recipientId'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
