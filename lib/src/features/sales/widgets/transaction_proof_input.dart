import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';

class TransactionProofInput extends StatefulWidget {
  final Function(String url) onProofUploaded;
  final String? initialUrl;
  final Color themeColor;

  const TransactionProofInput({
    super.key,
    required this.onProofUploaded,
    required this.themeColor,
    this.initialUrl,
  });

  @override
  State<TransactionProofInput> createState() => _TransactionProofInputState();
}

class _TransactionProofInputState extends State<TransactionProofInput> {
  bool _isUploading = false;
  String? _proofUrl;

  @override
  void initState() {
    super.initState();
    _proofUrl = widget.initialUrl;
  }

  Future<void> _pickAndUploadProof() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      if (!mounted) return;
      setState(() => _isUploading = true);
      try {
        final storage = Provider.of<StorageService>(context, listen: false);
        final bytes = await pickedFile.readAsBytes();
        final filename =
            'transaction_proof_${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        final url = await storage.uploadBytes(bytes, filename, 'transactions');

        if (!mounted) return;

        setState(() {
          _proofUrl = url;
          _isUploading = false;
        });
        
        widget.onProofUploaded(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bukti transaksi berhasil diunggah!')),
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal mengunggah: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickAndUploadProof,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
              image: _proofUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_proofUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _proofUrl == null
                ? _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap untuk unggah bukti transaksi',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                : null,
          ),
        ),
        if (_proofUrl != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton.icon(
              onPressed: _pickAndUploadProof,
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Ganti Bukti Transaksi'),
              style: TextButton.styleFrom(
                foregroundColor: widget.themeColor,
              ),
            ),
          ),
      ],
    );
  }
}
