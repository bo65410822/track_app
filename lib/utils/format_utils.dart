String formatDistance(double distance) {
  if (distance < 1000) {
    return '${distance.round()}m';
  } else {
    return '${(distance / 1000).toStringAsFixed(2)}km';
  }
}

String formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
