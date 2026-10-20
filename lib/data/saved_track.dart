class SavedTrack {
  final int? id;
  final int startTime;
  final int endTime;
  final int duration;
  final double distance;
  final int pointCount;

  SavedTrack({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distance,
    required this.pointCount,
  });
}
