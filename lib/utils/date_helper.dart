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
  return DateTime.tryParse(value.toString());
}

DateTime parseDateTime(dynamic createdAt, dynamic date) {
  final created = DateTime.tryParse(createdAt?.toString() ?? '');
  if (created != null) return created;
  final transactionDate = DateTime.tryParse(date?.toString() ?? '');
  return transactionDate ?? DateTime(2000);
}

DateTime localCreatedDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return DateTime.now();
  return date.toLocal();
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
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  final local = date.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
