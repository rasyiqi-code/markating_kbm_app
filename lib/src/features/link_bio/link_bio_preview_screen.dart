import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markating_kbm_app/src/core/models/link_bio_model.dart';
import 'package:markating_kbm_app/src/core/models/user_model.dart';
import 'package:markating_kbm_app/src/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkBioPreviewScreen extends StatefulWidget {
  final UserModel user;
  final List<LinkBioModel> links;
  final bool isPublicView;

  const LinkBioPreviewScreen({
    super.key,
    required this.user,
    required this.links,
    this.isPublicView = false,
  });

  @override
  State<LinkBioPreviewScreen> createState() => _LinkBioPreviewScreenState();
}

class _LinkBioPreviewScreenState extends State<LinkBioPreviewScreen> {
  // Extract special contact links for the quick action bar
  List<LinkBioModel> get _contactLinks {
    return widget.links.where((l) {
      if (!l.isActive) return false;
      final lower = l.icon.toLowerCase();
      // Assuming 'whatsapp', 'email', 'phone' or similar keywords
      return lower.contains('whatsapp') ||
          lower.contains('email') ||
          lower.contains('mail') ||
          lower.contains('call') ||
          lower.contains('phone') ||
          lower.contains('facebook');
    }).toList();
  }

  // Content links (everything else)
  List<LinkBioModel> get _contentLinks {
    // Get IDs of links already shown in contact row
    final contactIds = _contactLinks.map((l) => l.id).toSet();

    return widget.links.where((l) {
      if (!l.isActive) return false;
      // Exclude if it's already a quick contact
      if (contactIds.contains(l.id)) return false;
      return true;
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.user.name ?? widget.user.email.split('@')[0];
    const professionalTitle = 'Authorized Marketing Agent';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Premium Animated Background
          const _BackgroundDecoration(),

          // 2. Main Content
          SafeArea(
            child: Column(
              children: [
                // Nav Bar (Close Button for Preview Mode)
                if (!widget.isPublicView)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _GlassIconButton(
                          icon: Icons.close,
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // --- Profile Card Section ---
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      Color(0xFF6A11CB),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  width: 92,
                                  height: 92,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: ClipOval(
                                    child: widget.user.photoUrl != null
                                        ? Image.network(
                                            widget.user.photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Image Load Error: $error');
                                              return Center(
                                                child: Text(
                                                  displayName.isNotEmpty
                                                      ? displayName[0].toUpperCase()
                                                      : '?',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 36,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Center(
                                            child: Text(
                                              displayName.isNotEmpty
                                                  ? displayName[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.outfit(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name & Verified Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      displayName,
                                      style: GoogleFonts.outfit(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                professionalTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 24),
                              const Divider(height: 1),
                              const SizedBox(height: 24),

                              // Quick Contacts Row
                              if (_contactLinks.isNotEmpty) ...[
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  alignment: WrapAlignment.center,
                                  children: _contactLinks
                                      .map(
                                        (l) => _QuickContactButton(
                                          link: l,
                                          onTap: () => _launchUrl(l.url),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ] else
                                Text(
                                  'Connect with me below',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // --- Main Links List ---
                        ..._contentLinks.map(
                          (link) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ModernLinkButton(
                              link: link,
                              onTap: () => _launchUrl(link.url),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Branding Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Powered by KBM App',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Specific Sub-widgets for cleaner code ---

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE), // Soft base
      ),
      child: Stack(
        children: [
          // Top Right Gradient Blob
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6A11CB).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom Left Gradient Blob
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Blur filter to smooth everything out
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black87, size: 20),
        ),
      ),
    );
  }
}

class _QuickContactButton extends StatelessWidget {
  final LinkBioModel link;
  final VoidCallback onTap;

  const _QuickContactButton({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    final label = link.icon.toLowerCase();
    if (label.contains('whatsapp')) {
      icon = Icons.chat_bubble;
      color = const Color(0xFF25D366);
    } else if (label.contains('email') || label.contains('mail')) {
      icon = Icons.email;
      color = const Color(0xFFEA4335);
    } else if (label.contains('facebook')) {
      icon = Icons.facebook;
      color = const Color(0xFF1877F2);
    } else {
      icon = Icons.link;
      color = AppTheme.primaryColor;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(child: Icon(icon, color: color, size: 28)),
      ),
    );
  }
}

class _ModernLinkButton extends StatelessWidget {
  final LinkBioModel link;
  final VoidCallback onTap;

  const _ModernLinkButton({required this.link, required this.onTap});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    switch (link.icon) {
      case 'instagram':
        iconData = Icons.camera_alt_outlined;
        break;
      case 'whatsapp':
        iconData = Icons.chat_bubble_outline;
        break;
      case 'facebook':
        iconData = Icons.facebook;
        break;
      case 'twitter':
        iconData = Icons.alternate_email;
        break;
      case 'store':
        iconData = Icons.storefront;
        break;
      case 'book':
        iconData = Icons.book_outlined;
        break;
      default:
        iconData = Icons.language;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A11CB).withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(iconData, size: 22, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    link.label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
