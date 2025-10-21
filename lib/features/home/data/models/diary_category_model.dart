import 'dart:convert';

class DiaryCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const DiaryCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  DiaryCategory copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory DiaryCategory.fromMap(Map<String, dynamic> map) {
    return DiaryCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String)
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DiaryCategory.fromJson(String source) =>
      DiaryCategory.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
