import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/mapel_preset_model.dart';

final mapelPresetServiceProvider = Provider<MapelPresetService>((ref) {
  return MapelPresetService();
});

class MapelPresetService {
  static const _keyCustomPresets = 'saved_custom_mapel_presets';

  Future<List<MapelPresetModel>> getPresets() async {
    final prefs = await SharedPreferences.getInstance();
    final customJsonList = prefs.getStringList(_keyCustomPresets) ?? [];

    final customPresets = customJsonList.map((item) {
      try {
        return MapelPresetModel.fromJson(item);
      } catch (_) {
        return null;
      }
    }).whereType<MapelPresetModel>().toList();

    return [...MapelPresetModel.defaultPresets, ...customPresets];
  }

  Future<void> addCustomPreset({
    required String namaMapel,
    required String namaMentor,
    int? iconCodePoint,
    int? colorValue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final customJsonList = prefs.getStringList(_keyCustomPresets) ?? [];

    final newPreset = MapelPresetModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      namaMapel: namaMapel.trim(),
      namaMentor: namaMentor.trim(),
      iconCodePoint: iconCodePoint ?? 0xe115, // Icons.class_ / school
      colorValue: colorValue ?? 0xFF455A64,
      isDefault: false,
    );

    customJsonList.add(newPreset.toJson());
    await prefs.setStringList(_keyCustomPresets, customJsonList);
  }

  Future<void> deleteCustomPreset(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final customJsonList = prefs.getStringList(_keyCustomPresets) ?? [];

    final updated = customJsonList.where((item) {
      try {
        final decoded = json.decode(item) as Map<String, dynamic>;
        return decoded['id'] != id;
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setStringList(_keyCustomPresets, updated);
  }
}
