import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';

class DataSeederService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDemoData() async {
    final batch = _firestore.batch();

    // 1. Seed Products for House 1 (Penerbitan Buku)
    final r1Products = [
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 1,
        name: 'Paket Terbit Hemat',
        category: 'Penerbitan',
        price: 1500000,
        description:
            'Paket penerbitan buku ekonomis untuk penulis pemula. Termasuk layout standar dan cover template.',
        copywriting: 'Wujudkan mimpi jadi penulis dengan biaya terjangkau!',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 1,
        name: 'Paket Terbit Premium',
        category: 'Penerbitan',
        price: 3500000,
        description:
            'Layanan penerbitan lengkap dengan editing profesional, custom cover, dan marketing kit.',
        copywriting:
            'Buku Anda layak mendapatkan perlakuan istimewa kelas dunia.',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 1,
        name: 'Cetak Buku Satuan (POD)',
        category: 'Percetakan',
        price: 45000,
        description:
            'Layanan cetak buku satuan (Print on Demand), tanpa minimum order.',
        copywriting: 'Cetak satu buku saja? Tentu bisa!',
      ),
    ];

    // 2. Seed Products for House 2 (KBM Creator)
    final r2Products = [
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 2,
        name: 'Desain Cover Eklusif',
        category: 'Desain',
        price: 750000,
        description:
            'Jasa pembuatan cover buku custom oleh desainer berpengalaman.',
        copywriting: 'Cover buku yang menjual dimulai dari desain yang tepat.',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 2,
        name: 'Profesional Layout',
        category: 'Layout',
        price:
            15000 / 10, // Per 10 halaman misal, tapi kita set harga unit saja
        description:
            'Jasa tata letak isi buku agar nyaman dibaca dan sesuai standar industri (Harga per halaman).',
        copywriting: 'Buku yang rapi membuat pembaca betah berlama-lama.',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 2,
        name: 'Ilustrasi Wajah Vector',
        category: 'Ilustrasi',
        price: 150000,
        description:
            'Pembuatan ilustrasi wajah gaya vector untuk hadiah atau profil.',
        copywriting: 'Abadikan momen spesial dengan gaya seni modern.',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 2,
        name: 'Paket Konten Sosmed',
        category: 'Desain',
        price: 500000,
        description: 'Paket desain 5 feed Instagram untuk branding penulis.',
        copywriting: 'Tampil profesional di media sosial tanpa ribet.',
      ),
      ProductModel(
        id: _firestore.collection('products').doc().id,
        houseType: 1,
        name: 'Jasa Ghostwriter',
        category: 'Penulisan',
        price: 5000000,
        description:
            'Jasa penulisan buku biografi atau kisah inspiratif oleh penulis profesional.',
        copywriting: 'Cerita Anda, kami yang tuliskan dengan indah.',
      ),
    ];

    for (var p in [...r1Products, ...r2Products]) {
      final docRef = _firestore.collection('products').doc(p.id);
      batch.set(docRef, p.toMap());
    }

    await batch.commit();
  }

  Future<void> clearAllData() async {
    // 1. Delete all products
    final products = await _firestore.collection('products').get();
    final batch = _firestore.batch();
    for (var doc in products.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete all sales
    final sales = await _firestore.collection('sales').get();
    for (var doc in sales.docs) {
      batch.delete(doc.reference);
    }

    // 3. Delete all claims
    final claims = await _firestore.collection('claims').get();
    for (var doc in claims.docs) {
      batch.delete(doc.reference);
    }

    // 4. Delete wallet history
    final history = await _firestore.collection('wallet_history').get();
    for (var doc in history.docs) {
      batch.delete(doc.reference);
    }

    // 5. Reset User Balances & Stats
    final users = await _firestore.collection('users').get();
    for (var doc in users.docs) {
      batch.update(doc.reference, {
        'commission_balance': 0,
        'pulsa_balance': 0,
        'total_sales_count': 0,
        'total_commission_earned': 0,
        'total_pulsa_earned': 0,
      });
    }

    await batch.commit();
  }
}
