import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/admin/image_management_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markating_kbm_app/src/core/services/storage_service.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentUserDetails();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isAdmin = _currentUser?.role == 'admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // User Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.transparent,
              foregroundImage: _currentUser?.photoUrl != null
                  ? NetworkImage(_currentUser!.photoUrl!)
                  : null,
              onForegroundImageError: _currentUser?.photoUrl != null
                  ? (exception, stackTrace) {
                      // Silently fails to child (initials)
                    }
                  : null,
              child: Text(
                (_currentUser?.email ?? 'User').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? _currentUser?.email ?? 'Unknown User',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (_currentUser?.username != null)
            Text(
              '@${_currentUser!.username}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            _currentUser?.role.toUpperCase() ?? 'USER',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ), // Colors.grey
          ),
          const SizedBox(height: 32),

          // Admin Section
          if (isAdmin) ...[
            _buildSectionHeader(context, 'Menu Admin'),
            _buildSettingsTile(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Manajemen Produk',
              subtitle: 'Tambah, edit, atau hapus produk',
              onTap: () => Navigator.pushNamed(context, '/admin/products'),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.settings_outlined,
              title: 'Pengaturan Global',
              subtitle: 'Atur bonus dan variabel sistem',
              onTap: () => Navigator.pushNamed(context, '/admin/settings'),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.image_outlined,
              title: 'Kelola Gambar',
              subtitle: 'Lihat dan hapus gambar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageManagementScreen(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
          ],

          // Personal Info Section (NEW)
          _buildSectionHeader(context, 'Informasi Pribadi'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Edit Profil',
            subtitle: 'Perbarui nama dan detail pribadi',
            onTap: () => _showEditProfileDialog(context),
          ),
          const SizedBox(height: 24),

          // Bank Info Section
          _buildSectionHeader(context, 'Detail Pembayaran'),
          _buildSettingsTile(
            context,
            icon: Icons.account_balance_rounded,
            title: 'Informasi Bank',
            subtitle: 'Kelola akun penarikan',
            onTap: () => _showBankSettingsDialog(context),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(context, 'Akun'),
          _buildSettingsTile(
            context,
            icon: Icons.logout,
            title: 'Keluar',
            subtitle: 'Keluar dari perangkat ini',
            isRed: true,
            onTap: () async {
              await Provider.of<AuthService>(context, listen: false).signOut();
              // Navigation handled by auth wrapper or main stream
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.delete_forever_rounded,
            title: 'Hapus Akun',
            subtitle: 'Hapus permanen akun dan data Anda',
            isRed: true,
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const SizedBox(height: 120), // Spacer for Bottom Nav
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant, // Colors.grey[600]
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isRed = false,
  }) {
    final color = isRed ? Colors.red : AppTheme.primaryColor;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ), // Colors.grey.withValues(alpha: 0.2)
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ), // Colors.grey[600]
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ), // Colors.grey
      ),
    );
  }

  void _showBankSettingsDialog(BuildContext context) {
    if (_currentUser == null) return;

    final bankDetails = _currentUser!.bankDetails ?? {};
    final bankNameController = TextEditingController(
      text: bankDetails['bank_name'],
    );
    final accNumberController = TextEditingController(
      text: bankDetails['account_number'],
    );
    final holderNameController = TextEditingController(
      text: bankDetails['account_holder'],
    );
    final phoneController = TextEditingController(text: bankDetails['phone']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Bank Information',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bankNameController,
                decoration: const InputDecoration(
                  labelText: 'Bank Name',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. BCA, Mandiri',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: holderNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone/E-Wallet Number',
                  border: OutlineInputBorder(),
                  hintText: 'For Pulsa or E-Wallet',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final bankName = bankNameController.text.trim();
                  final accNumber = accNumberController.text.trim();
                  final holderName = holderNameController.text.trim();

                  if (bankName.isEmpty ||
                      accNumber.isEmpty ||
                      holderName.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Semua field harus diisi')),
                    );
                    return;
                  }

                  if (accNumber.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nomor rekening minimal 8 digit'),
                      ),
                    );
                    return;
                  }

                  final newDetails = {
                    'bank_name': bankName,
                    'account_number': accNumber,
                    'account_holder': holderName,
                    'phone': phoneController.text.trim(),
                  };

                  try {
                    await Provider.of<FirestoreService>(
                      context,
                      listen: false,
                    ).updateUserBankDetails(_currentUser!.id, newDetails);

                    if (context.mounted) {
                      Navigator.pop(context);
                      await _loadUser(); // Refresh local user
                      // We need to use a context that is still mounted to show snackbar?
                      // Navigator.pop unmounts this context?
                      // Actually, if we pop, we should probably use the parent context or check if we can still use this context for snackbar.
                      // But usually changing to context.mounted satisfies the linter.
                      // Let's rely on ScaffoldMessenger finding the scaffold above even if this widget is unmounting?
                      // No, if context is unmounted, looking up ancestor might fail.
                      // However, usually we can capture ScaffoldMessenger before async gap?
                      // But let's try `if (context.mounted)` first as the error "guarded by unrelated" suggests mismatch.
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Detail berhasil disimpan!'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Detail'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    if (_currentUser == null) return;

    final emailController = TextEditingController(text: _currentUser!.email);
    final nameController = TextEditingController(text: _currentUser!.name);
    final usernameController = TextEditingController(
      text: _currentUser!.username,
    );
    final ktpController = TextEditingController(text: _currentUser!.ktpNumber);
    final addressController = TextEditingController(
      text: _currentUser!.address,
    );
    final phoneController = TextEditingController(
      text: _currentUser!.phoneNumber,
    );

    // Dialog state
    // ignore: no_leading_underscores_for_local_identifiers
    Uint8List? _newProfileImageBytes;
    // ignore: no_leading_underscores_for_local_identifiers
    String? _newProfileFilename;
    // ignore: no_leading_underscores_for_local_identifiers
    bool _isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor, // Colors.white
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 85,
                );
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setDialogState(() {
                    _newProfileImageBytes = bytes;
                    _newProfileFilename = image.name;
                  });
                }
              } catch (e) {
                // Handle error
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Edit Profil',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Profile Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest, // Colors.grey[100]
                                foregroundImage: _newProfileImageBytes != null
                                    ? MemoryImage(_newProfileImageBytes!)
                                    : (_currentUser?.photoUrl != null
                                              ? NetworkImage(
                                                  _currentUser!.photoUrl!,
                                                )
                                              : null)
                                          as ImageProvider?,
                                child:
                                    _newProfileImageBytes == null &&
                                        _currentUser?.photoUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Theme.of(context).iconTheme.color
                                            ?.withValues(
                                              alpha: 0.5,
                                            ), // Colors.grey[400]
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email (Read Only)
                    TextField(
                      controller: emailController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Alamat Email',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest, // Colors.grey[100]
                        helperText: 'Email tidak dapat diubah',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        hintText: 'Nama sesuai KTP',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                        hintText: 'Username unik',
                        helperText: 'Untuk link bio: kbm.bio/username',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // No KTP
                    TextField(
                      controller: ktpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'No. KTP',
                        border: OutlineInputBorder(),
                        hintText: '16 digit NIK',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap',
                        border: OutlineInputBorder(),
                        hintText: 'Jalan, RT/RW, Kelurahan, Kecamatan',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. WhatsApp / HP',
                        border: OutlineInputBorder(),
                        hintText: 'Contoh: 081234567890',
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              final newName = nameController.text.trim();
                              final newUsername = usernameController.text
                                  .trim();
                              final newKtp = ktpController.text.trim();
                              final newAddress = addressController.text.trim();
                              final newPhone = phoneController.text.trim();

                              if (newName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nama tidak boleh kosong'),
                                  ),
                                );
                                return;
                              }

                              if (newUsername.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Username tidak boleh kosong',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final validCharacters = RegExp(
                                r'^[a-zA-Z0-9_]+$',
                              );
                              if (!validCharacters.hasMatch(newUsername)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Username hanya huruf, angka, garis bawah',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                final firestore = Provider.of<FirestoreService>(
                                  context,
                                  listen: false,
                                );

                                // Check uniqueness
                                if (newUsername != _currentUser!.username) {
                                  final exists = await firestore
                                      .checkUsernameExists(newUsername);
                                  if (exists) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Username sudah digunakan',
                                          ),
                                        ),
                                      );
                                    }
                                    setDialogState(() => _isUploading = false);
                                    return;
                                  }
                                }

                                String? newPhotoUrl;
                                // Upload Photo if selected
                                if (_newProfileImageBytes != null) {
                                  if (!context.mounted) return;
                                  final storage = Provider.of<StorageService>(
                                    context,
                                    listen: false,
                                  );
                                  newPhotoUrl = await storage.uploadBytes(
                                    _newProfileImageBytes!,
                                    _newProfileFilename ?? 'profile.jpg',
                                    'profile_photos/${_currentUser!.id}',
                                  );
                                }

                                // Update Profile
                                final updateData = {
                                  'name': newName,
                                  'username': newUsername,
                                  'ktp_number': newKtp,
                                  'address': newAddress,
                                  'phone_number': newPhone,
                                };
                                if (newPhotoUrl != null) {
                                  updateData['photo_url'] = newPhotoUrl;
                                }

                                await firestore.updateUserProfile(
                                  _currentUser!.id,
                                  updateData,
                                );

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await _loadUser(); // Refresh UI
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Profil berhasil diperbarui!',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                                setDialogState(() => _isUploading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus akun Anda secara permanen? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              // 1. Close Confirmation Dialog
              Navigator.pop(context);

              // 2. Show Loading Dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.deleteAccount();

                if (context.mounted) {
                  // 3. Close Loading Dialog
                  Navigator.pop(context);

                  // 4. Show Success & Navigate to Login
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Akun berhasil dihapus.')),
                  );
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  // Close Loading Dialog on Error
                  Navigator.pop(context);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                }
              }
            },
            child: const Text('Hapus Secara Permanen'),
          ),
        ],
      ),
    );
  }
}
