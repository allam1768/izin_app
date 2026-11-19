import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../application/app_update_service.dart';
import '../domain/models/app_update_info.dart';

/// Dialog konfirmasi dan informasi pembaruan versi aplikasi
class AppUpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;

  const AppUpdateDialog({super.key, required this.updateInfo});

  static Future<void> show(BuildContext context, AppUpdateInfo info) {
    return showDialog(
      context: context,
      barrierDismissible: !info.isForceUpdate,
      builder: (context) => AppUpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = updateInfo.isForceUpdate;
    final primaryColor = isUrgent
        ? const Color(0xFFDC2626)
        : theme.colorScheme.primary;

    return PopScope(
      canPop: !isUrgent,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        elevation: 6,
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon Header IDN Logo
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icon/idn_ic.svg',
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -3.w,
                      bottom: -3.h,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: isUrgent
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isUrgent
                              ? Icons.priority_high_rounded
                              : Icons.system_update_rounded,
                          size: 13.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Judul Dialog
              Text(
                isUrgent ? 'Pembaruan Wajib Tersedia' : 'Pembaruan Tersedia',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8.h),

              // Versi badge (Lokal vs Terbaru)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildVersionPill(
                    label: 'v${updateInfo.currentVersion}',
                    color: const Color(0xFF64748B),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14.sp,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  _buildVersionPill(
                    label: 'v${updateInfo.latestVersion}',
                    color: isUrgent
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                    bgColor: isUrgent
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFDCFCE7),
                  ),
                  if (isUrgent) ...[
                    SizedBox(width: 6.w),
                    _buildVersionPill(
                      label: 'WAJIB',
                      color: Colors.white,
                      bgColor: const Color(0xFFDC2626),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 16.h),

              // Catatan Rilis / Changelog
              if (updateInfo.releaseNotes.isNotEmpty) ...[
                Text(
                  'Catatan Pembaruan:',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                SizedBox(height: 6.h),
                Container(
                  constraints: BoxConstraints(maxHeight: 140.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateInfo.releaseNotes,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.sp,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
              ] else ...[
                Text(
                  isUrgent
                      ? 'Pembaruan penting tersedia untuk kelancaran pembuatan surat izin.'
                      : 'Versi terbaru aplikasi telah dirilis dengan perbaikan dan peningkatan performa.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 20.h),
              ],

              // Tombol Aksi
              ElevatedButton.icon(
                onPressed: () {
                  if (!isUrgent) {
                    Navigator.of(context).pop();
                  }
                  AppUpdateService.openDownloadUrl(updateInfo.downloadUrl);
                  if (isUrgent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Membuka tautan unduhan. Silakan pasang pembaruan untuk melanjutkan.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: Text(
                  isUrgent ? 'Unduh & Perbarui Sekarang' : 'Unduh & Perbarui APK',
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              if (!isUrgent) ...[
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Nanti Saja',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionPill({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
