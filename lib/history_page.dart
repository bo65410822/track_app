import 'package:flutter/material.dart';
import 'package:track_app/data/track_database.dart';
import 'package:track_app/track_detail_page.dart';
import 'package:track_app/utils/format_utils.dart';

import 'data/saved_track.dart';
import 'main.dart' show kPrimaryColor;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<SavedTrack> tracks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getTracks();
  }

  Future<void> getTracks() async {
    final result = await TrackDatabase.instance.getAllTracks();
    if (!mounted) return;
    setState(() {
      tracks = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF5F0),
        elevation: 0,
        iconTheme: const IconThemeData(color: kPrimaryColor),
        title: const Text(
          '历史记录',
          style: TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tracks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    return _buildTrackCard(tracks[index]);
                  },
                ),
    );
  }

  Widget _buildTrackCard(SavedTrack track) {
    final kmText = (track.distance / 1000).toStringAsFixed(2);
    final durationText = formatDuration(Duration(milliseconds: track.duration));
    final timeText = _formatDateTime(track.startTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDetailPage(track: track),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 占位缩略图
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route, color: kPrimaryColor, size: 30),
                ),
                const SizedBox(width: 12),
                // 中间信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            kmText,
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('公里',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 15, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(durationText,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                // 右侧日期 + 箭头
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(timeText,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    const Icon(Icons.chevron_right,
                        color: Colors.grey, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.map_outlined,
                size: 72, color: kPrimaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无记录',
            style: TextStyle(
              color: kPrimaryColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '开始你的第一次运动记录吧',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            icon: const Icon(Icons.directions_run),
            label: const Text('去记录',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(int millis) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}
