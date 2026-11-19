import 'dart:convert';
import 'package:flutter/material.dart';

/// Model kartu preset mata pelajaran dan mentor tujuan
/// Mematuhi aturan desain: 100% Solid Flat, Unifikasi Brand Blue (#1F81FF) & Slate, no-gradient, no-emoji.
class MapelPresetModel {
  final String id;
  final String namaMapel;
  final String namaMentor;
  final int iconCodePoint;
  final int colorValue;
  final bool isDefault;

  const MapelPresetModel({
    required this.id,
    required this.namaMapel,
    required this.namaMentor,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'namaMapel': namaMapel,
      'namaMentor': namaMentor,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isDefault': isDefault,
    };
  }

  factory MapelPresetModel.fromMap(Map<String, dynamic> map) {
    return MapelPresetModel(
      id: map['id'] as String,
      namaMapel: map['namaMapel'] as String,
      namaMentor: map['namaMentor'] as String,
      iconCodePoint: map['iconCodePoint'] as int? ?? Icons.school_rounded.codePoint,
      colorValue: map['colorValue'] as int? ?? 0xFF1F81FF,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory MapelPresetModel.fromJson(String source) =>
      MapelPresetModel.fromMap(json.decode(source) as Map<String, dynamic>);

  static List<MapelPresetModel> get defaultPresets => [
        const MapelPresetModel(
          id: 'preset_inggris',
          namaMapel: 'Bahasa Inggris',
          namaMentor: 'Muhammad Rafi Ar-Rasyid',
          iconCodePoint: 0xf05a1, // Icons.translate_rounded
          colorValue: 0xFF1F81FF, // Brand Blue
          isDefault: true,
        ),
        const MapelPresetModel(
          id: 'preset_diniyah',
          namaMapel: 'Diniyah',
          namaMentor: 'Khoirul Umam',
          iconCodePoint: 0xe3e7, // Icons.menu_book_rounded
          colorValue: 0xFF1F81FF, // Brand Blue
          isDefault: true,
        ),
        const MapelPresetModel(
          id: 'preset_tahfidz',
          namaMapel: 'Tahfidz',
          namaMentor: 'Khoirul Umam',
          iconCodePoint: 0xe934, // Icons.mosque_rounded / record_voice_over
          colorValue: 0xFF1F81FF, // Brand Blue
          isDefault: true,
        ),
      ];
}
