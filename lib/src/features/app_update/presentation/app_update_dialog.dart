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
      barrierDismissible: true,
      builder: (context) => AppUpdateDialog(updateInfo: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      elevation: 10,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon Header dengan IDN Logo
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64.w,
                    height: 64.w,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                    right: -4.w,
                    bottom: -4.h,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.system_update_rounded,
                        size: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Judul
            Text(
              'Pembaruan Tersedia!',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: 8.h),

            // Versi badge (Lokal vs Terbaru)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildVersionPill(
                  label: 'v${updateInfo.currentVersion}',
                  color: Colors.grey.shade600,
                  bgColor: Colors.grey.shade100,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
                _buildVersionPill(
                  label: 'v${updateInfo.latestVersion}',
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Catatan Rilis / Changelog
            if (updateInfo.releaseNotes.isNotEmpty) ...[
              Text(
                'Apa yang baru:',
                style: GoogleFonts.dmSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                constraints: BoxConstraints(maxHeight: 140.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    updateInfo.releaseNotes,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.sp,
                      color: const Color(0xFF4B5563),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
            ] else ...[
              Text(
                'Versi terbaru aplikasi telah dirilis dengan perbaikan dan peningkatan performa.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 20.h),
            ],

            // Tombol Aksi
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                AppUpdateService.openDownloadUrl(updateInfo.downloadUrl);
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              label: Text(
                'Unduh & Perbarui APK',
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
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.dmSans(
                  fontSize: 13.sp,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
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
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
