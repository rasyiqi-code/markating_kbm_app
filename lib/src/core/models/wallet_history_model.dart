import 'package:cloud_firestore/cloud_firestore.dart';

class WalletHistoryModel {
  final String id;
  final String userId;
  final String type; // 'COMMISSION_IN', 'CLAIM_OUT', 'ADJUSTMENT'
  final int amount;
  final String description;
  final String relatedRefId; // SaleID or ClaimID
  final DateTime createdAt;

  WalletHistoryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.relatedRefId,
    required this.createdAt,
  });

  factory WalletHistoryModel.fromMap(Map<String, dynamic> data, String id) {
    return WalletHistoryModel(
      id: id,
      userId: data['user_id'] ?? '',
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toInt(),
      description: data['description'] ?? '',
      relatedRefId: data['related_ref_id'] ?? '',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'related_ref_id': relatedRefId,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
