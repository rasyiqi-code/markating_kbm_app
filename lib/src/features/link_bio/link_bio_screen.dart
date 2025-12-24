import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:markating_kbm_app/src/core/models/global_settings_model.dart';
import 'package:markating_kbm_app/src/core/models/link_bio_model.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/services/auth_service.dart';
import 'package:markating_kbm_app/src/core/services/firestore_service.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:markating_kbm_app/src/features/link_bio/add_edit_link_dialog.dart';
import 'package:markating_kbm_app/src/features/link_bio/link_bio_preview_screen.dart';

class LinkBioScreen extends StatefulWidget {
  const LinkBioScreen({super.key});

  @override
  State<LinkBioScreen> createState() => _LinkBioScreenState();
}

class _LinkBioScreenState extends State<LinkBioScreen> {
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = await auth.getCurrentUserDetails();
    if (mounted && user != null) {
      setState(() => _currentUser = user);
    }
  }

  void _showAddEditDialog([LinkBioModel? link]) {
    showDialog(
      context: context,
      builder: (_) => AddEditLinkDialog(link: link),
    );
  }

  Future<void> _deleteLink(String linkId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Link?'),
        content: const Text('Apakah Anda yakin ingin menghapus link ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<FirestoreService>(
        context,
        listen: false,
      ).deleteLink(linkId);
    }
  }

  Future<void> _toggleActive(LinkBioModel link, bool newVal) async {
    final updated = link.copyWith(isActive: newVal);
    await Provider.of<FirestoreService>(
      context,
      listen: false,
    ).updateLink(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final firestore = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Keep background
      body: StreamBuilder<List<LinkBioModel>>(
        stream: firestore.getLinks(_currentUser!.id),
        builder: (context, snapshot) {
          // ... (Error/Loading checks remain same)
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final links = snapshot.data!;

          if (links.isEmpty) {
            // ... (Empty view logic remains same, just update variable usage if needed)
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada link.',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Link Pertama'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF6A11CB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: StreamBuilder<GlobalSettingsModel>(
                  stream: firestore.getGlobalSettings(),
                  builder: (context, settingsSnapshot) {
                    String baseUrl;
                    if (kIsWeb) {
                      baseUrl = Uri.base.origin;
                    } else {
                      baseUrl =
                          settingsSnapshot.data?.webBaseUrl ??
                          'https://kbm-group-app.web.app';
                    }

                    // Remove trailing slash if present to avoid double slashes
                    if (baseUrl.endsWith('/')) {
                      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
                    }

                    final identifier =
                        _currentUser!.username != null &&
                            _currentUser!.username!.isNotEmpty
                        ? _currentUser!.username
                        : _currentUser!.id;
                    final bioUrl = '$baseUrl/bio/$identifier';

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Colors.white24,
                              child: Icon(Icons.public, color: Colors.white),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Public Bio Anda',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${links.where((l) => l.isActive).length} Link Aktif',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    // ignore: deprecated_member_use
                                    await Share.share(
                                      'Check out my bio: $bioUrl',
                                      subject: 'My KBM Bio',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.share,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Bagikan Bio',
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppTheme.primaryColor,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LinkBioPreviewScreen(
                                          user: _currentUser!,
                                          links: links,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('Pratinjau'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Copy Link Box
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  bioUrl,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: bioUrl),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Link berhasil disalin!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.copy,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Add New Link Button (Inline)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.05,
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    'Tambah Link Baru',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // Links List
              ...links.map((link) => _buildLinkCard(link)),

              const SizedBox(height: 120), // Space for FAB & Bottom Nav
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        heroTag: 'add_link_fab',
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLinkCard(LinkBioModel link) {
    IconData icon;
    switch (link.icon) {
      case 'instagram':
        icon = Icons.camera_alt_outlined;
        break;
      case 'whatsapp':
        icon = Icons.chat_bubble_outline;
        break;
      case 'facebook':
        icon = Icons.facebook;
        break;
      case 'twitter':
        icon = Icons.alternate_email;
        break;
      case 'store':
        icon = Icons.storefront;
        break;
      case 'book':
        icon = Icons.book_outlined;
        break;
      default:
        icon = Icons.language;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          link.label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          link.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: link.isActive,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (val) => _toggleActive(link, val),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
              onSelected: (val) {
                if (val == 'edit') _showAddEditDialog(link);
                if (val == 'delete') _deleteLink(link.id);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
