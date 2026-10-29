import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:track_app/data/track_database.dart';
import 'package:track_app/track/track_point.dart';

import '../data/saved_track.dart';

class TrackSaveService {
  const TrackSaveService();

  Future<int?> save({
    required List<TrackPoint> points,
    required SportType type,
    required Duration duration,
    required double distance,
  }) async {
    if (points.length < 2) {
      return null;
    }

    return TrackDatabase.instance.insertTrack(
      SavedTrack(
        startTime: points.first.timestamp,
        endTime: points.last.timestamp,
        duration: duration.inMilliseconds,
        distance: distance,
        pointCount: points.length,
        type: type.code,
      ),
      points,
    );
  }

  Future<void> saveThumbnail({
    required int trackId,
    required Uint8List bytes,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/thumb_$trackId.png';
    try {
      await File(path).writeAsBytes(bytes);
      await TrackDatabase.instance.updateThumbnail(trackId, path);
    } catch (e) {
      // 删除文件
      if (await File(path).exists()) File(path).delete();
    }
  }
}
