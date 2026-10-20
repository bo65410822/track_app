import 'package:flutter/material.dart';
import 'package:track_app/data/track_database.dart';
import 'package:track_app/track_detail_page.dart';
import 'package:track_app/utils/format_utils.dart';

import 'data/saved_track.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    getTracks();
  }

  List<SavedTrack> tracks = [];

  Future<void> getTracks() async {
    List<SavedTrack> result = await TrackDatabase.instance.getAllTracks();
    if (!mounted) return;
    setState(() {
      tracks = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: tracks.isEmpty
          ? Center(child: Text('暂无记录'))
          : ListView.builder(
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final track = tracks[index];
                return ListTile(
                  title: Text(
                    '距离 ${formatDistance(track.distance)}  '
                    '时长 ${formatDuration(Duration(milliseconds: track.duration))}',
                  ),
                  subtitle: Text(
                    DateTime.fromMillisecondsSinceEpoch(track.startTime)
                        .toString(),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrackDetailPage(track: track),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
