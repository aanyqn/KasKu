import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class SpendingChart extends StatefulWidget {
  final Map<String, double> categorySpending;

  const SpendingChart({super.key, required this.categorySpending});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categorySpending.isEmpty) {
      return _emptyState(context);
    }

    final entries = widget.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total =
        entries.fold(0.0, (sum, e) => sum + e.value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Pie chart
              Expanded(
                flex: 5,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: _buildSections(entries, total),
                  ),
                ),
              ),
              // Legend
              Expanded(
                flex: 5,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(right: 8),
                  itemCount: entries.length > 5 ? 5 : entries.length,
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    final pct =
                        (entry.value / total * 100).toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors
                                  .chartColors[i % AppColors.chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Selected category detail
        if (_touchedIndex >= 0 && _touchedIndex < entries.length)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chartColors[
                      _touchedIndex % AppColors.chartColors.length]
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.chartColors[
                    _touchedIndex % AppColors.chartColors.length],
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entries[_touchedIndex].key,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  CurrencyFormatter.format(entries[_touchedIndex].value),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.chartColors[
                            _touchedIndex % AppColors.chartColors.length],
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, double>> entries, double total) {
    return List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final value = entries[i].value;
      final color = AppColors.chartColors[i % AppColors.chartColors.length];

      return PieChartSectionData(
        color: color,
        value: value,
        title: isTouched
            ? '${(value / total * 100).toStringAsFixed(0)}%'
            : '',
        radius: isTouched ? 56 : 48,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        borderSide: isTouched
            ? BorderSide(color: color, width: 2)
            : BorderSide.none,
      );
    });
  }

  Widget _emptyState(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada pengeluaran bulan ini',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
