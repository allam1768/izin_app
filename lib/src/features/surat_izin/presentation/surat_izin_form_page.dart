import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/pencil_signature_pad.dart';
import '../../dashboard/presentation/dashboard_providers.dart';
import '../../dashboard/presentation/dashboard_utils.dart';
import '../domain/models/surat_izin_model.dart';
import 'surat_izin_preview_page.dart';
import '../../license/application/license_service.dart';
import '../../license/presentation/activation_modal.dart';
import '../../app_update/presentation/app_update_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../signature/domain/models/saved_signature_model.dart';
import '../../signature/application/signature_vault_service.dart';
import '../../signature/presentation/signature_vault_modal.dart';
import '../../student_profile/domain/models/saved_student_profile_model.dart';
import '../../student_profile/application/student_profile_service.dart';
import '../../student_profile/presentation/profile_manage_dialog.dart';

/// Halaman Formulir Pengajuan Surat Izin Tidak Masuk Kelas Politeknik IDN
class SuratIzinFormPage extends ConsumerStatefulWidget {
  final String? initialNama;
  final String? initialNim;
  final String? initialProdi;
  final String? initialMatkul;
  final String? initialMentor;
  final DateTime? initialTanggal;

  const SuratIzinFormPage({
    super.key,
    this.initialNama,
    this.initialNim,
    this.initialProdi,
    this.initialMatkul,
    this.initialMentor,
    this.initialTanggal,
  });

  @override
  ConsumerState<SuratIzinFormPage> createState() => _SuratIzinFormPageState();
}

