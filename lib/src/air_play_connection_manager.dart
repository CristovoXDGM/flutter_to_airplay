import 'package:flutter/services.dart';

class AirplayConnectionManager {
  static const MethodChannel _channel = MethodChannel('flutter_to_airplay');

  static Future<void> startMonitoring(
      {Function(bool)? onConnectionChanged}) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAirplayConnectionChanged') {
        final args = call.arguments as Map;
        final connected = args['connected'] as bool;
        onConnectionChanged?.call(connected);
      }
    });

    await _channel.invokeMethod('startMonitoringAirplayConnection');
  }

  static Future<void> stopMonitoring() async {
    await _channel.invokeMethod('stopMonitoringAirplayConnection');
  }

  static Future<bool> isConnectedToAirplay() async {
    return await _channel.invokeMethod('isConnectedToAirplay');
  }

  static Future<void> disconnectFromAirplay() async {
    await _channel.invokeMethod('disconnectFromAirplay');
  }
}
