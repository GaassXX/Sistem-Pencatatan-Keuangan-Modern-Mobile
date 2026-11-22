import 'package:flutter/material.dart';

/// Chip filter untuk memilih jenis transaksi — Modern FinChat Design.
class TxFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const TxFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const selectedBg = Color(0xFF4F46E5);
    const selectedText = Colors.white;
    final unselectedBg = Theme.of(context).colorScheme.surface;
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? selectedBg : unselectedBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedBg : borderColor,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? selectedText : unselectedText,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                trailingIcon,
                size: 13,
                color: selected ? selectedText : unselectedText,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row berisi chip filter jenis transaksi.
class FilterChipBar extends StatelessWidget {
  final String selectedType;
  final void Function(String) onTypeChanged;
  final String? selectedCategory;
  final VoidCallback? onCategoryTap;

  const FilterChipBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    this.selectedCategory,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    const types = ['Semua', 'Pengeluaran', 'Pemasukan'];
    final hasCategory = selectedCategory != null && selectedCategory!.isNotEmpty;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < types.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            TxFilterChip(
              label: types[i],
              selected: selectedType == types[i],
              onTap: () => onTypeChanged(types[i]),
            ),
          ],
          const SizedBox(width: 8),
          TxFilterChip(
            label: hasCategory ? selectedCategory! : 'Kategori',
            selected: hasCategory,
            trailingIcon: hasCategory ? Icons.close_rounded : Icons.tune_rounded,
            onTap: onCategoryTap ?? () {},
          ),
        ],
      ),
    );
  }
}
