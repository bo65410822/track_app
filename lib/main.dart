import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_app/data/saved_track.dart';
import 'package:track_app/data/track_database.dart';
import 'package:track_app/privacy.dart';
import 'package:track_app/track/track_point.dart';
import 'package:track_app/track/track_recorder.dart';
import 'package:track_app/utils/format_utils.dart';
import 'package:track_app/utils/map_utils.dart';
import 'package:x_amap_base/x_amap_base.dart';

import 'history_page.dart';

/// 主题色
const Color kPrimaryColor = Color(0xFF009688);
const Color kRecordingColor = Color(0xFFE53935);

void main() {
  runApp(const TrackApp());
}

class TrackApp extends StatelessWidget {
  const TrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '轨迹记',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688), // 青绿主色
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F7F4),
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  static const int _currentPrivacyVersion = 1;
  static const String _privacyVersionKey = 'privacy_consent_version';

  AMapController? _mapController;

  AMapLocation? _latestLocation;

  bool _permissionChecked = false;
  bool _locationGranted = false;
  bool _hasCenteredOnUser = false;

  bool _permissionRequestInFlight = false;
  bool _amapInitialized = false;

  final TrackRecorder _recorder = TrackRecorder();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrivacyConsent();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _amapInitialized && mounted) {
      _requestLocationPermission();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recorder.startRecording();
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _recorder.stopRecording();
    });

    if (_recorder.points.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('轨迹太短，未保存')));
      return;
    }

    final double distance = _recorder.calculateTotalDistance();
    final Duration duration = _recorder.duration;
    await TrackDatabase.instance.insertTrack(
      SavedTrack(
        startTime: _recorder.points.first.timestamp,
        endTime: _recorder.points.last.timestamp,
        duration: duration.inMilliseconds,
        distance: distance,
        pointCount: _recorder.points.length,
      ),
      _recorder.points,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('轨迹已保存')));
  }

  Future<void> _checkPrivacyConsent() async {
    final preferences = await SharedPreferences.getInstance();
    final agreedVersion = preferences.getInt(_privacyVersionKey);

    if (!mounted) {
      return;
    }

    if (agreedVersion == _currentPrivacyVersion) {
      // 隐私协议已同意
      await _initializeAmap();
    } else {
      // 需要更新隐私协议
      await _handlePrivacyConsent();
    }
  }

  Future<void> _handlePrivacyConsent() async {
    final agree = await showPrivacyConsentDialog(context);
    if (!mounted) {
      return;
    }
    if (!agree) {
      await SystemNavigator.pop();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_privacyVersionKey, _currentPrivacyVersion);

    await _initializeAmap();
  }

  Future<void> _initializeAmap() async {
    if (!mounted) {
      return;
    }

    AMapInitializer.init(context);
    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );

    _amapInitialized = true;

    await _requestLocationPermission();
  }

  // 请求位置权限
  Future<void> _requestLocationPermission() async {
    if (_permissionRequestInFlight) {
      return;
    }
    _permissionRequestInFlight = true;
    try {
      final status = await Permission.location.request();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionChecked = true;
        _locationGranted = status.isGranted;
      });
      if (status.isGranted) {
        // 位置权限已授予
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      } else {
        // 位置权限被拒绝
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('需要定位权限才能显示当前位置')));
      }
    } finally {
      _permissionRequestInFlight = false;
    }
  }

  void _moveToUserLocation() {
    if (_latestLocation != null) {
      _mapController?.moveCamera(
        CameraUpdate.newLatLng(_latestLocation!.latLng),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先获取位置信息')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final double distance = _recorder.calculateTotalDistance();
    final Duration duration = _recorder.duration;
    final latLngList = toLatLngList(_recorder.points);
    final Set<Polyline> polylines = latLngList.length >= 2
        ? {
            Polyline(
              points: latLngList,
              color: kPrimaryColor,
              width: 6,
              capType: CapType.round,
              joinType: JoinType.round,
            ),
          }
        : <Polyline>{};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF5F0),
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: const [
            Icon(Icons.directions_run, color: kPrimaryColor),
            SizedBox(width: 8),
            Text(
              '轨迹记',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const HistoryPage()),
              );
            },
            icon: const Icon(Icons.history, color: kPrimaryColor),
            label: const Text(
              '历史记录',
              style: TextStyle(color: kPrimaryColor, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AMapWidget(
            myLocationStyleOptions: MyLocationStyleOptions(_locationGranted),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onLocationChanged: (location) {
              if (!isLocationValid(location)) {
                debugPrint(
                  'no valid location result ：${location.latLng}, accuracy：${location.accuracy}',
                );
                return;
              }
              debugPrint(
                'location result ：${location.latLng}, accuracy：${location.accuracy}',
              );
              _latestLocation = location;
              if (!_hasCenteredOnUser) {
                _hasCenteredOnUser = true;
                _mapController?.moveCamera(
                  CameraUpdate.newLatLng(location.latLng),
                );
              }
              _recorder.addTrackPoint(
                TrackPoint(
                  latitude: location.latLng.latitude,
                  longitude: location.latLng.longitude,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                ),
              );
              if (_recorder.isRecording) {
                setState(() {});
              }
            },
            polylines: polylines,
          ),

          // 顶部距离/时长信息卡片
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _buildStatsCard(distance, duration),
          ),

          // 右下角定位按钮
          Positioned(
            right: 16,
            bottom: 110,
            child: _buildLocateButton(),
          ),

          // 底部开始/停止记录按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: _buildRecordButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(double distance, Duration duration) {
    final kmText = (distance / 1000).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem(Icons.route, '距离', kmText, '公里'),
          Container(width: 1, height: 34, color: const Color(0xFFE0E0E0)),
          _statItem(
            Icons.timer_outlined,
            '时长',
            formatDuration(duration),
            null,
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, String? unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 4),
                  Text(unit,
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
    );
  }

  Widget _buildLocateButton() {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _moveToUserLocation,
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.my_location, color: kPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildRecordButton() {
    final recording = _recorder.isRecording;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recording)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.circle, size: 10, color: kRecordingColor),
                SizedBox(width: 6),
                Text(
                  '正在记录',
                  style: TextStyle(
                    color: kRecordingColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: recording ? _stopRecording : _startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: recording ? kRecordingColor : kPrimaryColor,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 4,
            ),
            icon: Icon(recording ? Icons.stop : Icons.play_arrow, size: 20),
            label: Text(
              recording ? '停止记录' : '开始记录',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
