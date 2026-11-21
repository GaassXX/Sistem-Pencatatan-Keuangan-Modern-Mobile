import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request izin kamera dengan penanganan jika diblokir permanen
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    status = await Permission.camera.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await showSettingsDialog(
        context,
        title: 'Izin Kamera Dibutuhkan',
        message:
            'Aplikasi memerlukan izin kamera untuk mengambil foto profil. Silakan aktifkan izin kamera di Pengaturan aplikasi.',
      );
    }

    return false;
  }

  /// Request izin galeri foto (Android 13+ Media Images & Android lama Storage)
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    // Coba request photos (Android 13+)
    PermissionStatus status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    status = await Permission.photos.request();

    if (status.isGranted || status.isLimited) {
      return true;
    }

    // Fallback untuk Android 12 ke bawah yang menggunakan storage
    PermissionStatus storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }
    } else {
      return true;
    }

    if ((status.isPermanentlyDenied || storageStatus.isPermanentlyDenied) && context.mounted) {
      await showSettingsDialog(
        context,
        title: 'Izin Galeri Foto Dibutuhkan',
        message:
            'Aplikasi memerlukan akses galeri foto untuk memilih foto profil. Silakan aktifkan izin penyimpanan/foto di Pengaturan aplikasi.',
      );
    }

    return false;
  }

  /// Cek apakah izin notifikasi sudah aktif
  static Future<bool> isNotificationGranted() async {
    return await Permission.notification.isGranted;
  }

  /// Request izin notifikasi (Android 13+)
  static Future<bool> requestNotificationPermission(BuildContext context, {bool showDialogIfDenied = true}) async {
    PermissionStatus status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    status = await Permission.notification.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied && showDialogIfDenied && context.mounted) {
      await showSettingsDialog(
        context,
        title: 'Izin Notifikasi Dimatikan',
        message:
            'Notifikasi penting seperti persetujuan transaksi, pengingat utang jatuh tempo, dan peringatan budget dimatikan. Aktifkan notifikasi di Pengaturan?',
      );
    }

    return false;
  }

  /// Dialog edukasi untuk mengarahkan pengguna ke Pengaturan Aplikasi
  static Future<void> showSettingsDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF10B981),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: isDark ? Colors.white70 : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Nanti Saja',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
