import 'package:cloud_firestore/cloud_firestore.dart';

class SaleHistoryItem {
  final String status;
  final String? note;
  final DateTime timestamp;
  final String actor; // 'Admin', 'Marketing', 'System'

  SaleHistoryItem({
    required this.status,
    this.note,
    required this.timestamp,
    required this.actor,
  });

  factory SaleHistoryItem.fromMap(Map<String, dynamic> map) {
    return SaleHistoryItem(
      status: map['status'] ?? '',
      note: map['note'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      actor: map['actor'] ?? 'System',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
      'actor': actor,
    };
  }
}

class SaleModel {
  final String id;
  final String userId;
  final String productId;
  final Map<String, dynamic> details;
  final double totalPrice;
  final String paymentStatus; // DP, LUNAS, PENDING, CANCELED, COMPLETE, PROBLEM
  final double bonusAmount; // General/Legacy total bonus
  final double commissionAmount; // Specific Commission (Cash)
  final double pulsaBonusAmount; // Specific Pulsa (Credit)
  final double paidAmount; // Amount currently paid (DP or Full)
  final DateTime createdAt;
  final String? transactionProofUrl;
  final List<SaleHistoryItem> history; // New history field

  static const String statusPending = 'PENDING';
  static const String statusDp = 'DP';
  static const String statusLunas = 'LUNAS';
  static const String statusComplete = 'COMPLETE';
  static const String statusProblem = 'PROBLEM';
  static const String statusCanceled = 'CANCELED';

  SaleModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.details,
    required this.totalPrice,
    required this.paymentStatus,
    required this.bonusAmount,
    required this.createdAt,
    this.commissionAmount = 0,
    this.pulsaBonusAmount = 0,
    this.paidAmount = 0,
    this.transactionProofUrl,
    this.history = const [],
  });

  factory SaleModel.fromMap(Map<String, dynamic> data, String id) {
    return SaleModel(
      id: id,
      userId: data['user_id'] ?? '',
      productId: data['product_id'] ?? '',
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      totalPrice: (data['total_price'] ?? 0).toDouble(),
      paymentStatus: data['payment_status'] ?? statusPending,
      bonusAmount: (data['bonus_amount'] ?? 0).toDouble(),
      commissionAmount: (data['commission_amount'] ?? 0).toDouble(),
      pulsaBonusAmount: (data['pulsa_bonus_amount'] ?? 0).toDouble(),
      paidAmount: (data['paid_amount'] ?? 0).toDouble(),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      transactionProofUrl: data['transaction_proof_url'],
      history:
          (data['history'] as List<dynamic>?)
              ?.map((e) => SaleHistoryItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'product_id': productId,
      'details': details,
      'total_price': totalPrice,
      'payment_status': paymentStatus,
      'bonus_amount': bonusAmount,
      'commission_amount': commissionAmount,
      'pulsa_bonus_amount': pulsaBonusAmount,
      'paid_amount': paidAmount,
      'created_at': Timestamp.fromDate(createdAt),
      'transaction_proof_url': transactionProofUrl,
      'history': history.map((e) => e.toMap()).toList(),
    };
  }
}
