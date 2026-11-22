import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

/// Logo FinChat resmi sesuai desain squircle ungu + chat bubble putih
/// Beserta teks 'FinChat' dan subtitle 'Laporan Keuangan'
class FinChatBrandLogo extends StatelessWidget {
  final double iconSize;
  final bool isVertical;
  final bool showSubtitle;

  const FinChatBrandLogo({
    super.key,
    this.iconSize = 56,
    this.isVertical = false,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final subColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final logoIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(iconSize * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7417F6).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(iconSize * 0.28),
        child: Image.asset(
          'assets/icon/app_logo.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF7417F6),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: iconSize * 0.52,
            ),
          ),
        ),
      ),
    );

    final titleBlock = Column(
      crossAxisAlignment:
          isVertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'FinChat',
          style: TextStyle(
            fontSize: isVertical ? 26 : 22,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 1),
          Text(
            'Laporan Keuangan',
            style: TextStyle(
              fontSize: isVertical ? 13 : 12,
              fontWeight: FontWeight.w600,
              color: subColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          logoIcon,
          const SizedBox(height: 14),
          titleBlock,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        const SizedBox(width: 14),
        titleBlock,
      ],
    );
  }
}

/// Input field terstandarisasi untuk Login & Register dengan warna tema FinChat
class AuthInput extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;

  const AuthInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;
    final labelColor = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final iconColor = isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final hintColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: borderCol, width: 1.2),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF5B4DFF), width: 1.8),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.expense, width: 1.2),
    );

    final inputDecoration = InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: bg,
      border: border,
      enabledBorder: border,
      focusedBorder: focusBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44),
      suffixIcon: suffixIcon,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        validator != null
            ? TextFormField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onFieldSubmitted: onSubmitted,
                validator: validator,
                style: TextStyle(color: labelColor, fontSize: 15),
                decoration: inputDecoration,
              )
            : TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                onSubmitted: onSubmitted,
                style: TextStyle(color: labelColor, fontSize: 15),
                decoration: inputDecoration,
              ),
      ],
    );
  }
}

/// Tombol utama Auth dengan styling ungu FinChat modern
class AuthButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthButton({
    super.key,
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B4DFF), // Ungu FinChat
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFF5B4DFF).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
