import 'package:flutter/material.dart';

import '../../main.dart';
import '../../utils/format_utils.dart';

class StatsCard extends StatelessWidget {
  final double distance;
  final Duration duration;

  const StatsCard({super.key, required this.distance, required this.duration});

  @override
  Widget build(BuildContext context) {
    final kmText = (distance / 1000).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: _buildBoxDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.route, '距离', kmText, '公里'),
          Container(width: 1, height: 34, color: const Color(0xFFE0E0E0)),
          _statItem(Icons.timer_outlined, '时长', formatDuration(duration), null),
        ],
      ),
    );
  }

  /// 构建装饰
  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// 构建统计项
  Widget _statItem(IconData icon, String label, String value, String? unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        _buildFittedBox(value, unit),
      ],
    );
  }

  /// 构建适应框
  Widget _buildFittedBox(String value, String? unit) {
    return FittedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (unit != null) ...[
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
