import 'dart:convert';

/// Model data profil mahasiswa yang tersimpan di HP
class SavedStudentProfileModel {
  final String id;
  final String nama;
  final String nim;
  final String prodi;
  final String noHp;
  final bool isDefault;

  const SavedStudentProfileModel({
    required this.id,
    required this.nama,
    required this.nim,
    required this.prodi,
    required this.noHp,
    this.isDefault = false,
  });

  SavedStudentProfileModel copyWith({
    String? id,
    String? nama,
    String? nim,
    String? prodi,
    String? noHp,
    bool? isDefault,
  }) {
    return SavedStudentProfileModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      nim: nim ?? this.nim,
      prodi: prodi ?? this.prodi,
      noHp: noHp ?? this.noHp,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nim': nim,
      'prodi': prodi,
      'noHp': noHp,
      'isDefault': isDefault,
    };
  }

  factory SavedStudentProfileModel.fromMap(Map<String, dynamic> map) {
    return SavedStudentProfileModel(
      id: map['id'] as String,
      nama: map['nama'] as String,
      nim: map['nim'] as String,
      prodi: map['prodi'] as String,
      noHp: map['noHp'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedStudentProfileModel.fromJson(String source) =>
      SavedStudentProfileModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
