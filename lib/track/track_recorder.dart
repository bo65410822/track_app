import 'dart:math';

import 'package:track_app/track/track_point.dart';

class TrackRecorder {
  bool _isRecording = false;
  final List<TrackPoint> _trackPoints = [];

  bool get isRecording => _isRecording;

  List<TrackPoint> get points => List.unmodifiable(_trackPoints);

  void startRecording() {
    _isRecording = true;
    _trackPoints.clear();
  }

  void stopRecording() {
    _isRecording = false;
  }

  void addTrackPoint(TrackPoint trackPoint) {
    if (!_isRecording) {
      return;
    }
    _trackPoints.add(trackPoint);
  }

  Duration get duration {
    if (_trackPoints.length < 2) {
      return Duration.zero;
    }
    final start = _trackPoints.first.timestamp;
    final end = _trackPoints.last.timestamp;
    return Duration(milliseconds: end - start);
  }

  // 纯函数：输入轨迹点，输出数字，不依赖地图、不依赖 UI，方便测试。
  // totalDistance 对 0 个或 1 个点要返回 0，不能崩。
  // 地球半径用常量 6371000 米。
  // GPS 的经纬度是角度，Haversine 里要先把角度转成弧度再做三角运算。
  double _toRadians(double degree) => degree * pi / 180;

  double distanceBetween(TrackPoint a, TrackPoint b) {
    const double earthRadius = 6371000;

    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(h), sqrt(1 - h));

    return earthRadius * c;
  }

  double calculateTotalDistance() {
    double sum = 0;
    for (var i = 1; i < points.length; i++) {
      sum += distanceBetween(points[i - 1], points[i]);
    }
    return sum;
  }
}
