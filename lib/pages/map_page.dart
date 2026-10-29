import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:track_app/pages/home/locating_hint.dart';
import 'package:track_app/pages/home/record_controls.dart';
import 'package:track_app/pages/home/stats_card.dart';
import 'package:track_app/pages/widgets/app_top_bar.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../data/saved_track.dart';
import '../main.dart';
import '../privacy/privacy_gate.dart';
import '../services/location_permission_service.dart';
import '../track/track_point.dart';
import '../track/track_recorder.dart';
import '../track/track_save_service.dart';
import '../utils/map_utils.dart';
import 'history_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  AMapController? _mapController;

  AMapLocation? _latestLocation;

  bool _permissionChecked = false;
  bool _locationGranted = false;
  bool _hasCenteredOnUser = false;

  bool _permissionRequestInFlight = false;
  bool _amapInitialized = false;

  final TrackRecorder _recorder = TrackRecorder();

  final TrackSaveService _trackSaveService = const TrackSaveService();

  // 当前选择的运动类型，默认跑步
  SportType _selectedType = SportType.run;

  // 停止记录后等待截图：fitBounds 相机停稳后生成缩略图
  bool _pendingSnapshot = false;
  int? _pendingSnapshotTrackId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var privacyGate = const PrivacyGate();
      final passed = await privacyGate.ensureConsent(context);
      if (!passed || !mounted) return;
      await _initializeAmap();
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
    _mapController = null;
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
    _saveTrackData();
  }

  Future<void> _saveTrackData() async {
    try {
      final trackId = await _trackSaveService.save(
        points: _recorder.points,
        type: _selectedType,
        duration: _recorder.duration,
        distance: _recorder.calculateTotalDistance(),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存轨迹失败')));
    }
  }

  /// 相机停止移动：若处于待截图状态，等瓦片渲染后截图并保存为缩略图
  void _onCameraMoveEnd(CameraPosition position) {
    if (!_pendingSnapshot) return;
    _pendingSnapshot = false; // 只截这一次
    final trackId = _pendingSnapshotTrackId;
    if (trackId == null) return;

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        final controller = _mapController;
        if (controller == null) return;
        final bytes = await controller.takeSnapshot();
        if (bytes == null) return;
        await _trackSaveService.saveThumbnail(trackId: trackId, bytes: bytes);
      } catch (e) {
        debugPrint('$e');
      }
      _pendingSnapshotTrackId = null;
    });
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
      final locationPermission = const LocationPermissionService();
      final result = await locationPermission.requestPermission();
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionChecked = true;
        _locationGranted = result == LocationPermissionResult.granted;
      });
      switch (result) {
        case LocationPermissionResult.granted:
          // 位置权限已授予
          break;
        case LocationPermissionResult.denied:
          // 位置权限被拒绝
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('需要定位权限才能显示当前位置')));
          break;
        case LocationPermissionResult.permanentlyDenied:
          await locationPermission.openSettings();
          break;
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
      appBar: AppTopBar(
        title: '轨迹记',
        leadingIcon: Icons.directions_run,
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
            myLocationStyleOptions: MyLocationStyleOptions(
              _locationGranted,
              circleFillColor: Colors.transparent,
              circleStrokeColor: Colors.transparent,
              circleStrokeWidth: 0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // 如果定位已经先到达，这里补一次居中
              _centerOnUserOnce(_latestLocation);
            },
            onCameraMoveEnd: _onCameraMoveEnd,
            onLocationChanged: _onLocationChanged,
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
        _recorder.isRecording ? _stopRecording() : _startRecording();
      },
    );
  }

  void _centerOnUserOnce(AMapLocation? location) {
    if (_hasCenteredOnUser) return;
    if (location == null || _mapController == null) return;

    setState(() {
      _hasCenteredOnUser = true;
    });
    _mapController!.moveCamera(CameraUpdate.newLatLngZoom(location.latLng, 16));
  }

  void _recordLocation(AMapLocation location) {
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
  }

  void _onLocationChanged(AMapLocation location) {
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
    _centerOnUserOnce(location);
    _recordLocation(location);
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
