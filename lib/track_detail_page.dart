import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:track_app/data/track_database.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'data/saved_track.dart';

class TrackDetailPage extends StatefulWidget {
  final SavedTrack track;

  const TrackDetailPage({super.key, required this.track});

  @override
  State<StatefulWidget> createState() => _TrackDetailPageState();
}

class _TrackDetailPageState extends State<TrackDetailPage> {
  List<LatLng> trackPoints = [];

  @override
  void initState() {
    super.initState();
    TrackDatabase.instance.getTrackPoints(widget.track).then((value) {
      if (!mounted) return;
      setState(() {
        trackPoints = value
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Set<Polyline> polylines = trackPoints.length >= 2
        ? {Polyline(points: trackPoints, color: Colors.red, width: 5)}
        : <Polyline>{};
    return Scaffold(
      appBar: AppBar(title: Text("轨迹详情")),
      body: trackPoints.isEmpty
          ? const Center(child: Text('暂无数据'))
          : AMapWidget(
              onMapCreated: (controller) {
                if (!mounted) return;
                var latLng = trackPoints[0];
                var cameraUpdate = CameraUpdate.newLatLngZoom(latLng, 15);
                controller.moveCamera(cameraUpdate);
              },
              polylines: polylines,
            ),
    );
  }
}
