import 'package:cloud_firestore/cloud_firestore.dart';

class ClaimModel {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'BANK_TRANSFER' or 'PULSA'
  final String status; // 'PENDING', 'PAID', 'REJECTED'
  final Map<String, dynamic> bankDetails;
  final DateTime createdAt;

  static const String statusPending = 'PENDING';
  static const String statusPaid = 'PAID';
  static const String statusRejected = 'REJECTED';

  static const String typeBank = 'BANK_TRANSFER';
  static const String typePulsa = 'PULSA';

  ClaimModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.bankDetails,
    required this.createdAt,
  });

  factory ClaimModel.fromMap(Map<String, dynamic> data, String id) {
    return ClaimModel(
      id: id,
      userId: data['user_id'] ?? '',
      amount: (data['amount'] ?? 0).toInt(),
      type: data['type'] ?? typeBank,
      status: data['status'] ?? statusPending,
      bankDetails: Map<String, dynamic>.from(data['bank_details'] ?? {}),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'bank_details': bankDetails,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
