class DnsModel {
  final String id;
  final String name;
  final String primary;
  final String secondary;
  final bool isCustom;
  final List<String> tags;

  DnsModel({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    this.isCustom = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'primary': primary,
      'secondary': secondary,
      'isCustom': isCustom,
      'tags': tags,
    };
  }

  factory DnsModel.fromJson(Map<String, dynamic> json) {
    return DnsModel(
      id: json['id'],
      name: json['name'],
      primary: json['primary'],
      secondary: json['secondary'],
      isCustom: json['isCustom'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DnsModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
