import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/saved_student_profile_model.dart';

final studentProfileServiceProvider = Provider<StudentProfileService>((ref) {
  return StudentProfileService();
});

class StudentProfileService {
  static const _keyProfileList = 'saved_student_profiles_list';
  static const _keyActiveProfileId = 'active_student_profile_id';

  Future<List<SavedStudentProfileModel>> getProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_keyProfileList);

    if (jsonList == null || jsonList.isEmpty) {
      // Buat default profil pertama jika belum ada
      final defaultProfile = const SavedStudentProfileModel(
        id: 'profile_allam_default',
        nama: 'Allam Permata Putra',
        nim: '260558302016',
        prodi: 'TRPL',
        noHp: '',
        isDefault: true,
      );
      await saveProfile(defaultProfile);
      return [defaultProfile];
    }

    return jsonList.map((item) {
      try {
        return SavedStudentProfileModel.fromJson(item);
      } catch (_) {
        return null;
      }
    }).whereType<SavedStudentProfileModel>().toList();
  }

  Future<SavedStudentProfileModel?> getActiveProfile() async {
    final profiles = await getProfiles();
    if (profiles.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final activeId = prefs.getString(_keyActiveProfileId);

    if (activeId != null) {
      final found = profiles.where((p) => p.id == activeId).toList();
      if (found.isNotEmpty) return found.first;
    }

    final defaultProfile = profiles.where((p) => p.isDefault).toList();
    if (defaultProfile.isNotEmpty) return defaultProfile.first;

    return profiles.first;
  }

  Future<void> setActiveProfileId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveProfileId, id);
  }

  Future<void> saveProfile(SavedStudentProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();

    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    final jsonList = profiles.map((p) => p.toJson()).toList();
    await prefs.setStringList(_keyProfileList, jsonList);
  }

  Future<void> deleteProfile(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = await getProfiles();

    profiles.removeWhere((p) => p.id == id);
    final jsonList = profiles.map((p) => p.toJson()).toList();
    await prefs.setStringList(_keyProfileList, jsonList);
  }
}
