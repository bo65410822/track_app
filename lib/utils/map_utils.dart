import 'dart:math';

import 'package:amap_map/amap_map.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../track/track_point.dart';

LatLng toLatLng(TrackPoint p) => LatLng(p.latitude, p.longitude);

List<LatLng> toLatLngList(List<TrackPoint> points) =>
    points.map(toLatLng).toList();

/// 计算一组坐标的边界框（西南角 + 东北角）
LatLngBounds calculateBounds(List<LatLng> points) {
  double minLat = points.first.latitude;
  double maxLat = points.first.latitude;
  double minLng = points.first.longitude;
  double maxLng = points.first.longitude;
  for (final p in points) {
    minLat = min(minLat, p.latitude);
    maxLat = max(maxLat, p.latitude);
    minLng = min(minLng, p.longitude);
    maxLng = max(maxLng, p.longitude);
  }
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// 返回"让整条轨迹显示在屏幕内"的相机更新。
/// 轨迹过于集中（原地）时退回固定缩放，避免放大到极限。
CameraUpdate fitTrackCameraUpdate(List<LatLng> points, {double padding = 80}) {
  final bounds = calculateBounds(points);
  final latSpan = bounds.northeast.latitude - bounds.southwest.latitude;
  final lngSpan = bounds.northeast.longitude - bounds.southwest.longitude;
  if (latSpan < 0.0001 && lngSpan < 0.0001) {
    return CameraUpdate.newLatLngZoom(points.first, 16);
  }
  return CameraUpdate.newLatLngBounds(bounds, padding);
}
