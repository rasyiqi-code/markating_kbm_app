class LinkBioModel {
  final String id;
  final String userId;
  final String label;
  final String url;
  final String icon; // e.g., 'whatsapp', 'instagram', 'web', 'other'
  final bool isActive;
  final DateTime createdAt;

  LinkBioModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.url,
    this.icon = 'web',
    this.isActive = true,
    required this.createdAt,
  });

  factory LinkBioModel.fromJson(Map<String, dynamic> json, String id) {
    return LinkBioModel(
      id: id,
      userId: json['user_id'] ?? '',
      label: json['label'] ?? '',
      url: json['url'] ?? '',
      icon: json['icon'] ?? 'web',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'url': url,
      'icon': icon,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LinkBioModel copyWith({
    String? label,
    String? url,
    String? icon,
    bool? isActive,
  }) {
    return LinkBioModel(
      id: id,
      userId: userId,
      label: label ?? this.label,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
