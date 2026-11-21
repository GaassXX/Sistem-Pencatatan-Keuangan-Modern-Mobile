import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Widget kartu saldo utama FinChat modern dengan gradient Indigo -> Purple,
/// status defisit/surplus, toggle sembunyikan saldo, dan indicator panah bulat.
class BalanceCard extends StatefulWidget {
  final String balance;
  final String income;
  final String expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _isHidden = false;

  @override
  Widget build(BuildContext context) {
    // Menentukan apakah status saldo defisit (mengandung tanda '-')
    final isDeficit = widget.balance.contains('-');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 10),
            color: const Color(0xFF1E1B4B).withOpacity(0.35),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label & Tombol Sembunyikan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL SALDO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: .9,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isHidden = !_isHidden);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isHidden ? 'Tampilkan' : 'Sembunyikan',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Nominal Saldo & Badge Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isHidden ? 'Rp ••••••••' : widget.balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (isDeficit && !_isHidden) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF881337), // Dark red / Maroon
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Defisit',
                    style: TextStyle(
                      color: Color(0xFFFECDD3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Pemasukan & Pengeluaran Row
          Row(
            children: [
              Expanded(
                child: _BalanceBox(
                  label: 'Pemasukan',
                  amount: _isHidden ? '••••••' : widget.income,
                  isIncome: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BalanceBox(
                  label: 'Pengeluaran',
                  amount: _isHidden ? '••••••' : widget.expense,
                  isIncome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceBox extends StatelessWidget {
  final String label;
  final String amount;
  final bool isIncome;

  const _BalanceBox({
    required this.label,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isIncome ? AppColors.accent : const Color(0xFFFCA5A5),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isIncome
                  ? AppColors.income.withOpacity(0.25)
                  : AppColors.expense.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 15,
              color: isIncome ? AppColors.accent : const Color(0xFFFCA5A5),
            ),
          ),
        ],
      ),
    );
  }
}
