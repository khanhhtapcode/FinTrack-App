import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for 6 days
    final List<double> data = [50, 70, 60, 100, 65, 55];
    final double maxValue = data.reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(6, (index) {
          final barHeight = (data[index] / maxValue) * 120;
          final isHighlighted = index == 3; // T4 is highlighted

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bar
              Container(
                width: 40,
                height: barHeight,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppTheme.primaryTeal
                      : AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              // Day label
              Text(
                'T${index + 1}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          );
        }),
      ),
    );
  }
}
