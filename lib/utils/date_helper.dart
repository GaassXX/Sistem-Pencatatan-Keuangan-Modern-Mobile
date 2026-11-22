/// Helper date & waktu untuk halaman transaksi.
library;

String monthName(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return months[month - 1];
}

String fullMonthName(int month) {
  const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return months[month - 1];
}

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  String s = value.toString().trim();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// Helper untuk mem-parsing string datetime dari backend (UTC) ke local device time
DateTime parseUtcToLocal(dynamic value) {
  if (value == null) return DateTime.now();
  String s = value.toString().trim();
  if (s.isEmpty) return DateTime.now();
  if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
    s += 'Z';
  }
  return (DateTime.tryParse(s) ?? DateTime.now()).toLocal();
}

DateTime parseDateTime(dynamic createdAt, dynamic date) {
  if (createdAt != null && createdAt.toString().trim().isNotEmpty) {
    return parseUtcToLocal(createdAt);
  }
  final transactionDate = DateTime.tryParse(date?.toString() ?? '');
  return transactionDate ?? DateTime(2000);
}

DateTime localCreatedDate(dynamic value) {
  return parseUtcToLocal(value);
}

String dayLabel(dynamic value) {
  final date = parseDate(value);
  if (date == null) return 'TANGGAL';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final transactionDate = DateTime(date.year, date.month, date.day);
  final difference = today.difference(transactionDate).inDays;

  if (difference == 0) return 'HARI INI, ${date.day} ${monthName(date.month)}';
  if (difference == 1) return 'KEMARIN, ${date.day} ${monthName(date.month)}';
  return '${date.day} ${monthName(date.month)} ${date.year}'.toUpperCase();
}

String formatTime(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) return '';
  final local = parseUtcToLocal(value);
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
