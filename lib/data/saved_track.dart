import 'package:flutter/material.dart';

class SavedTrack {
  final int? id;
  final int startTime;
  final int endTime;
  final int duration;
  final double distance;
  final int pointCount;
  final int? type;

  SavedTrack({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.pointCount,
    this.type = 0,
  });
}

enum SportType {
  run(0, '跑步', Icons.directions_run),
  ride(1, '骑行', Icons.directions_bike),
  walk(2, '徒步', Icons.directions_walk);

  const SportType(this.code, this.label, this.icon);

  final int code;        // 存数据库的 int 值
  final String label;    // 显示名称
  final IconData icon;   // 图标

  // 从数据库读出的 int 还原成枚举，非法值兜底为跑步
  static SportType fromCode(int code) => SportType.values.firstWhere(
        (t) => t.code == code,
    orElse: () => SportType.run,
  );
}
