import 'package:track_app/data/saved_track.dart';

String formatDistance(double distance) {
  if (distance < 1000) {
    return '${distance.round()}m';
  } else {
    return '${(distance / 1000).toStringAsFixed(2)}km';
  }
}

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatPace(double distanceMeters, Duration duration) {
  if (distanceMeters <= 0 || duration.inSeconds <= 0) {
    return '--';
  }
  final pace = duration.inSeconds / (distanceMeters / 1000); // 秒/公里
  final minutes = pace ~/ 60;
  final seconds = (pace % 60).round();
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String formatSpeed(double distanceMeters, Duration duration) {
  if (distanceMeters <= 0 || duration.inSeconds <= 0) {
    return '--';
  }
  final speed = distanceMeters / duration.inSeconds.toDouble() * 3.6;
  return '${speed.toStringAsFixed(2)} km/h';
}

/// 按运动类型返回要展示的指标：(标签, 值)
/// 跑步/徒步显示配速，骑行显示均速。
(String, String) sportMetric(
  SportType type,
  double distanceMeters,
  Duration duration,
) {
  switch (type) {
    case SportType.ride:
      return ('均速', formatSpeed(distanceMeters, duration));
    case SportType.run:
    case SportType.walk:
      return ('配速', formatPace(distanceMeters, duration));
  }
}
