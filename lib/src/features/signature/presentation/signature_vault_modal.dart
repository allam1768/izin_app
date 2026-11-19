import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../domain/models/saved_signature_model.dart';
import '../application/signature_vault_service.dart';
import '../../surat_izin/presentation/widgets/pencil_signature_pad.dart';

class SignatureVaultModal extends StatefulWidget {
  final SignatureVaultService vaultService;
  final String? initialOwnerName;
  final Function(SavedSignatureModel selected)? onSelect;

  const SignatureVaultModal({
    super.key,
    required this.vaultService,
    this.initialOwnerName,
    this.onSelect,
  });

  static Future<SavedSignatureModel?> show(
    BuildContext context, {
    required SignatureVaultService vaultService,
    String? initialOwnerName,
  }) async {
    return showModalBottomSheet<SavedSignatureModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SignatureVaultModal(
        vaultService: vaultService,
        initialOwnerName: initialOwnerName,
      ),
    );
  }

  @override
  State<SignatureVaultModal> createState() => _SignatureVaultModalState();
}

class _SignatureVaultModalState extends State<SignatureVaultModal> {
  List<SavedSignatureModel> _signatures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignatures();
  }

  Future<void> _loadSignatures() async {
    setState(() => _isLoading = true);
    final sigs = await widget.vaultService.getSignatures();
    if (mounted) {
      setState(() {
        _signatures = sigs;
        _isLoading = false;
      });
    }
  }

  void _showDrawNewSignatureDialog() {
    final controller = PencilSignatureController(
      penColor: Colors.black,
      minStrokeWidth: 1.6,
      maxStrokeWidth: 4.0,
    );
    final nameCtrl = TextEditingController(
      text: widget.initialOwnerName != null && widget.initialOwnerName!.isNotEmpty
          ? 'TTD ${widget.initialOwnerName}'
          : 'Tanda Tangan',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Buat & Simpan Tanda Tangan Baru',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label / Nama Pemilik TTD',
                    hintText: 'Contoh: TTD Allam, TTD Fulan',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 180.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Stack(
                    children: [
                      PencilSignaturePad(controller: controller),
                      Positioned(
                        right: 8.w,
                        top: 8.h,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'Ulangi coretan',
                          onPressed: () {
                            controller.clear();
                            setDialogState(() {});
                          },
                        ),
                      ),
                      Positioned(
                        left: 12.w,
                        bottom: 8.h,
                        child: Text(
                          'Coret tanda tangan di atas kotak ini',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F81FF),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (controller.isEmpty) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(
                      content: Text('Coret tanda tangan terlebih dahulu'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                final bytes = await controller.toPngBytes();
                if (bytes != null) {
                  final saved = await widget.vaultService.saveSignature(
                    name: nameCtrl.text.trim(),
                    pngBytes: bytes,
                  );
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                  await _loadSignatures();
                  if (mounted && widget.onSelect != null) {
                    widget.onSelect!(saved);
                  }
                }
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
      constraints: BoxConstraints(maxHeight: 0.8.sh),
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
              Icon(Icons.draw_rounded, color: const Color(0xFF1F81FF), size: 24.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Bank Tanda Tangan',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F81FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Buat Baru', style: TextStyle(fontSize: 12.sp)),
                onPressed: _showDrawNewSignatureDialog,
              ),
            ],
          ),
          Text(
            'Pilih tanda tangan tersimpan untuk langsung ditempel ke surat izin.',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 14.h),
          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ))
          else if (_signatures.isEmpty)
            Container(
              padding: EdgeInsets.all(24.w),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drive_file_rename_outline,
                      size: 48.w, color: Colors.grey.shade400),
                  SizedBox(height: 10.h),
                  Text(
                    'Belum ada tanda tangan tersimpan',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Buat TTD sekali, dan gunakan berkali-kali tanpa perlu coret ulang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5.sp, color: Colors.grey.shade500),
                  ),
                  SizedBox(height: 14.h),
                  ElevatedButton.icon(
                    onPressed: _showDrawNewSignatureDialog,
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Buat TTD Sekarang'),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                itemCount: _signatures.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 1.3,
                ),
                itemBuilder: (ctx, idx) {
                  final sig = _signatures[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () {
                      if (widget.onSelect != null) {
                        widget.onSelect!(sig);
                      }
                      Navigator.pop(context, sig);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200, width: 1.2),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.all(8.w),
                                  child: Image.memory(
                                    sig.bytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(14.r),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.draw_outlined,
                                      size: 14.w,
                                      color: const Color(0xFF1F81FF),
                                    ),
                                    SizedBox(width: 4.w),
                                    Expanded(
                                      child: Text(
                                        sig.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 4.h,
                            right: 4.w,
                            child: InkWell(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Hapus Tanda Tangan?'),
                                    content: Text('Hapus "${sig.name}" dari bank tanda tangan?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Batal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await widget.vaultService.deleteSignature(sig.id);
                                  _loadSignatures();
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 14.w, color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                        ],
                      ),
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
