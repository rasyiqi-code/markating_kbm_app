import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markating_kbm_app/src/core/models/product_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:provider/provider.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _copywritingController;

  int _houseType = 1;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _uploadedImageUrl = p?.marketingKitUrl;
    _nameController = TextEditingController(text: p?.name ?? '');
    _categoryController = TextEditingController(text: p?.category ?? '');
    _priceController = TextEditingController(
      text: p?.price.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _copywritingController = TextEditingController(text: p?.copywriting ?? '');
    _houseType = p?.houseType ?? 1;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final product = ProductModel(
        id:
            widget.product?.id ??
            '', // ID handled by firestore if empty but we use .add() or .update
        houseType: _houseType,
        name: _nameController.text,
        category: _categoryController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        description: _descriptionController.text,
        copywriting: _copywritingController.text,
        // Use the uploaded image URL or keep existing one
        imageUrl: widget
            .product
            ?.imageUrl, // We haven't added image upload for main image yet
        marketingKitUrl: _uploadedImageUrl,
      );

      if (widget.product == null) {
        await firestore.addProduct(product);
      } else {
        await firestore.updateProduct(product);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                initialValue: _houseType,
                decoration: const InputDecoration(labelText: 'House Type'),
                items: const [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('Penerbitan Buku (B2C)'),
                  ),
                  DropdownMenuItem(value: 2, child: Text('KBM Creator (B2B)')),
                ],
                onChanged: (val) => setState(() => _houseType = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Base Price (Rp)'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Marketing Kit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _copywritingController,
                decoration: const InputDecoration(
                  labelText: 'Copywriting Text',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Poster Image'),
                subtitle: _uploadedImageUrl != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Image.network(
                            _uploadedImageUrl!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ],
                      )
                    : Text(
                        widget.product?.marketingKitUrl ?? 'No image uploaded',
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: () async {
                    try {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth:
                            1080, // Resize before upload (Server-size optimization)
                        maxHeight: 1080,
                        imageQuality: 85, // Compress to ~85% quality
                      );

                      if (image == null) return;
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uploading image...')),
                      );

                      final storage = Provider.of<StorageService>(
                        context,
                        listen: false,
                      );

                      // For web support we would need readAsBytes, but for mobile File is fine.
                      // Since we are likely targeted for mobile (based on file paths), we use File.
                      // However, cross-platform safety:
                      final bytes = await image.readAsBytes();
                      final url = await storage.uploadBytes(
                        bytes,
                        image.name,
                        'products',
                      );

                      if (!context.mounted) return;

                      setState(() {
                        _uploadedImageUrl = url;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Upload Successful!')),
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Upload failed: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
