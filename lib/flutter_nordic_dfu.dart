import 'dart:async';

import 'package:flutter/services.dart';

class FlutterNordicDfu {
  static const String NAMESPACE = 'com.timeyaa.flutter_nordic_dfu';

  static const MethodChannel _channel =
      const MethodChannel('$NAMESPACE/method');

  /// Start dfu handle
  /// [address] android: mac address iOS: device uuid
  /// [filePath] zip file path
  /// [name] device name
  /// [progressListener] Dfu progress listener
  static startDfu(
    String address,
    String filePath, {
    String name,
    DfuProgressListenerAdapter progressListener,
    bool fileInAsset,
  }) async {
    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "onDeviceConnected":
          progressListener?.onDeviceConnected(call.arguments);
          break;
        case "onDeviceConnecting":
          progressListener?.onDeviceConnecting(call.arguments);
          break;
        case "onDeviceDisconnected":
          progressListener?.onDeviceDisconnected(call.arguments);
          break;
        case "onDeviceDisconnecting":
          progressListener?.onDeviceDisconnecting(call.arguments);
          break;
        case "onDfuAborted":
          progressListener?.onDfuAborted(call.arguments);
          break;
        case "onDfuCompleted":
          progressListener?.onDfuCompleted(call.arguments);
          break;
        case "onDfuProcessStarted":
          progressListener?.onDfuProcessStarted(call.arguments);
          break;
        case "onDfuProcessStarting":
          progressListener?.onDfuProcessStarting(call.arguments);
          break;
        case "onEnablingDfuMode":
          progressListener?.onEnablingDfuMode(call.arguments);
          break;
        case "onFirmwareValidating":
          progressListener?.onFirmwareValidating(call.arguments);
          break;
        case "onError":
          progressListener?.onError(
            call.arguments['deviceAddress'],
            call.arguments['error'],
            call.arguments['errorType'],
            call.arguments['message'],
          );
          break;
        case "onProgressChanged":
          progressListener?.onProgressChanged(
            call.arguments['deviceAddress'],
            call.arguments['percent'],
            call.arguments['speed'],
            call.arguments['avgSpeed'],
            call.arguments['currentPart'],
            call.arguments['partsTotal'],
          );
          break;
        default:
          break;
      }
    });

    _channel.invokeMethod('startDfu', {
      'address': address,
      'filePath': filePath,
      'name': name,
      'fileInAsset': fileInAsset
    });
  }
}

abstract class DfuProgressListenerAdapter {
  void onDeviceConnected(String deviceAddress) {}

  void onDeviceConnecting(String deviceAddress) {}

  void onDeviceDisconnected(String deviceAddress) {}

  void onDeviceDisconnecting(String deviceAddress) {}

  void onDfuAborted(String deviceAddress) {}

  void onDfuCompleted(String deviceAddress) {}

  void onDfuProcessStarted(String deviceAddress) {}

  void onDfuProcessStarting(String deviceAddress) {}

  void onEnablingDfuMode(String deviceAddress) {}

  void onFirmwareValidating(String deviceAddress) {}

  void onError(
      String deviceAddress, int error, int errorType, String message) {}

  void onProgressChanged(String deviceAddress, int percent, double speed,
      double avgSpeed, int currentPart, int partsTotal) {}
}
