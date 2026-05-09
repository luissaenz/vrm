import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:vrm_app/core/services/logger_service.dart';

class DeviceInfo {
  final String model;
  final String brand;
  final String id;
  final DateTime? installDate;

  DeviceInfo({
    required this.model,
    required this.brand,
    required this.id,
    this.installDate,
  });

  factory DeviceInfo.unknown() =>
      DeviceInfo(model: 'Unknown Device', brand: 'Unknown', id: 'unknown');
}

class DeviceInfoService {
  static final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  static DeviceInfoService? _instance;
  DeviceInfoService._();
  static DeviceInfoService get instance {
    _instance ??= DeviceInfoService._();
    return _instance!;
  }

  Future<DeviceInfo> getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _plugin.androidInfo;
        return DeviceInfo(
          model: androidInfo.model,
          brand: androidInfo.brand,
          id: androidInfo.id,
        );
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _plugin.iosInfo;
        return DeviceInfo(
          model: iosInfo.utsname.machine,
          brand: 'Apple',
          id: iosInfo.identifierForVendor ?? 'unknown',
        );
      } else {
        return DeviceInfo.unknown();
      }
    } catch (e) {
      LoggerService.log('device_info_service', 'DeviceInfoService Error: $e');
      return DeviceInfo.unknown();
    }
  }
}
