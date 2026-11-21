import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';

class ProfileCard extends StatelessWidget {
  final User user;
  final bool isDarkMode;
  final Color cardColor;
  final Color softLime;
  final Color limeColor;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onChangePhoto;
  final VoidCallback? onEditProfile;

  const ProfileCard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.cardColor,
    required this.softLime,
    required this.limeColor,
    required this.primaryText,
    required this.secondaryText,
    required this.onChangePhoto,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name.isNotEmpty ? user.name : 'Pengguna';
    final email = user.email.isNotEmpty ? user.email : '-';
    final roleName = (user.role != null && user.role!.isNotEmpty)
        ? user.role!
        : 'Personal';

    final avatarBg = isDarkMode ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
    final avatarIcon = isDarkMode ? const Color(0xFFA5B4FC) : AppColors.primaryBrand;
    final badgeBg = isDarkMode ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
    final badgeFg = isDarkMode ? const Color(0xFFA5B4FC) : AppColors.primaryBrand;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: onChangePhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: avatarBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                            ? Image.network(
                                ApiService.getFullAvatarUrl(user.avatarUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 38,
                                  color: avatarIcon,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: avatarIcon,
                              ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBrand,
                          shape: BoxShape.circle,
                          border: Border.all(color: cardColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FinChat $roleName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: badgeFg,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.auto_awesome,
                            size: 11,
                            color: badgeFg,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              onPressed: onEditProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? AppColors.surfaceDarkHigh
                    : const Color(0xFFF1F5F9),
                foregroundColor: primaryText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: Icon(
                Icons.tune_rounded,
                size: 16,
                color: primaryText,
              ),
              label: Text(
                'Edit Profil Lengkap',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
