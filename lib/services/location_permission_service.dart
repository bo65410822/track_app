import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionResult { granted, denied, permanentlyDenied }

class LocationPermissionService {

  const LocationPermissionService();

  LocationPermissionResult _map(PermissionStatus status) {
    if (status == PermissionStatus.granted) {
      return LocationPermissionResult.granted;
    } else if (status == PermissionStatus.denied) {
      return LocationPermissionResult.denied;
    } else {
      return LocationPermissionResult.permanentlyDenied;
    }
  }

  /// 查询当前定位权限状态（不触发系统弹窗）
  Future<LocationPermissionResult> checkPermission() {
    return Permission.location.status.then(_map);
  }

  /// 请求定位权限（会触发系统弹窗）
  Future<LocationPermissionResult> requestPermission() {
    return Permission.location.request().then(_map);
  }

  /// 跳转系统设置页（永久拒绝时用）
  Future<bool> openSettings() => openAppSettings();
}