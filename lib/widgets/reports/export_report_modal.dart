import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/report_export_service.dart';

class ExportReportModal extends StatefulWidget {
  final DateTime selectedMonth;

  const ExportReportModal({
    super.key,
    required this.selectedMonth,
  });

  @override
  State<ExportReportModal> createState() => _ExportReportModalState();
}

class _ExportReportModalState extends State<ExportReportModal> {
  bool _isFullYear = false;
  String _selectedFormat = 'pdf'; // 'pdf' or 'excel'
  bool _isDownloading = false;
  String? _errorMessage;

  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  String get _currentMonthName => _monthNames[widget.selectedMonth.month - 1];
  int get _year => widget.selectedMonth.year;

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
      _errorMessage = null;
    });

    try {
      final transactions = await ApiService.getTransactions();
      final file = await ReportExportService.createReport(
        transactions: transactions,
        year: _year,
        month: _isFullYear ? null : widget.selectedMonth.month,
        format: _selectedFormat,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);

        final result = await OpenFilex.open(file.path);
        final String message;
        final Color backgroundColor;
        switch (result.type) {
          case ResultType.done:
            message = 'Laporan berhasil diunduh dan dibuka';
            backgroundColor = const Color(0xFF059669);
            break;
          case ResultType.noAppToOpen:
            message =
                'Laporan berhasil disimpan di HP. Pasang aplikasi pembaca PDF/Excel untuk membukanya';
            backgroundColor = const Color(0xFF2563EB);
            break;
          default:
            message = 'Laporan tersimpan di: ${file.path}';
            backgroundColor = const Color(0xFFB45309);
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final secondaryText =
        isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5B4DFF).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.file_download_outlined,
                        size: 20,
                        color: Color(0xFF5B4DFF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unduh Laporan Keuangan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Pilih cakupan periode & format berkas',
                          style:
                              TextStyle(fontSize: 11.5, color: secondaryText),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            // ── 1. Pilihan Periode ─────────────────────────────────
            Text(
              'Cakupan Periode Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildPeriodOption(
                    title: 'Bulan Ini',
                    subtitle: '$_currentMonthName $_year',
                    isSelected: !_isFullYear,
                    icon: Icons.calendar_month_outlined,
                    onTap: () => setState(() => _isFullYear = false),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPeriodOption(
                    title: '1 Tahun Penuh',
                    subtitle: 'Tahun $_year (Jan - Des)',
                    isSelected: _isFullYear,
                    icon: Icons.date_range_outlined,
                    onTap: () => setState(() => _isFullYear = true),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── 2. Pilihan Format ──────────────────────────────────
            Text(
              'Format Unduhan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _buildFormatOption(
                    code: 'pdf',
                    label: 'Dokumen PDF (.pdf)',
                    description: 'Ringkasan visual siap cetak/arsip',
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: const Color(0xFFEF4444), // Red
                    isSelected: _selectedFormat == 'pdf',
                    onTap: () => setState(() => _selectedFormat = 'pdf'),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFormatOption(
                    code: 'excel',
                    label: 'Excel (.xlsx)',
                    description: 'Tabel spreadsheet terstruktur',
                    icon: Icons.table_chart_outlined,
                    iconColor: const Color(0xFF10B981), // Emerald
                    isSelected: _selectedFormat == 'excel',
                    onTap: () => setState(() => _selectedFormat = 'excel'),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Keterangan Konten Laporan ──────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF5B4DFF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laporan mencakup ringkasan mutasi arus kas, perbandingan kategori pengeluaran, serta rincian seluruh daftar transaksi akun Anda.',
                      style: TextStyle(
                          fontSize: 11, color: secondaryText, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── Tombol Unduh ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _handleDownload,
                icon: _isDownloading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.download_rounded, size: 18),
                label: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _isFullYear
                            ? 'Unduh Laporan Tahun $_year (${_selectedFormat.toUpperCase()})'
                            : 'Unduh Laporan $_currentMonthName (${_selectedFormat.toUpperCase()})',
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B4DFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B4DFF).withOpacity(isDark ? 0.25 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B4DFF)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? const Color(0xFF5B4DFF)
                      : (isDark ? Colors.white60 : Colors.grey),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF5B4DFF)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF5B4DFF)
                    : (isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatOption({
    required String code,
    required String label,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF5B4DFF).withOpacity(isDark ? 0.25 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5B4DFF)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: iconColor),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF5B4DFF)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? const Color(0xFF5B4DFF)
                    : (isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
