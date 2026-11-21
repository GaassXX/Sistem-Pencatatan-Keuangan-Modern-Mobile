/// Helper functions untuk formatting angka dan teks.
String formatRupiah(dynamic value) {
  if (value == null) {
    return 'Rp 0';
  }

  num? number;

  if (value is num) {
    number = value;
  } else {
    number = num.tryParse(value.toString());
  }

  if (number == null) {
    return 'Rp 0';
  }

  final formatted = number
      .round()
      .toString()
      .replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => '.',
      );

  return 'Rp $formatted';
}