class _SuratIzinFormPageState extends ConsumerState<SuratIzinFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _nimController;
  late final TextEditingController _jurusanController;
  late final TextEditingController _noHpController;
  late final TextEditingController _matkulController;
  late final TextEditingController _keteranganController;
  late final TextEditingController _mentorController;
  late final TextEditingController _newSigLabelController;

  late DateTime _mulaiIzin;
  late DateTime _akhirIzin;
  JenisIzin _jenisIzin = JenisIzin.sakitDiRumah;

  late final PencilSignatureController _signatureController;
  Uint8List? _suratDokterBytes;
  final ImagePicker _picker = ImagePicker();

  // Signature Vault State
  List<SavedSignatureModel> _vaultSignatures = [];
  SavedSignatureModel? _selectedSavedSignature;
  bool _useSavedSignature = false;
  bool _saveNewSignatureToVault = true;

  // Active Student Profile
  SavedStudentProfileModel? _activeProfile;

  static const _prefPhoneKey = 'saved_surat_izin_no_hp';

  @override
  void initState() {
    super.initState();
    final today = widget.initialTanggal ?? DateTime.now();
    _mulaiIzin = DateTime(today.year, today.month, today.day);
    _akhirIzin = DateTime(today.year, today.month, today.day);

    _namaController = TextEditingController(text: widget.initialNama ?? '');
    _nimController = TextEditingController(text: widget.initialNim ?? '');
    _jurusanController = TextEditingController(text: widget.initialProdi ?? '');
    _noHpController = TextEditingController();
    _matkulController = TextEditingController(text: widget.initialMatkul ?? '');
    _keteranganController = TextEditingController();
    _mentorController = TextEditingController(text: widget.initialMentor ?? '');
    _newSigLabelController = TextEditingController();

    _signatureController = PencilSignatureController(
      penColor: Colors.black,
      minStrokeWidth: 1.5,
      maxStrokeWidth: 4.2,
    );

    _loadInitialProfileAndSignatures();
    _loadSavedPhone();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appUpdateControllerProvider).checkOnStartup(context);
      }
    });
  }

  Future<void> _loadInitialProfileAndSignatures() async {
    final profileService = ref.read(studentProfileServiceProvider);
    final vaultService = ref.read(signatureVaultServiceProvider);

    final profile = await profileService.getActiveProfile();
    final sigs = await vaultService.getSignatures();

    if (mounted) {
      setState(() {
        _activeProfile = profile;
        _vaultSignatures = sigs;

        // Auto-fill jika kosong
        if (_namaController.text.isEmpty && profile != null) {
          _namaController.text = profile.nama;
        }
        if (_nimController.text.isEmpty && profile != null) {
          _nimController.text = profile.nim;
        }
        if (_jurusanController.text.isEmpty && profile != null) {
          _jurusanController.text = profile.prodi;
        }
        if (_noHpController.text.isEmpty && profile != null && profile.noHp.isNotEmpty) {
          _noHpController.text = profile.noHp;
        }

        // Default ke TTD tersimpan jika tersedia
        if (sigs.isNotEmpty) {
          _useSavedSignature = true;
          // Cari TTD yang cocok dengan nama profil, jika tidak ada pakai yang pertama
          final matched = sigs.where((s) =>
              s.name.toLowerCase().contains(_namaController.text.toLowerCase()) ||
              _namaController.text.toLowerCase().contains(s.name.toLowerCase()));
          _selectedSavedSignature = matched.isNotEmpty ? matched.first : sigs.first;
        } else {
          _useSavedSignature = false;
        }

        _newSigLabelController.text = 'TTD ${_namaController.text.trim()}';
      });
    }
  }

  Future<void> _loadSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_prefPhoneKey);
    if (savedPhone != null && savedPhone.isNotEmpty && mounted) {
      if (_noHpController.text.isEmpty) {
        _noHpController.text = savedPhone;
      }
    }
  }

  Future<void> _savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefPhoneKey, phone.trim());
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nimController.dispose();
    _jurusanController.dispose();
    _noHpController.dispose();
    _matkulController.dispose();
    _keteranganController.dispose();
    _mentorController.dispose();
    _newSigLabelController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  int get _durasiHari {
    final start = DateTime(_mulaiIzin.year, _mulaiIzin.month, _mulaiIzin.day);
    final end = DateTime(_akhirIzin.year, _akhirIzin.month, _akhirIzin.day);
    final diff = end.difference(start).inDays;
    return (diff >= 0 ? diff : 0) + 1;
  }

  Future<void> _pickMulaiTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mulaiIzin,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _mulaiIzin = picked;
        if (_akhirIzin.isBefore(_mulaiIzin)) {
          _akhirIzin = _mulaiIzin;
        }
      });
    }
  }

  Future<void> _pickAkhirTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _akhirIzin.isBefore(_mulaiIzin) ? _mulaiIzin : _akhirIzin,
      firstDate: _mulaiIzin,
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _akhirIzin = picked;
      });
    }
  }

  Future<void> _pickSuratDokter(ImageSource source) async {
    try {
      final xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (xFile != null) {
        final bytes = await xFile.readAsBytes();
        setState(() {
          _suratDokterBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Uint8List? signatureBytes;

    if (_useSavedSignature) {
      if (_selectedSavedSignature == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih salah satu tanda tangan tersimpan.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      signatureBytes = _selectedSavedSignature!.bytes;
    } else {
      if (_signatureController.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon bubuhkan tanda tangan Anda terlebih dahulu.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      signatureBytes = await _signatureController.toPngBytes();

      // Simpan ke bank jika dicentang
      if (_saveNewSignatureToVault && signatureBytes != null) {
        final label = _newSigLabelController.text.trim().isNotEmpty
            ? _newSigLabelController.text.trim()
            : 'TTD ${_namaController.text.trim()}';
        await ref.read(signatureVaultServiceProvider).saveSignature(
              name: label,
              pngBytes: signatureBytes,
            );
      }
    }

    await _savePhone(_noHpController.text);

    // Simpan juga ke profil aktif jika ada perubahan nomor HP
    if (_activeProfile != null) {
      final updatedProfile = _activeProfile!.copyWith(
        nama: _namaController.text.trim(),
        nim: _nimController.text.trim(),
        prodi: _jurusanController.text.trim(),
        noHp: _noHpController.text.trim(),
      );
      await ref.read(studentProfileServiceProvider).saveProfile(updatedProfile);
    }

    final model = SuratIzinModel(
      namaLengkap: _namaController.text.trim(),
      nim: _nimController.text.trim(),
      jurusanKelas: _jurusanController.text.trim(),
      mulaiIzin: _mulaiIzin,
      akhirIzin: _akhirIzin,
      noHp: _noHpController.text.trim(),
      jenisIzin: _jenisIzin,
      keterangan: _keteranganController.text.trim(),
      namaMatkul: _matkulController.text.trim(),
      namaMentor: _mentorController.text.trim(),
      tandaTanganBytes: signatureBytes,
      suratDokterBytes: _suratDokterBytes,
    );

    if (!mounted) return;

    // Gerbang Lisensi Pro
    final isPro = ref.read(licenseControllerProvider).valueOrNull ?? false;
    if (!isPro) {
      final activated = await ActivationModal.show(context);
      if (activated != true) {
        return;
      }
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SuratIzinPreviewPage(model: model)),
    );
  }

  void _switchProfile(SavedStudentProfileModel profile) {
    setState(() {
      _activeProfile = profile;
      _namaController.text = profile.nama;
      _nimController.text = profile.nim;
      _jurusanController.text = profile.prodi;
      if (profile.noHp.isNotEmpty) {
        _noHpController.text = profile.noHp;
      }
      _newSigLabelController.text = 'TTD ${profile.nama}';

      // Cari apakah ada TTD yang cocok dengan nama profil ini
      final matched = _vaultSignatures.where((s) =>
          s.name.toLowerCase().contains(profile.nama.toLowerCase()) ||
          profile.nama.toLowerCase().contains(s.name.toLowerCase()));
      if (matched.isNotEmpty) {
        _selectedSavedSignature = matched.first;
        _useSavedSignature = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardMahasiswaProvider);
    final kelasAsync = ref.watch(kelasHarianProvider);
    final profile = DashboardUtils.extractUserProfile(
      dashboardAsync.valueOrNull,
      kelasAsync.valueOrNull,
    );

    if (_namaController.text.isEmpty && profile.name != 'Mahasiswa') {
      _namaController.text = profile.name;
    }
    if (_nimController.text.isEmpty && profile.nim.isNotEmpty) {
      _nimController.text = profile.nim;
    }
    if (_jurusanController.text.isEmpty && profile.prodi != '-') {
      _jurusanController.text = profile.kelas != '-'
          ? '${profile.prodi} - ${profile.kelas}'
          : profile.prodi;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1F81FF),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: SvgPicture.asset(
                'assets/icon/idn_ic.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            const Text(
              'Formulir Surat Izin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Cek Pembaruan Aplikasi',
            onPressed: () {
              ref.read(appUpdateControllerProvider).checkManually(context);
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          children: [
            // Banner Info Switch Profil Pemohon
            _buildProfileSelectorBanner(),

            SizedBox(height: 14.h),

            // Card 1: Biodata Mahasiswa
            _buildSectionHeader('Biodata Mahasiswa', Icons.person_rounded),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap Mahasiswa',
                      hint: 'Contoh: Allam Permata Putra',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _nimController,
                      label: 'Nomor Induk Mahasiswa (NIM)',
                      hint: 'Contoh: 260558302016',
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'NIM wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _jurusanController,
                      label: 'Jurusan & Kelas',
                      hint: 'Contoh: Teknik Informatika',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Jurusan wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _noHpController,
                      label: 'No. Handphone / WhatsApp',
                      hint: 'Contoh: 081234567890',
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'No. HP wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Card 2: Detail Mapel & Permohonan Izin
            _buildSectionHeader(
              'Detail Mata Pelajaran & Izin',
              Icons.event_note_rounded,
            ),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _matkulController,
                      label: 'Mata Kuliah / Sesi Kelas',
                      hint: 'Contoh: Bahasa Inggris / Diniyah / Tahfidz',
                      prefixIcon: Icons.menu_book_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Mata kuliah wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _mentorController,
                      label: 'Nama Mentor / Asisten Dosen Tujuan',
                      hint: 'Contoh: Muhammad Rafi Ar-Rasyid / Khoirul Umam',
                      prefixIcon: Icons.person_pin_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama mentor/asdos wajib diisi'
                          : null,
                    ),
                    SizedBox(height: 14.h),

                    // Date pickers
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickMulaiTanggal,
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mulai Izin',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14.w,
                                        color: const Color(0xFF1F81FF),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '${_mulaiIzin.day}/${_mulaiIzin.month}/${_mulaiIzin.year}',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: InkWell(
                            onTap: _pickAkhirTanggal,
                            borderRadius: BorderRadius.circular(10.r),
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Akhir Izin',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14.w,
                                        color: const Color(0xFF1F81FF),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        '${_akhirIzin.day}/${_akhirIzin.month}/${_akhirIzin.year}',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Durasi: $_durasiHari Hari',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F81FF),
                          ),
                        ),
                        Row(
                          children: [
                            _buildQuickDateChip('Hari Ini', () {
                              final now = DateTime.now();
                              setState(() {
                                _mulaiIzin = DateTime(now.year, now.month, now.day);
                                _akhirIzin = DateTime(now.year, now.month, now.day);
                              });
                            }),
                            SizedBox(width: 6.w),
                            _buildQuickDateChip('Besok', () {
                              final tomorrow =
                                  DateTime.now().add(const Duration(days: 1));
                              setState(() {
                                _mulaiIzin = DateTime(
                                    tomorrow.year, tomorrow.month, tomorrow.day);
                                _akhirIzin = DateTime(
                                    tomorrow.year, tomorrow.month, tomorrow.day);
                              });
                            }),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Keterangan Izin Radio
                    Text(
                      'Kategori Izin (Formulir Resmi)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 8.w,
                      children: JenisIzin.values.map((item) {
                        final isSelected = _jenisIzin == item;
                        return ChoiceChip(
                          label: Text(item.label),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDBEAFE),
                          labelStyle: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF4B5563),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _jenisIzin = item);
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 12.h),

                    _buildTextField(
                      controller: _keteranganController,
                      label: 'Detail Alasan / Keterangan',
                      hint: 'Contoh: Sakit Demam dan Flu / Keperluan Keluarga',
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Alasan izin wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Card 3: Tanda Tangan Mahasiswa (Multi-Signature Bank)
            _buildSignatureSection(),

            SizedBox(height: 16.h),

            // Card 4: Lampiran Surat Dokter (Opsional)
            _buildDoctorAttachmentCard(),

            SizedBox(height: 24.h),

            // Tombol Generate PDF
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F81FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                'Pratinjau Surat Izin (PDF)',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              onPressed: _submitForm,
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSelectorBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: const Color(0xFF1F81FF),
            foregroundColor: Colors.white,
            child: Text(
              _namaController.text.isNotEmpty
                  ? _namaController.text[0].toUpperCase()
                  : 'M',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemohon: ${_namaController.text.isNotEmpty ? _namaController.text : "Pilih Mahasiswa"}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
                Text(
                  'NIM: ${_nimController.text.isNotEmpty ? _nimController.text : "-"}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
              ),
            ),
            icon: const Icon(Icons.people_outline, size: 15, color: Color(0xFF1F81FF)),
            label: Text(
              'Ganti Teman',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F81FF),
              ),
            ),
            onPressed: () {
              ProfileManageDialog.show(
                context,
                profileService: ref.read(studentProfileServiceProvider),
                onSelect: _switchProfile,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.draw_rounded,
                        size: 16.sp, color: const Color(0xFF1F81FF)),
                    SizedBox(width: 6.w),
                    Text(
                      'Tanda Tangan Mahasiswa',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  ),
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 14),
                  label: Text('Bank TTD', style: TextStyle(fontSize: 11.sp)),
                  onPressed: () {
                    SignatureVaultModal.show(
                      context,
                      vaultService: ref.read(signatureVaultServiceProvider),
                      initialOwnerName: _namaController.text,
                    ).then((selected) async {
                      final sigs = await ref
                          .read(signatureVaultServiceProvider)
                          .getSignatures();
                      setState(() {
                        _vaultSignatures = sigs;
                        if (selected != null) {
                          _selectedSavedSignature = selected;
                          _useSavedSignature = true;
                        }
                      });
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Tab / Pilihan: Gunakan Tersimpan ATAU Coret Baru
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.all(3.w),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_vaultSignatures.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Belum ada TTD tersimpan. Coret tanda tangan baru di bawah!'),
                            ),
                          );
                        } else {
                          setState(() => _useSavedSignature = true);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          color: _useSavedSignature
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: _useSavedSignature
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14.w,
                              color: _useSavedSignature
                                  ? const Color(0xFF1F81FF)
                                  : Colors.grey.shade600,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Pilih TTD Tersimpan',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: _useSavedSignature
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _useSavedSignature
                                    ? const Color(0xFF1F81FF)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _useSavedSignature = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          color: !_useSavedSignature
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: !_useSavedSignature
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14.w,
                              color: !_useSavedSignature
                                  ? const Color(0xFF1F81FF)
                                  : Colors.grey.shade600,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Coret TTD Baru',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: !_useSavedSignature
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: !_useSavedSignature
                                    ? const Color(0xFF1F81FF)
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            // Konten TTD sesuai mode
            if (_useSavedSignature) ...[
              if (_vaultSignatures.isEmpty)
                Container(
                  padding: EdgeInsets.all(16.w),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        'Belum ada TTD tersimpan',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () =>
                            setState(() => _useSavedSignature = false),
                        child: const Text('Buat Tanda Tangan Sekarang'),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(
                  'Ketuk tanda tangan yang ingin digunakan:',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  height: 95.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _vaultSignatures.length,
                    separatorBuilder: (_, index) => SizedBox(width: 10.w),
                    itemBuilder: (ctx, idx) {
                      final sig = _vaultSignatures[idx];
                      final isSelected = _selectedSavedSignature?.id == sig.id;

                      return InkWell(
                        onTap: () {
                          setState(() => _selectedSavedSignature = sig);
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: 130.w,
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1F81FF).withValues(alpha: 0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF1F81FF)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Image.memory(
                                  sig.bytes,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 12.w,
                                      color: const Color(0xFF1F81FF),
                                    ),
                                  if (isSelected) SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      sig.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? const Color(0xFF1F81FF)
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              // Mode Coret Tanda Tangan Baru
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.brush_rounded,
                          size: 12.sp,
                          color: const Color(0xFF1D4ED8),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Pensil Dinamis (Tinta Hitam)',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _signatureController,
                    builder: (context, _) {
                      final hasStrokes = _signatureController.isNotEmpty;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo_rounded, size: 18),
                            tooltip: 'Urungkan',
                            onPressed: hasStrokes
                                ? () => _signatureController.undo()
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.redAccent),
                            tooltip: 'Bersihkan',
                            onPressed: hasStrokes
                                ? () => _signatureController.clear()
                                : null,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Container(
                height: 160.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: PencilSignaturePad(
                    controller: _signatureController,
                    backgroundColor: Colors.white,
                    placeholderText:
                        'Goreskan tanda tangan tinta hitam Anda di sini...',
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Checkbox simpan ke bank
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _saveNewSignatureToVault,
                          activeColor: const Color(0xFF1F81FF),
                          onChanged: (val) {
                            setState(
                                () => _saveNewSignatureToVault = val ?? false);
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Simpan TTD ini ke Bank Tanda Tangan untuk dipakai lagi nanti',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_saveNewSignatureToVault)
                      Padding(
                        padding: EdgeInsets.only(
                            left: 12.w, right: 12.w, bottom: 8.h),
                        child: TextField(
                          controller: _newSigLabelController,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Nama Label TTD',
                            hintText: 'Contoh: TTD Allam, TTD Teman A',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorAttachmentCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: BorderSide(
          color: _suratDokterBytes != null
              ? const Color(0xFFBFDBFE)
              : Colors.grey.shade200,
        ),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _suratDokterBytes != null,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: _suratDokterBytes != null
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              _suratDokterBytes != null
                  ? Icons.check_circle_rounded
                  : Icons.medical_services_outlined,
              color: _suratDokterBytes != null
                  ? const Color(0xFF1F81FF)
                  : const Color(0xFF64748B),
              size: 20.sp,
            ),
          ),
          title: Text(
            'Lampiran Surat Dokter',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            _suratDokterBytes != null
                ? '1 foto terlampir (akan jadi halaman ke-2 PDF)'
                : 'Opsional • Buka jika ingin menyertakan surat dokter',
            style: TextStyle(
              fontSize: 10.5.sp,
              color: _suratDokterBytes != null
                  ? const Color(0xFF1F81FF)
                  : Colors.grey.shade500,
            ),
          ),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          children: [
            if (_suratDokterBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.memory(
                  _suratDokterBytes!,
                  height: 180.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 10.h),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  minimumSize: Size(double.infinity, 38.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus Lampiran Dokter'),
                onPressed: () => setState(() => _suratDokterBytes = null),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Color(0xFF1F81FF),
                      ),
                      label: Text(
                        'Kamera',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      onPressed: () => _pickSuratDokter(ImageSource.camera),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        size: 18,
                        color: Color(0xFF1F81FF),
                      ),
                      label: Text(
                        'Galeri',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      onPressed: () => _pickSuratDokter(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Lampiran otomatis digabungkan sebagai halaman ke-2 pada dokumen PDF.',
                style: TextStyle(fontSize: 10.5.sp, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: const Color(0xFF1F81FF)),
          SizedBox(width: 6.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(fontSize: 13.sp),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18.w) : null,
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        labelStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: Color(0xFF1F81FF), width: 1.5),
        ),
      ),
    );
  }
}
