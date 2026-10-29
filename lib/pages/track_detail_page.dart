import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:track_app/data/track_database.dart';
import 'package:track_app/pages/widgets/app_top_bar.dart';
import 'package:track_app/utils/format_utils.dart';
import 'package:track_app/utils/map_utils.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/saved_track.dart';
import '../main.dart';

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
    return Scaffold(
      appBar: AppTopBar(
        title: '轨迹详情',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: kRecordingColor),
            onPressed: _onDeletePressed,
          ),
        ],
      ),
      body: trackPoints.isEmpty
          ? const Center(child: Text('加载中...'))
          : Stack(
              children: [
                AMapWidget(
                  onMapCreated: (controller) {
                    if (!mounted) return;
                    controller.moveCamera(fitTrackCameraUpdate(trackPoints));
                  },
                  polylines: {
                    Polyline(
                      points: trackPoints,
                      color: kPrimaryColor,
                      width: 6,
                      capType: CapType.round,
                      joinType: JoinType.round,
                    ),
                  },
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildStatsCard(),
                ),
              ],
            ),
    );
  }

  Future<void> _onDeletePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录'),
        content: const Text('确定删除这条运动记录吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await TrackDatabase.instance.deleteTrack(widget.track);
    if (!mounted) return;
    // 返回 true，让历史列表刷新
    Navigator.pop(context, true);
  }

  Widget _buildStatsCard() {
    final track = widget.track;
    final sportType = SportType.fromCode(track.type ?? 0);
    final kmText = (track.distance / 1000).toStringAsFixed(2);
    final durationText = formatDuration(Duration(milliseconds: track.duration));
    final timeText = _formatDateTime(track.startTime);
    final metric = sportMetric(
      sportType,
      track.distance,
      Duration(milliseconds: track.duration),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _statItem(Icons.route, '距离', kmText, '公里')),
              _divider(),
              Expanded(
                child: _statItem(
                  Icons.timer_outlined,
                  '时长',
                  durationText,
                  null,
                ),
              ),
              _divider(),
              Expanded(
                child: _statItem(Icons.speed, metric.$1, metric.$2, null),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                timeText,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 32, color: const Color(0xFFE0E0E0));

  Widget _statItem(IconData icon, String label, String value, String? unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}
