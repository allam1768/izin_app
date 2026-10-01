/// Model entitas profil mahasiswa untuk form surat izin
class UserProfileModel {
  final String name;
  final String nim;
  final String prodi;
  final String kelas;

  const UserProfileModel({
    required this.name,
    required this.nim,
    required this.prodi,
    required this.kelas,
  });

  factory UserProfileModel.empty() {
    return const UserProfileModel(
      name: 'Mahasiswa',
      nim: '',
      prodi: '-',
      kelas: '-',
    );
  }
}
