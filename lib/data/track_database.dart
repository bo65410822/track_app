import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:track_app/data/saved_track.dart';
import 'package:track_app/track/track_point.dart';

class TrackDatabase {
  TrackDatabase._internal();

  // 唯一实例
  static final TrackDatabase instance = TrackDatabase._internal();

  // 缓存的数据库连接，初始为 null
  Database? _db;

  // 对外入口：要用数据库就 await 这个
  Future<Database> get database async {
    _db ??= await _initDatabase(); // 为空才打开，否则复用
    return _db!;
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'track.db'),
      onCreate: (db, version) {
        return _createTable(db);
      },
      version: 1,
    );
  }

  Future<void> _createTable(Database db) async {
    await db.execute(
      "CREATE TABLE tracks( id INTEGER PRIMARY KEY AUTOINCREMENT,start_time INTEGER,end_time INTEGER,duration INTEGER,distance REAL,point_count INTEGER,type INTEGER)",
    );

    await db.execute(
      "CREATE TABLE track_points(id INTEGER PRIMARY KEY AUTOINCREMENT,track_id INTEGER,latitude REAL,longitude REAL,timestamp INTEGER)",
    );
  }

  Future<int> insertTrack(SavedTrack track, List<TrackPoint> points) async {
    Map<String, Object?> values = <String, Object?>{};
    values['start_time'] = track.startTime;
    values['end_time'] = track.endTime;
    values['duration'] = track.duration;
    values['distance'] = track.distance;
    values['point_count'] = track.pointCount;
    values['type'] = track.type;
    Database db = await instance.database;
    return db.transaction((txn) async {
      int trackId = await txn.insert('tracks', values);
      for (TrackPoint point in points) {
        await txn.insert('track_points', {
          'track_id': trackId,
          'latitude': point.latitude,
          'longitude': point.longitude,
          'timestamp': point.timestamp,
        });
      }
      return trackId;
    });
  }

  Future<List<SavedTrack>> getAllTracks() async {
    Database db = await instance.database;
    List<Map<String, Object?>> tracks = await db.query('tracks');
    return tracks
        .map(
          (track) => SavedTrack(
            id: int.parse(track['id'].toString()),
            startTime: track['start_time'] != null
                ? track['start_time'] as int
                : 0,
            endTime: track['end_time'] != null ? track['end_time'] as int : 0,
            duration: track['duration'] != null ? track['duration'] as int : 0,
            distance: track['distance'] != null
                ? track['distance'] as double
                : 0.0,
            pointCount: track['point_count'] != null
                ? track['point_count'] as int
                : 0,
            type: track['type'] != null ? track['type'] as int : 0,
          ),
        )
        .toList();
  }

  Future<void> deleteTrack(SavedTrack track) async {
    Database db = await instance.database;
    await db.transaction((txn) async {
      // 先删该轨迹的所有点，再删轨迹本身，避免孤儿数据
      await txn.delete(
        'track_points',
        where: 'track_id = ?',
        whereArgs: [track.id],
      );
      await txn.delete('tracks', where: 'id = ?', whereArgs: [track.id]);
    });
  }

  Future<List<TrackPoint>> getTrackPoints(SavedTrack track) async {
    Database db = await instance.database;
    var list = await db.query(
      'track_points',
      where: 'track_id = ?',
      whereArgs: [track.id],
    );
    return list
        .map(
          (trackPoint) => TrackPoint(
            latitude: trackPoint['latitude'] as double,
            longitude: trackPoint['longitude'] as double,
            timestamp: trackPoint['timestamp'] as int,
          ),
        )
        .toList();
  }
}
