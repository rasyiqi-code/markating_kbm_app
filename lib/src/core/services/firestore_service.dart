import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/models/sale_model.dart';
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/models/link_bio_model.dart';
import 'package:markating_kbm_app/src/core/models/notification_model.dart';

import 'package:markating_kbm_app/src/core/models/claim_model.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/models/wallet_history_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Users
  Future<void> updateUserBankDetails(
    String userId,
    Map<String, dynamic> bankDetails,
  ) {
    return _db.collection('users').doc(userId).update({
      'bank_details': bankDetails,
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) {
    return _db.collection('users').doc(userId).update(data);
  }

  Stream<UserModel> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      throw Exception('User not found');
    });
  }

  // Username Helpers
  Future<bool> checkUsernameExists(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final snapshot = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return UserModel.fromMap(
        snapshot.docs.first.data(),
        snapshot.docs.first.id,
      );
    }
    return null;
  }

  /// Tries to find a user by username first, then by ID.
  Future<UserModel?> resolveUser(String identifier) async {
    // 1. Try finding by username
    final userByUsername = await getUserByUsername(identifier);
    if (userByUsername != null) return userByUsername;

    // 2. Try finding by ID (only if identifier doesn't look like a simple username, or just try anyway)
    // Actually, just try fetching the doc.
    final docSpan = await _db.collection('users').doc(identifier).get();
    if (docSpan.exists) {
      return UserModel.fromMap(docSpan.data()!, docSpan.id);
    }

    return null;
  }

  // Marketing Users List (For Admin)
  Stream<List<UserModel>> getAllMarketingUsers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'marketing')
        // Order by Total Sales to show top performers first? Or Name?
        // Let's rely on client-side sort or default
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Admin: Delete User (Firestore Doc only)
  Future<void> deleteUser(String userId) {
    return _db.collection('users').doc(userId).delete();
  }

  // Admin: Update User Role/Name
  Future<void> updateAdminUser(String userId, Map<String, dynamic> data) {
    return _db.collection('users').doc(userId).update(data);
  }

  // Admin: Recalculate Stats (Backfill for existing users)
  Future<void> recalculateUserStats(String userId) async {
    final userRef = _db.collection('users').doc(userId);

    // Get all LUNAS sales
    final salesSnapshot = await _db
        .collection('sales')
        .where('user_id', isEqualTo: userId)
        .where('payment_status', isEqualTo: SaleModel.statusComplete)
        .get();

    int totalSales = 0;
    int totalCommission = 0;
    int totalPulsa = 0;

    for (var doc in salesSnapshot.docs) {
      final data = doc.data();
      totalSales++;
      totalCommission += (data['commission_amount'] ?? 0) as int;
      totalPulsa += (data['pulsa_bonus_amount'] ?? 0) as int;
    }

    // Update User Doc
    await userRef.update({
      'total_sales_count': totalSales,
      'total_commission_earned': totalCommission,
      'total_pulsa_earned': totalPulsa,
    });
  }

  // Products
  Stream<List<ProductModel>> getProducts(int houseType) {
    return _db
        .collection('products')
        .where('house_type', isEqualTo: houseType)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addProduct(ProductModel product) {
    return _db.collection('products').add(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) {
    return _db.collection('products').doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  // Sales
  Future<void> addSale(SaleModel sale) {
    // If status is NOT COMPLETE, simple add (No Balance Update)
    if (sale.paymentStatus != SaleModel.statusComplete) {
      return _db.collection('sales').add(sale.toMap());
    }

    // If COMPLETE (Rarely happens on creation, but handled), Credit Balance immediately
    final saleRef = _db.collection('sales').doc(); // Auto-gen ID
    final userRef = _db.collection('users').doc(sale.userId);

    return _db.runTransaction((transaction) async {
      // 1. Create Sale
      // Use the auto-gen ID but we need to put it in the map if model has it?
      // SaleModel.toMap doesn't include ID usually if it's from doc.id.
      // But we can just write the data.
      transaction.set(saleRef, sale.toMap());

      // 2. Credit Commission
      if (sale.commissionAmount > 0) {
        transaction.update(userRef, {
          'commission_balance': FieldValue.increment(
            sale.commissionAmount.toInt(),
          ),
        });

        final commHistoryRef = _db.collection('wallet_history').doc();
        final commHistory = WalletHistoryModel(
          id: commHistoryRef.id,
          userId: sale.userId,
          type: 'COMMISSION_IN',
          amount: sale.commissionAmount.toInt(),
          description:
              'Komisi Penjualan: ${sale.details['product_name'] ?? "Item"}',
          relatedRefId: saleRef.id,
          createdAt: DateTime.now(),
        );
        transaction.set(commHistoryRef, commHistory.toMap());
      }

      // 3. Credit Pulsa Bonus
      if (sale.pulsaBonusAmount > 0) {
        transaction.update(userRef, {
          'pulsa_balance': FieldValue.increment(sale.pulsaBonusAmount.toInt()),
        });

        final pulsaHistoryRef = _db.collection('wallet_history').doc();
        final pulsaHistory = WalletHistoryModel(
          id: pulsaHistoryRef.id,
          userId: sale.userId,
          type: 'PULSA_IN',
          amount: sale.pulsaBonusAmount.toInt(),
          description: 'Bonus Pulsa: ${sale.details['product_name'] ?? "Item"}',
          relatedRefId: saleRef.id,
          createdAt: DateTime.now(),
        );
        transaction.set(pulsaHistoryRef, pulsaHistory.toMap());
      }

      // 4. Update User Stats (Total Sales & All-time Earnings)
      // Only for COMPLETE transactions
      transaction.update(userRef, {
        'total_sales_count': FieldValue.increment(1),
        'total_commission_earned': FieldValue.increment(
          sale.commissionAmount.toInt(),
        ),
        'total_pulsa_earned': FieldValue.increment(
          sale.pulsaBonusAmount.toInt(),
        ),
      });
    });
  }

  // Update Sale Status with Transaction (Handle Bonus)
  Future<void> updateSaleStatus(
    SaleModel sale,
    String newStatus, {
    String? note,
    String actor = 'Admin',
    Map<String, dynamic>? extraData,
  }) async {
    final saleRef = _db.collection('sales').doc(sale.id);
    final userRef = _db.collection('users').doc(sale.userId);

    // Create history item
    final historyItem = SaleHistoryItem(
      status: newStatus,
      note: note,
      timestamp: DateTime.now(),
      actor: actor,
    );

    return _db.runTransaction((transaction) async {
      final saleDoc = await transaction.get(saleRef);
      if (!saleDoc.exists) throw Exception("Sale does not exist!");

      final currentStatus = saleDoc.data()?['payment_status'];

      // If moving TO COMPLETE from non-COMPLETE -> Add Bonus
      // Logic adjusted: LUNAS is just Paid. COMPLETE is Finished/Delivered -> that's when agent gets paid.
      if (newStatus == SaleModel.statusComplete &&
          currentStatus != SaleModel.statusComplete) {
        // Update Sale status and add history
        final updateMap = {
          'payment_status': newStatus,
          'history': FieldValue.arrayUnion([historyItem.toMap()]),
          ...?extraData,
        };
        transaction.update(saleRef, updateMap);

        // 1. Credit Commission
        if (sale.commissionAmount > 0) {
          transaction.update(userRef, {
            'commission_balance': FieldValue.increment(
              sale.commissionAmount.toInt(),
            ),
          });

          final commHistoryRef = _db.collection('wallet_history').doc();
          final commHistory = WalletHistoryModel(
            id: commHistoryRef.id,
            userId: sale.userId,
            type: 'COMMISSION_IN',
            amount: sale.commissionAmount.toInt(),
            description:
                'Komisi Penjualan: ${sale.details['product_name'] ?? "Item"}',
            relatedRefId: sale.id,
            createdAt: DateTime.now(),
          );
          transaction.set(commHistoryRef, commHistory.toMap());
        }

        // 2. Credit Pulsa Bonus
        if (sale.pulsaBonusAmount > 0) {
          transaction.update(userRef, {
            'pulsa_balance': FieldValue.increment(
              sale.pulsaBonusAmount.toInt(),
            ),
          });

          final pulsaHistoryRef = _db.collection('wallet_history').doc();
          final pulsaHistory = WalletHistoryModel(
            id: pulsaHistoryRef.id,
            userId: sale.userId,
            type: 'PULSA_IN',
            amount: sale.pulsaBonusAmount.toInt(),
            description:
                'Bonus Pulsa: ${sale.details['product_name'] ?? "Item"}',
            relatedRefId: sale.id,
            createdAt: DateTime.now(),
          );
          transaction.set(pulsaHistoryRef, pulsaHistory.toMap());
        }

        // 3. Update User Stats (Total Sales & All-time Earnings)
        // Transitioning to COMPLETE implies a successful sale close and earnings realized
        transaction.update(userRef, {
          'total_sales_count': FieldValue.increment(1),
          'total_commission_earned': FieldValue.increment(
            sale.commissionAmount.toInt(),
          ),
          'total_pulsa_earned': FieldValue.increment(
            sale.pulsaBonusAmount.toInt(),
          ),
        });
      } else {
        // Just update status (e.g., PENDING -> DP, or LUNAS -> COMPLETE, or -> PROBLEM)
        final updateMap = {
          'payment_status': newStatus,
          'history': FieldValue.arrayUnion([historyItem.toMap()]),
          ...?extraData,
        };
        transaction.update(saleRef, updateMap);
      }
    });
  }

  Stream<List<SaleModel>> getUserSales(String userId) {
    return _db
        .collection('sales')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SaleModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<SaleModel?> getSale(String saleId) async {
    final doc = await _db.collection('sales').doc(saleId).get();
    if (doc.exists) {
      return SaleModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Settings
  Stream<GlobalSettingsModel> getGlobalSettings() {
    return _db.collection('global_settings').doc('config').snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return GlobalSettingsModel.fromMap(doc.data()!);
      } else {
        return GlobalSettingsModel(
          bonusPercentR1: 0,
          minPayout: 5000000,
          latestInfo: 'Batas klaim pulsa bulan ini: Tgl 25.',
        );
      }
    });
  }

  Future<void> updateGlobalSettings(GlobalSettingsModel settings) {
    return _db
        .collection('global_settings')
        .doc('config')
        .set(settings.toMap());
  }

  // Link Bio
  Stream<List<LinkBioModel>> getLinks(String userId) {
    return _db
        .collection('links')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LinkBioModel.fromJson(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addLink(LinkBioModel link) {
    return _db.collection('links').add(link.toJson());
  }

  Future<void> updateLink(LinkBioModel link) {
    return _db.collection('links').doc(link.id).update(link.toJson());
  }

  // Admin: Get Sales with filters
  Stream<List<SaleModel>> getSales({
    int? houseType,
    String? status,
    int? limit,
  }) {
    Query query = _db.collection('sales');

    if (houseType != null) {
      query = query.where('details.house_type', isEqualTo: houseType);
    }

    if (status != null) {
      query = query.where('payment_status', isEqualTo: status);
    }

    query = query.orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (s) => s.docs
          .map((d) => SaleModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Future<void> deleteLink(String linkId) {
    return _db.collection('links').doc(linkId).delete();
  }

  // --- Claims & Wallet ---

  Stream<List<ClaimModel>> getUserClaims(String userId) {
    return _db
        .collection('claims')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<ClaimModel>> getPendingClaims() {
    return _db
        .collection('claims')
        .where('status', isEqualTo: ClaimModel.statusPending)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<ClaimModel>> getClaimHistory() {
    return _db
        .collection('claims')
        .where('status', isNotEqualTo: ClaimModel.statusPending)
        // Note: Firestore requires an index for 'status' != ... combined with orderBy
        // We will order manually or add another index if needed.
        // For 'not-equal' queries, correct ordering can be tricky.
        // Let's try simple query first, client-side sort if needed.
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ClaimModel.fromMap(d.data(), d.id)).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  Future<ClaimModel?> getClaim(String claimId) async {
    final doc = await _db.collection('claims').doc(claimId).get();
    if (doc.exists) {
      return ClaimModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  Future<String> requestClaim(ClaimModel claim) async {
    final userRef = _db.collection('users').doc(claim.userId);
    final claimRef = _db.collection('claims').doc();
    final historyRef = _db.collection('wallet_history').doc();

    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final currentBalance = claim.type == ClaimModel.typePulsa
          ? (userDoc.data()?['pulsa_balance'] ?? 0)
          : (userDoc.data()?['commission_balance'] ?? 0);

      if (currentBalance < claim.amount) {
        throw Exception('Insufficient balance');
      }

      // Deduct Balance
      if (claim.type == ClaimModel.typePulsa) {
        transaction.update(userRef, {
          'pulsa_balance': FieldValue.increment(-claim.amount),
        });
      } else {
        transaction.update(userRef, {
          'commission_balance': FieldValue.increment(-claim.amount),
        });
      }

      // Create Claim
      transaction.set(claimRef, claim.toMap());

      // History
      final history = WalletHistoryModel(
        id: historyRef.id,
        userId: claim.userId,
        type: 'CLAIM_OUT',
        amount: claim.amount,
        description: 'Claim request (${claim.type})',
        relatedRefId: claimRef.id,
        createdAt: DateTime.now(),
      );
      transaction.set(historyRef, history.toMap());
    });

    return claimRef.id;
  }

  Future<void> approveClaim(String claimId) {
    return _db.collection('claims').doc(claimId).update({
      'status': ClaimModel.statusPaid,
    });
  }

  Future<void> rejectClaim(ClaimModel claim) async {
    final userRef = _db.collection('users').doc(claim.userId);
    final claimRef = _db.collection('claims').doc(claim.id);
    final historyRef = _db.collection('wallet_history').doc();

    return _db.runTransaction((transaction) async {
      // Refund Balance
      if (claim.type == ClaimModel.typePulsa) {
        transaction.update(userRef, {
          'pulsa_balance': FieldValue.increment(claim.amount),
        });
      } else {
        transaction.update(userRef, {
          'commission_balance': FieldValue.increment(claim.amount),
        });
      }

      // Update Status
      transaction.update(claimRef, {'status': ClaimModel.statusRejected});

      // History
      final history = WalletHistoryModel(
        id: historyRef.id,
        userId: claim.userId,
        type: 'REFUND',
        amount: claim.amount,
        description: 'Claim rejected refund',
        relatedRefId: claim.id,
        createdAt: DateTime.now(),
      );
      transaction.set(historyRef, history.toMap());
    });
  }

  // --- Notifications ---

  Future<void> sendNotification(NotificationModel notification) {
    return _db.collection('notifications').add(notification.toMap());
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<NotificationModel>> getAdminNotifications() {
    return _db
        .collection('notifications')
        .where('recipientId', isEqualTo: 'role:admin')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => NotificationModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) {
    return _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }
}
