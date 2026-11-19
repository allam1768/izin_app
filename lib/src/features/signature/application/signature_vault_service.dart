import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/saved_signature_model.dart';

final signatureVaultServiceProvider = Provider<SignatureVaultService>((ref) {
  return SignatureVaultService();
});

class SignatureVaultService {
  static const _keySignatureList = 'saved_signature_vault_list';

  Future<List<SavedSignatureModel>> getSignatures() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keySignatureList) ?? [];

    return jsonList.map((item) {
      try {
        return SavedSignatureModel.fromJson(item);
      } catch (_) {
        return null;
      }
    }).whereType<SavedSignatureModel>().toList();
  }

  Future<SavedSignatureModel> saveSignature({
    required String name,
    required Uint8List pngBytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keySignatureList) ?? [];

    final base64Str = base64Encode(pngBytes);
    final newModel = SavedSignatureModel(
      id: 'sig_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Tanda Tangan' : name.trim(),
      base64Png: base64Str,
      createdAt: DateTime.now(),
    );

    jsonList.insert(0, newModel.toJson());
    await prefs.setStringList(_keySignatureList, jsonList);
    return newModel;
  }

  Future<void> deleteSignature(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keySignatureList) ?? [];

    final updated = jsonList.where((item) {
      try {
        final decoded = json.decode(item) as Map<String, dynamic>;
        return decoded['id'] != id;
      } catch (_) {
        return false;
      }
    }).toList();

    await prefs.setStringList(_keySignatureList, updated);
  }
}
