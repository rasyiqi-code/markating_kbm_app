import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/admin_product_card.dart';
import 'package:markating_kbm_app/src/features/admin/widgets/admin_product_empty_state.dart';
import 'package:provider/provider.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Manage Products'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Penerbitan Buku (B2C)'),
              Tab(text: 'KBM Creator (B2B)'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                // Show dialog or navigate to add screen
                Navigator.pushNamed(context, '/admin/products/add');
              },
            ),
          ],
        ),
        body: const TabBarView(
          children: [ProductList(houseType: 1), ProductList(houseType: 2)],
        ),
      ),
    );
  }
}

class ProductList extends StatelessWidget {
  final int houseType;

  const ProductList({super.key, required this.houseType});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return StreamBuilder<List<ProductModel>>(
      stream: firestore.getProducts(houseType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AdminProductEmptyState(houseType: houseType);
        }

        final products = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final product = products[index];
            return AdminProductCard(
              product: product,
              firestore: firestore,
              houseType: houseType,
            );
          },
        );
      },
    );
  }
}
