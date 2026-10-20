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
}
