import 'package:flutter_test/flutter_test.dart';
import 'package:track_app/utils/format_utils.dart';

void main() {
  group('formatDistance', () {
    test('0 米显示为 0m', () {
      expect(formatDistance(0), '0m');
    });

    test('米段四舍五入为整数', () {
      expect(formatDistance(1), '1m');
      expect(formatDistance(853.4), '853m');
      expect(formatDistance(853.6), '854m');
      expect(formatDistance(999), '999m');
      expect(formatDistance(999.4), '999m');
    });

    test('正好 1000 米进位为公里', () {
      expect(formatDistance(1000), '1.00km');
    });

    test('公里段保留两位小数', () {
      expect(formatDistance(1500), '1.50km');
      expect(formatDistance(1850), '1.85km');
      expect(formatDistance(2000), '2.00km');
    });
  });

  group('formatDuration', () {
    test('0 秒显示为 00:00:00', () {
      expect(formatDuration(Duration.zero), '00:00:00');
    });

    test('一小时以内始终显示 hh:mm:ss', () {
      expect(formatDuration(const Duration(seconds: 5)), '00:00:05');
      expect(formatDuration(const Duration(seconds: 59)), '00:00:59');
      expect(formatDuration(const Duration(seconds: 60)), '00:01:00');
      expect(formatDuration(const Duration(seconds: 61)), '00:01:01');
      expect(formatDuration(const Duration(seconds: 599)), '00:09:59');
      expect(formatDuration(const Duration(seconds: 600)), '00:10:00');
      expect(formatDuration(const Duration(seconds: 3599)), '00:59:59');
    });

    test('一小时及以上显示 hh:mm:ss', () {
      expect(formatDuration(const Duration(seconds: 3600)), '01:00:00');
      expect(formatDuration(const Duration(seconds: 3661)), '01:01:01');
      expect(formatDuration(const Duration(seconds: 7325)), '02:02:05');
    });
  });
}
