import 'package:flutter_test/flutter_test.dart';
import 'package:track_app/track/track_point.dart';
import 'package:track_app/track/track_recorder.dart';

TrackPoint _point(double lat, double lng, int ts) =>
    TrackPoint(latitude: lat, longitude: lng, timestamp: ts);

void main() {
  late TrackRecorder recorder;

  setUp(() {
    recorder = TrackRecorder();
  });

  group('初始状态', () {
    test('未记录、无点、时长与距离为 0', () {
      expect(recorder.isRecording, false);
      expect(recorder.points, isEmpty);
      expect(recorder.duration, Duration.zero);
      expect(recorder.calculateTotalDistance(), 0);
    });
  });

  group('开始 / 停止 / 收点', () {
    test('开始后进入记录状态', () {
      recorder.startRecording();
      expect(recorder.isRecording, true);
    });

    test('记录中加点会被收集', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      recorder.addTrackPoint(_point(0, 1, 1000));
      expect(recorder.points.length, 2);
    });

    test('未开始时加点被忽略', () {
      recorder.addTrackPoint(_point(0, 0, 0));
      expect(recorder.points, isEmpty);
    });

    test('停止后加点被忽略', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      recorder.stopRecording();
      recorder.addTrackPoint(_point(0, 1, 1000));
      expect(recorder.points.length, 1);
    });

    test('再次开始会清空上一轮的点', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      recorder.addTrackPoint(_point(0, 1, 1000));
      recorder.startRecording();
      expect(recorder.points, isEmpty);
    });

    test('points 返回只读视图，外部不能修改', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      expect(
        () => recorder.points.add(_point(0, 1, 1000)),
        throwsUnsupportedError,
      );
    });
  });

  group('时长', () {
    test('不足两个点时长为 0', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 5000));
      expect(recorder.duration, Duration.zero);
    });

    test('首尾时间戳差值作为时长', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 1000));
      recorder.addTrackPoint(_point(0, 1, 4000));
      expect(recorder.duration, const Duration(milliseconds: 3000));
    });
  });

  group('距离', () {
    test('不足两个点距离为 0', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      expect(recorder.calculateTotalDistance(), 0);
    });

    test('相同两点距离约等于 0', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(31.0, 121.0, 0));
      recorder.addTrackPoint(_point(31.0, 121.0, 1000));
      expect(recorder.calculateTotalDistance(), closeTo(0, 0.001));
    });

    test('纬度相差 1 度约为 111 公里', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      recorder.addTrackPoint(_point(1, 0, 1000));
      expect(recorder.calculateTotalDistance(), closeTo(111194.9, 50));
    });

    test('多段距离为相邻点距离之和', () {
      recorder.startRecording();
      recorder.addTrackPoint(_point(0, 0, 0));
      recorder.addTrackPoint(_point(1, 0, 1000));
      recorder.addTrackPoint(_point(2, 0, 2000));
      expect(recorder.calculateTotalDistance(), closeTo(111194.9 * 2, 100));
    });
  });
}
