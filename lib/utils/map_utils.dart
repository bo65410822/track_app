import 'package:x_amap_base/x_amap_base.dart';

import '../track/track_point.dart';

LatLng toLatLng(TrackPoint p) => LatLng(p.latitude, p.longitude);

List<LatLng> toLatLngList(List<TrackPoint> points) =>
    points.map(toLatLng).toList();


