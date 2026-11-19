import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../app_update/presentation/app_update_controller.dart';
import '../../quick_presets/domain/models/mapel_preset_model.dart';
import '../../quick_presets/application/mapel_preset_service.dart';
import '../../quick_presets/presentation/add_custom_mapel_dialog.dart';
import '../../signature/application/signature_vault_service.dart';
import '../../signature/presentation/signature_vault_modal.dart';
import '../../student_profile/domain/models/saved_student_profile_model.dart';
import '../../student_profile/application/student_profile_service.dart';
import '../../student_profile/presentation/profile_manage_dialog.dart';
import '../../surat_izin/presentation/surat_izin_form_page.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  SavedStudentProfileModel? _activeProfile;
  List<MapelPresetModel> _presets = [];
  int _signatureCount = 0;
  String _appVersion = 'v1.1.0';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appUpdateControllerProvider).checkOnStartup(context);
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    final profileService = ref.read(studentProfileServiceProvider);
    final presetService = ref.read(mapelPresetServiceProvider);
    final vaultService = ref.read(signatureVaultServiceProvider);

    final profile = await profileService.getActiveProfile();
    final presets = await presetService.getPresets();
    final signatures = await vaultService.getSignatures();

    String version = 'v1.1.0';
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (pkg.version.isNotEmpty) {
        version = 'v${pkg.version}';
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _activeProfile = profile;
        _presets = presets;
        _signatureCount = signatures.length;
        _appVersion = version;
        _isLoading = false;
      });
    }
  }

  void _openForm({
    String? initialMatkul,
    String? initialMentor,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SuratIzinFormPage(
          initialNama: _activeProfile?.nama,
          initialNim: _activeProfile?.nim,
          initialProdi: _activeProfile?.prodi,
          initialMatkul: initialMatkul,
          initialMentor: initialMentor,
        ),
      ),
    ).then((_) => _loadInitialData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Surat Izin Mahasiswa',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // 1. KARTU PROFIL MAHASISWA (CLEAN TANPA LABEL)
                    // ==========================================
                    _buildActiveProfileCard(),

                    SizedBox(height: 16.h),

                    // ==========================================
                    // 2. KOTAK-KOTAK IZIN MAPEL & TAMBAH MAPEL
                    // ==========================================
                    _buildPresetsGrid(),

                    SizedBox(height: 18.h),

                    // ==========================================
                    // 3. SEKSI KELOLA CEPAT
                    // ==========================================
                    Text(
                      'Kelola Cepat',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildToolCard(
                            icon: Icons.draw_rounded,
                            iconColor: const Color(0xFF1F81FF),
                            title: 'Bank TTD',
                            subtitle: '$_signatureCount tersimpan',
                            onTap: () {
                              SignatureVaultModal.show(
                                context,
                                vaultService:
                                    ref.read(signatureVaultServiceProvider),
                                initialOwnerName: _activeProfile?.nama,
                              ).then((_) => _loadInitialData());
                            },
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildToolCard(
                            icon: Icons.people_alt_rounded,
                            iconColor: const Color(0xFF1F81FF),
                            title: 'Daftar Teman',
                            subtitle: 'Ganti & tambah profil',
                            onTap: () {
                              ProfileManageDialog.show(
                                context,
                                profileService:
                                    ref.read(studentProfileServiceProvider),
                                onSelect: (selected) {
                                  setState(() => _activeProfile = selected);
                                },
                              ).then((_) => _loadInitialData());
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 36.h),

                    // ==========================================
                    // 4. COPYRIGHT PUTRAALABS & VERSI APLIKASI
                    // ==========================================
                    Center(
                      child: Text(
                        '© 2026 putraalabs • $_appVersion',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.all(14.w),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22.r,
            backgroundColor: const Color(0xFF1F81FF).withValues(alpha: 0.1),
            child: Text(
              _activeProfile?.nama.isNotEmpty == true
                  ? _activeProfile!.nama[0].toUpperCase()
                  : 'A',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F81FF),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _activeProfile?.nama ?? 'Belum ada nama',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${_activeProfile?.nim ?? '-'} • ${_activeProfile?.prodi ?? 'TRPL'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () {
              ProfileManageDialog.show(
                context,
                profileService: ref.read(studentProfileServiceProvider),
                onSelect: (selected) {
                  setState(() => _activeProfile = selected);
                },
              ).then((_) => _loadInitialData());
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16.w, color: Colors.black87),
                SizedBox(width: 4.w),
                Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalCount = _presets.length + 1; // +1 untuk Tambah Mapel
        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: totalCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 1.18,
          ),
          itemBuilder: (ctx, idx) {
            if (idx < _presets.length) {
              return _buildMapelCard(_presets[idx]);
            } else {
              return _buildAddMapelCard();
            }
          },
        );
      },
    );
  }

  Widget _buildAddMapelCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.2,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            AddCustomMapelDialog.show(
              context,
              presetService: ref.read(mapelPresetServiceProvider),
              onSaved: _loadInitialData,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, size: 18.w, color: Colors.black87),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Tambah Mapel',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Matkul IT / Dosen lain',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapelCard(MapelPresetModel preset) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            _openForm(
              initialMatkul: preset.namaMapel,
              initialMentor: preset.namaMentor,
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.all(7.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F81FF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        preset.icon,
                        color: const Color(0xFF1F81FF),
                        size: 18.w,
                      ),
                    ),
                    if (!preset.isDefault)
                      InkWell(
                        onTap: () async {
                          await ref
                              .read(mapelPresetServiceProvider)
                              .deleteCustomPreset(preset.id);
                          _loadInitialData();
                        },
                        child: Icon(
                          Icons.close,
                          size: 16.w,
                          color: Colors.grey.shade400,
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'Utama',
                          style: TextStyle(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.namaMapel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      preset.namaMentor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Ajukan Izin',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F81FF),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12.w,
                      color: const Color(0xFF1F81FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20.w),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
