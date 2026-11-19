import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../domain/models/saved_student_profile_model.dart';
import '../application/student_profile_service.dart';

class ProfileManageDialog extends StatefulWidget {
  final StudentProfileService profileService;
  final Function(SavedStudentProfileModel selected) onSelect;

  const ProfileManageDialog({
    super.key,
    required this.profileService,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentProfileService profileService,
    required Function(SavedStudentProfileModel selected) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ProfileManageDialog(
        profileService: profileService,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<ProfileManageDialog> createState() => _ProfileManageDialogState();
}

class _ProfileManageDialogState extends State<ProfileManageDialog> {
  List<SavedStudentProfileModel> _profiles = [];
  SavedStudentProfileModel? _activeProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    final profiles = await widget.profileService.getProfiles();
    final active = await widget.profileService.getActiveProfile();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _activeProfile = active;
        _isLoading = false;
      });
    }
  }

  void _showAddEditProfileModal([SavedStudentProfileModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.nama ?? '');
    final nimCtrl = TextEditingController(text: existing?.nim ?? '');
    final allowedProdis = ['TRPL', 'TRKJ', 'TRMG'];
    String selectedProdi = allowedProdis.contains(existing?.prodi)
        ? existing!.prodi
        : 'TRPL';
    final phoneCtrl = TextEditingController(text: existing?.noHp ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Text(
            existing == null ? 'Tambah Profil Teman / Diri' : 'Ubah Profil',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap Mahasiswa',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: nimCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'NIM',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'NIM wajib diisi' : null,
                  ),
                  SizedBox(height: 12.h),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProdi,
                    decoration: const InputDecoration(
                      labelText: 'Jurusan (TRPL / TRKJ / TRMG)',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    items: allowedProdis
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedProdi = val);
                      }
                    },
                  ),
                  SizedBox(height: 12.h),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp / HP',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F81FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final newModel = SavedStudentProfileModel(
                  id: existing?.id ??
                      'profile_${DateTime.now().millisecondsSinceEpoch}',
                  nama: nameCtrl.text.trim(),
                  nim: nimCtrl.text.trim(),
                  prodi: selectedProdi,
                  noHp: phoneCtrl.text.trim(),
                  isDefault: existing?.isDefault ?? false,
                );
                await widget.profileService.saveProfile(newModel);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadProfiles();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.people_alt_rounded, color: const Color(0xFF1F81FF), size: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Pilih Profil Mahasiswa',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF1F81FF)),
                tooltip: 'Tambah Teman Baru',
                onPressed: () => _showAddEditProfileModal(),
              ),
            ],
          ),
          Text(
            'Pilih siapa yang mengajukan izin agar formulir otomatis terisi.',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 12.h),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ))
          else
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _profiles.length,
                separatorBuilder: (_, index) => SizedBox(height: 8.h),
                itemBuilder: (ctx, idx) {
                  final p = _profiles[idx];
                  final isSelected = p.id == _activeProfile?.id;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1F81FF).withValues(alpha: 0.08)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1F81FF)
                            : Colors.grey.shade200,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 4.h,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? const Color(0xFF1F81FF)
                            : Colors.grey.shade200,
                        foregroundColor:
                            isSelected ? Colors.white : Colors.black87,
                        child: Text(
                          p.nama.isNotEmpty ? p.nama[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        p.nama,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'NIM: ${p.nim} • ${p.prodi}',
                        style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF1F81FF)),
                          PopupMenuButton<String>(
                            onSelected: (val) async {
                              if (val == 'edit') {
                                _showAddEditProfileModal(p);
                              } else if (val == 'delete') {
                                await widget.profileService.deleteProfile(p.id);
                                _loadProfiles();
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Ubah'),
                              ),
                              if (_profiles.length > 1)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus',
                                      style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await widget.profileService.setActiveProfileId(p.id);
                        widget.onSelect(p);
                        navigator.pop();
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
