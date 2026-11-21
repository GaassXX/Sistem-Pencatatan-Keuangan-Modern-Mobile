import 'dart:math';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CategoryDonutData {
  final String name;
  final double amount;
  final Color color;
  final IconData icon;

  CategoryDonutData({
    required this.name,
    required this.amount,
    required this.color,
    required this.icon,
  });
}

class DonutChartWidget extends StatefulWidget {
  final List<CategoryDonutData> items;
  final String centerTitle;
  final String centerSubtitle;

  const DonutChartWidget({
    super.key,
    required this.items,
    this.centerTitle = 'Total Biaya',
    this.centerSubtitle = 'Rp 0',
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DonutChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = widget.items.fold<double>(0, (sum, item) => sum + item.amount);

    if (total == 0 || widget.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 48, color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 8),
            Text(
              'Belum ada data pengeluaran pada periode ini',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Donut Visual (Pas di Tengah) ───────────────────────
          Center(
            child: SizedBox(
              height: 210,
              width: 210,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DonutChartPainter(
                      items: widget.items,
                      total: total,
                      progress: _animation.value,
                      selectedIndex: _hoveredIndex,
                      strokeWidth: 24,
                      backgroundColor: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(26.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _hoveredIndex != null
                                  ? widget.items[_hoveredIndex!].name
                                  : widget.centerTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _hoveredIndex != null
                                    ? 'Rp ${_formatCompact(widget.items[_hoveredIndex!].amount)}'
                                    : widget.centerSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textDarkPrimary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (_hoveredIndex != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${((widget.items[_hoveredIndex!].amount / total) * 100).toStringAsFixed(1)}%',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.items[_hoveredIndex!].color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Interactive Legend Items (Pas di Tengah) ───────────
          Center(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(widget.items.length, (idx) {
                final item = widget.items[idx];
                final percent = (item.amount / total * 100).toStringAsFixed(0);
                final isSelected = _hoveredIndex == idx;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _hoveredIndex = (_hoveredIndex == idx) ? null : idx;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withOpacity(0.15)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? item.color
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)} rb';
    }
    return value.toStringAsFixed(0);
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<CategoryDonutData> items;
  final double total;
  final double progress;
  final int? selectedIndex;
  final double strokeWidth;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.items,
    required this.total,
    required this.progress,
    required this.selectedIndex,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    if (total == 0) return;

    double startAngle = -pi / 2;
    final activeItems = items.where((it) => it.amount > 0).toList();
    final hasMultiple = activeItems.length > 1;
    final gapAngle = hasMultiple ? 0.03 : 0.0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = (item.amount / total) * (2 * pi) * progress;

      if (sweepAngle <= 0.002) continue;

      final isSelected = selectedIndex == i;
      final currentStroke = isSelected ? strokeWidth + 4 : strokeWidth;

      final paint = Paint()
        ..color = item.color
        ..strokeWidth = currentStroke
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt // Flat clean cut to keep perfect circular symmetry
        ..isAntiAlias = true;

      final effectiveSweep = hasMultiple ? max(0.005, sweepAngle - gapAngle) : sweepAngle;
      final effectiveStart = hasMultiple ? (startAngle + (gapAngle / 2)) : startAngle;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        effectiveStart,
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.items != items ||
        oldDelegate.total != total;
  }
}
