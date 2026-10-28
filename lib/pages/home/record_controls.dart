import 'package:flutter/material.dart';

import '../../data/saved_track.dart';

const _recordingColor = Color(0xFFE53935);

class RecordControls extends StatelessWidget {
  const RecordControls({
    super.key,
    required this.isRecording,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onRecordPressed,
  });

  final bool isRecording;
  final SportType selectedType;
  final ValueChanged<SportType> onTypeChanged;
  final VoidCallback onRecordPressed;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final double padding = isRecording ? 12 : 16;
    Widget widget = isRecording
        ? _buildRecordState()
        : _TrackTypeSelector(
            selectedType: selectedType,
            onChanged: onTypeChanged,
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: padding),
          child: widget,
        ),
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: onRecordPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isRecording ? _recordingColor : primaryColor,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
            ),
            icon: Icon(isRecording ? Icons.stop : Icons.play_arrow, size: 20),
            label: Text(
              isRecording ? '停止记录' : '开始记录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordState() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 10, color: _recordingColor),
          const SizedBox(width: 6),
          Text(
            '正在记录 · ${selectedType.label}',
            style: const TextStyle(
              color: _recordingColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackTypeSelector extends StatelessWidget {
  const _TrackTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  final SportType selectedType;
  final ValueChanged<SportType> onChanged;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: SportType.values.map((type) {
          return _buildTypeItem(type, primaryColor);
        }).toList(),
      ),
    );
  }

  Widget _buildTypeItem(SportType type, Color primaryColor) {
    final selected = selectedType == type;
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: selected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              type.label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
