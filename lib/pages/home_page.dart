import 'dart:io';

import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_app/pages/home/locating_hint.dart';
import 'package:track_app/pages/home/record_controls.dart';
import 'package:track_app/pages/home/stats_card.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/saved_track.dart';
import '../data/track_database.dart';
import '../main.dart';
import '../privacy.dart';
import '../track/track_point.dart';
import '../track/track_recorder.dart';
import '../utils/map_utils.dart';
import 'history_page.dart';

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

  // 当前选择的运动类型，默认跑步
  SportType _selectedType = SportType.run;

  // 停止记录后等待截图：fitBounds 相机停稳后生成缩略图
  bool _pendingSnapshot = false;
  int? _pendingSnapshotTrackId;

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
    final trackId = await TrackDatabase.instance.insertTrack(
      SavedTrack(
        startTime: _recorder.points.first.timestamp,
        endTime: _recorder.points.last.timestamp,
        duration: duration.inMilliseconds,
        distance: distance,
        pointCount: _recorder.points.length,
        type: _selectedType.code,
      ),
      _recorder.points,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('轨迹已保存')));

    // 触发缩略图：把地图缩放到整条轨迹，相机停稳后（onCameraMoveEnd）截图
    _pendingSnapshotTrackId = trackId;
    _pendingSnapshot = true;
    _mapController?.moveCamera(
      fitTrackCameraUpdate(toLatLngList(_recorder.points)),
    );
  }

  /// 相机停止移动：若处于待截图状态，等瓦片渲染后截图并保存为缩略图
  void _onCameraMoveEnd(CameraPosition position) {
    if (!_pendingSnapshot) return;
    _pendingSnapshot = false; // 只截这一次
    final trackId = _pendingSnapshotTrackId;
    if (trackId == null) return;

    Future.delayed(const Duration(milliseconds: 500), () async {
      final controller = _mapController;
      if (controller == null) return;
      final bytes = await controller.takeSnapshot();
      if (bytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/thumb_$trackId.png';
      await File(path).writeAsBytes(bytes);
      await TrackDatabase.instance.updateThumbnail(trackId, path);
      _pendingSnapshotTrackId = null;
    });
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
        CameraUpdate.newLatLngZoom(_latestLocation!.latLng, 16),
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
              // 如果定位已经先到达，这里补一次居中
              if (!_hasCenteredOnUser && _latestLocation != null) {
                setState(() {
                  _hasCenteredOnUser = true;
                });
                controller.moveCamera(
                  CameraUpdate.newLatLngZoom(_latestLocation!.latLng, 16),
                );
              }
            },
            onCameraMoveEnd: _onCameraMoveEnd,
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
              if (!_hasCenteredOnUser && _mapController != null) {
                setState(() {
                  _hasCenteredOnUser = true;
                });
                _mapController!.moveCamera(
                  CameraUpdate.newLatLngZoom(location.latLng, 16),
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
            child: StatsCard(distance: distance, duration: duration),
          ),

          // 首次定位中的提示
          if (!_hasCenteredOnUser)
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: Center(child: const LocatingHint()),
            ),

          // 右下角定位按钮
          Positioned(right: 16, bottom: 110, child: _buildLocateButton()),

          // 底部开始/停止记录按钮
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: _buildRecordControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordControls() {
    return RecordControls(
      isRecording: _recorder.isRecording,
      selectedType: _selectedType,
      onTypeChanged: (type) {
        setState(() {
          _selectedType = type;
        });
      },
      onRecordPressed: () {
        setState(() {
          _recorder.isRecording ? _stopRecording() : _startRecording();
        });
      },
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
}
