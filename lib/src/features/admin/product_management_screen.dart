import 'package:flutter/material.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:markating_kbm_app/src/features/admin/add_edit_product_screen.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No products found'),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/admin/products/add'),
                  child: const Text('Add Product'),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: houseType == 1
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : AppTheme.secondaryColor.withValues(alpha: 0.1),
                  child: Icon(
                    houseType == 1 ? Icons.book : Icons.brush,
                    color: houseType == 1
                        ? AppTheme.primaryColor
                        : AppTheme.secondaryColor,
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${product.category}\n${NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(product.price)}',
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddEditProductScreen(product: product),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Delete ${product.name}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await firestore.deleteProduct(product.id);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
