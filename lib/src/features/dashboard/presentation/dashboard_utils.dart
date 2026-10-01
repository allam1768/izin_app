import '../domain/models/user_profile_model.dart';

/// Utilitas data profil untuk pengisian form surat izin
class DashboardUtils {
  DashboardUtils._();

  static UserProfileModel extractUserProfile(
    dynamic dashboardData,
    dynamic kelasData,
  ) {
    if (dashboardData is UserProfileModel) {
      return dashboardData;
    }
    return UserProfileModel.empty();
  }
}
