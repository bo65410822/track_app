import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track_app/privacy.dart';
import 'package:x_amap_base/x_amap_base.dart';

void main() {
  runApp(const TrackApp());
}

class TrackApp extends StatelessWidget {
  const TrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '轨迹记',
      home: MapPage(),
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
    await preferences.setInt(
      _privacyVersionKey,
      _currentPrivacyVersion,
    );

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
            .showSnackBar(
            const SnackBar(content: Text('需要定位权限才能显示当前位置')));
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
    } else {
      // 创建地图
      return Scaffold(
        appBar: AppBar(title: const Text('轨迹记')),
        body: AMapWidget(
          myLocationStyleOptions: MyLocationStyleOptions(_locationGranted),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onLocationChanged: (location) {
            if (!isLocationValid(location)) {
              debugPrint(
                'no valid location result ：${location
                    .latLng}, accuracy：${location.accuracy}',
              );
              return;
            }
            debugPrint(
              'location result ：${location.latLng}, accuracy：${location
                  .accuracy}',
            );
            _latestLocation = location;
            if (!_hasCenteredOnUser) {
              _hasCenteredOnUser = true;
              _mapController?.moveCamera(
                CameraUpdate.newLatLng(location.latLng),
              );
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _moveToUserLocation,
          child: const Icon(Icons.my_location),
        ),
      );
    }
  }
}
