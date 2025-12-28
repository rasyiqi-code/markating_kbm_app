import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/link_bio_model.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

class AddEditLinkDialog extends StatefulWidget {
  final LinkBioModel? link;

  const AddEditLinkDialog({super.key, this.link});

  @override
  State<AddEditLinkDialog> createState() => _AddEditLinkDialogState();
}

class _AddEditLinkDialogState extends State<AddEditLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedIcon = 'web';
  bool _isActive = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _icons = [
    {'id': 'web', 'icon': Icons.language},
    {'id': 'instagram', 'icon': Icons.camera_alt_outlined},
    {'id': 'whatsapp', 'icon': Icons.chat_bubble_outline},
    {'id': 'facebook', 'icon': Icons.facebook},
    {'id': 'twitter', 'icon': Icons.alternate_email},
    {'id': 'store', 'icon': Icons.storefront},
    {'id': 'store', 'icon': Icons.storefront},
    {'id': 'book', 'icon': Icons.book_outlined},
    {'id': 'email', 'icon': Icons.email_outlined},
    {'id': 'phone', 'icon': Icons.phone},
    {'id': 'other', 'icon': Icons.link},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.link != null) {
      _labelController.text = widget.link!.label;
      _urlController.text = widget.link!.url;
      _selectedIcon = widget.link!.icon;
      _isActive = widget.link!.isActive;
    } else {
      _selectedIcon = 'web';
    }

    _urlController.addListener(() {
      setState(() {});
    });
  }

  String _getHintText() {
    switch (_selectedIcon) {
      case 'whatsapp':
        return 'Nomor WhatsApp (cth: 62812...)';
      case 'email':
        return 'Alamat Email (cth: nama@email.com)';
      case 'phone':
        return 'Nomor Telepon (cth: 0812...)';
      case 'instagram':
        return 'Username / Link (cth: instagram.com/user)';
      default:
        return 'URL (https://...)';
    }
  }

  String _formatUrl(String input) {
    if (input.isEmpty) return input;

    input = input.trim();

    // Auto-format based on type
    if (_selectedIcon == 'whatsapp') {
      // Remove symbols
      String clean = input.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.startsWith('0')) clean = '62${clean.substring(1)}';
      if (!clean.startsWith('62')) clean = '62$clean';
      return 'https://wa.me/$clean';
    }

    if (_selectedIcon == 'email') {
      if (!input.startsWith('mailto:')) return 'mailto:$input';
      return input;
    }

    if (_selectedIcon == 'phone') {
      if (!input.startsWith('tel:')) return 'tel:$input';
      return input;
    }

    // Standard URL formatting
    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      return 'https://$input';
    }

    return input;
  }

  Future<void> _saveLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      final user = await auth.getCurrentUserDetails();

      if (user == null) throw Exception('User not logged in');

      final toSave = LinkBioModel(
        id: widget.link?.id ?? '', // ID handled by firestore for add
        userId: user.id,
        label: _labelController.text.trim(),
        url: _formatUrl(_urlController.text),
        icon: _selectedIcon,
        isActive: _isActive,
        createdAt: widget.link?.createdAt ?? DateTime.now(),
      );

      if (widget.link == null) {
        await firestore.addLink(toSave);
      } else {
        await firestore.updateLink(toSave);
      }

      if (mounted) Navigator.pop(context);
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.link == null ? 'Tambah Link Baru' : 'Edit Link',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(
                  labelText: 'Label (cth: Portfolio Saya)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: _getHintText(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                  helperText: 'Format akan disesuaikan otomatis saat disimpan',
                ),
                keyboardType:
                    _selectedIcon == 'whatsapp' || _selectedIcon == 'phone'
                    ? TextInputType.phone
                    : (_selectedIcon == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.url),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              Text(
                'Pilih Ikon',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _icons.map((item) {
                  final isSelected = _selectedIcon == item['id'];
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = item['id']),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                        ),
                      ),
                      child: Icon(
                        item['icon'],
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Simpan Link',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
