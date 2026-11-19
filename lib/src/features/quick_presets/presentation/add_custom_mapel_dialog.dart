import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../application/mapel_preset_service.dart';

class AddCustomMapelDialog extends StatefulWidget {
  final MapelPresetService presetService;
  final VoidCallback onSaved;

  const AddCustomMapelDialog({
    super.key,
    required this.presetService,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required MapelPresetService presetService,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => AddCustomMapelDialog(
        presetService: presetService,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AddCustomMapelDialog> createState() => _AddCustomMapelDialogState();
}

class _AddCustomMapelDialogState extends State<AddCustomMapelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _mapelCtrl = TextEditingController();
  final _mentorCtrl = TextEditingController();

  final List<int> _iconOptions = [
    0xe115, // school
    0xe1d7, // computer
    0xe80c, // code
    0xe3e7, // menu_book
    0xf20a, // record_voice_over
    0xe156, // build
  ];
  int _selectedIcon = 0xe115;

  final List<int> _colorOptions = [
    0xFF1F81FF, // Blue
    0xFF00897B, // Teal
    0xFF5D4037, // Brown
    0xFF7B1FA2, // Purple
    0xFFE65100, // Orange
    0xFF2E7D32, // Green
  ];
  int _selectedColor = 0xFF1F81FF;

  @override
  void dispose() {
    _mapelCtrl.dispose();
    _mentorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Row(
        children: [
          Icon(Icons.add_task_rounded, color: const Color(0xFF1F81FF), size: 22.w),
          SizedBox(width: 8.w),
          Text(
            'Tambah Mapel Baru',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat kartu shortcut baru untuk mata pelajaran atau sesi izin lainnya.',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _mapelCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Mata Pelajaran / Sesi',
                  hintText: 'Contoh: Pemrograman Mobile / Flutter',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Nama mapel wajib diisi' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _mentorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nama Mentor / Asdos / Dosen',
                  hintText: 'Contoh: Fulan, S.Kom.',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama mentor/asdos wajib diisi'
                    : null,
              ),
              SizedBox(height: 14.h),
              Text(
                'Pilih Ikon & Warna Kartu:',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _iconOptions.map((code) {
                  final isSel = _selectedIcon == code;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = code),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: isSel
                            ? Color(_selectedColor).withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(color: Color(_selectedColor), width: 2)
                            : null,
                      ),
                      child: Icon(
                        IconData(code, fontFamily: 'MaterialIcons'),
                        size: 20.w,
                        color: isSel ? Color(_selectedColor) : Colors.grey.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _colorOptions.map((clr) {
                  final isSel = _selectedColor == clr;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = clr),
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Color(clr),
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(color: Colors.black87, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F81FF),
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            await widget.presetService.addCustomPreset(
              namaMapel: _mapelCtrl.text.trim(),
              namaMentor: _mentorCtrl.text.trim(),
              iconCodePoint: _selectedIcon,
              colorValue: _selectedColor,
            );
            if (context.mounted) Navigator.pop(context);
            widget.onSaved();
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
