class DebtPayment {
  final int id;
  final double amount;
  final String source; // 'cash', 'emoney', 'bank'
  final int? walletId;
  final String? walletName;
  final String? date;
  final String? description;
  final String status; // 'approved', 'pending'
  final String? createdAt;

  DebtPayment({
    required this.id,
    required this.amount,
    required this.source,
    this.walletId,
    this.walletName,
    this.date,
    this.description,
    required this.status,
    this.createdAt,
  });

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      source: json['source']?.toString() ?? 'cash',
      walletId: json['wallet_id'] is int ? json['wallet_id'] : int.tryParse(json['wallet_id']?.toString() ?? ''),
      walletName: json['wallet_name']?.toString(),
      date: json['date']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'approved',
      createdAt: json['created_at']?.toString(),
    );
  }

  String get formattedDate {
    if (date == null || date!.isEmpty) return '-';
    try {
      final parts = date!.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final monthStr = (monthNum >= 1 && monthNum <= 12) ? months[monthNum - 1] : parts[1];
        return '$day $monthStr $year';
      }
      return date!;
    } catch (_) {
      return date!;
    }
  }

  String get sourceLabel {
    if (walletName != null && walletName!.trim().isNotEmpty) {
      return walletName!;
    }
    switch (source.toLowerCase()) {
      case 'emoney':
      case 'e-money':
      case 'ewallet':
        return 'E-Money';
      case 'bank':
      case 'transfer bank':
        return 'Transfer Bank';
      case 'cash':
      case 'tunai':
      default:
        return 'Tunai';
    }
  }
}

class DebtItem {
  final int id;
  final String type; // 'debt' or 'receivable'
  final String personName;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final double percentPaid;
  final int installmentsCount;
  final String? date;
  final String? dueDate;
  final String? description;
  final String status; // 'unpaid' or 'paid'
  final String? paidAt;
  final List<DebtPayment> payments;

  DebtItem({
    required this.id,
    required this.type,
    required this.personName,
    required this.amount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.percentPaid,
    required this.installmentsCount,
    this.date,
    this.dueDate,
    this.description,
    required this.status,
    this.paidAt,
    this.payments = const [],
  });

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] is num
        ? (json['amount'] as num).toDouble()
        : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;

    final rawPaid = json['paid_amount'] is num
        ? (json['paid_amount'] as num).toDouble()
        : double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0;

    final rawRemaining = json['remaining_amount'] is num
        ? (json['remaining_amount'] as num).toDouble()
        : (json['status'] == 'paid' ? 0.0 : rawAmount);

    final rawPercent = json['percent_paid'] is num
        ? (json['percent_paid'] as num).toDouble()
        : (json['status'] == 'paid' ? 100.0 : (rawAmount > 0 ? (rawPaid / rawAmount * 100) : 0.0));

    final rawPayments = json['payments'] as List<dynamic>? ?? [];
    final paymentsList = rawPayments.map((p) {
      if (p is Map<String, dynamic>) return DebtPayment.fromJson(p);
      return DebtPayment.fromJson(Map<String, dynamic>.from(p as Map));
    }).toList();

    return DebtItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type']?.toString() ?? 'debt',
      personName: json['person_name']?.toString() ?? '-',
      amount: rawAmount,
      paidAmount: rawPaid,
      remainingAmount: rawRemaining,
      percentPaid: rawPercent,
      installmentsCount: json['installments_count'] is int
          ? json['installments_count']
          : paymentsList.length,
      date: json['date']?.toString(),
      dueDate: json['due_date']?.toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'unpaid',
      paidAt: json['paid_at']?.toString(),
      payments: paymentsList,
    );
  }

  bool get isPaid => status == 'paid' || remainingAmount <= 0;
  bool get isDebt => type == 'debt';

  String get formattedDueDate {
    if (dueDate == null || dueDate!.isEmpty) return '-';
    try {
      final parts = dueDate!.split('-');
      if (parts.length == 3) {
        final year = parts[0];
        final monthNum = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        final monthStr = (monthNum >= 1 && monthNum <= 12) ? months[monthNum - 1] : parts[1];
        return '$day $monthStr $year';
      }
      return dueDate!;
    } catch (_) {
      return dueDate!;
    }
  }
}
