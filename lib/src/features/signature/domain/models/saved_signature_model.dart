import 'dart:convert';
import 'dart:typed_data';

/// Model entitas tanda tangan digital tersimpan di Bank Tanda Tangan
class SavedSignatureModel {
  final String id;
  final String name;
  final String base64Png;
  final DateTime createdAt;

  const SavedSignatureModel({
    required this.id,
    required this.name,
    required this.base64Png,
    required this.createdAt,
  });

  Uint8List get bytes => base64Decode(base64Png);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'base64Png': base64Png,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SavedSignatureModel.fromMap(Map<String, dynamic> map) {
    return SavedSignatureModel(
      id: map['id'] as String,
      name: map['name'] as String,
      base64Png: map['base64Png'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedSignatureModel.fromJson(String source) =>
      SavedSignatureModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
