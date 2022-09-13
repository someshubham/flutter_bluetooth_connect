import 'dart:async';
import 'dart:io';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location_permissions/location_permissions.dart';

class BLEConnectionBloc {
  final flutterReactiveBle = FlutterReactiveBle();

  final _deviceController = StreamController<DiscoveredDevice>();

  late StreamSubscription<DiscoveredDevice> _scanStream;
  late StreamSubscription<ConnectionStateUpdate> _connectionStream;

  Stream<DiscoveredDevice> get foundDevice {
    return _deviceController.stream;
  }

  Future<bool> _getPermission() async {
    bool permGranted = false;
    PermissionStatus permission;
    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }

    return permGranted;
  }

  Future<void> findDevices(String deviceUuid) async {
    final permGranted = await _getPermission();
    if (permGranted) {
      _scanStream = flutterReactiveBle.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency,
      ).listen((device) {
        if (device.id == deviceUuid) {
          _deviceController.add(device);
          stopSearching();
        }
      });
    }
  }

  void stopSearching() {
    _scanStream.cancel();
  }

  Stream<ConnectionStateUpdate> connectToDevice(DiscoveredDevice uniqueDevice) {
    Stream<ConnectionStateUpdate> currentConnectionStream =
        flutterReactiveBle.connectToAdvertisingDevice(
      id: uniqueDevice.id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [],
    );

    return currentConnectionStream;
    // _connectionStream = currentConnectionStream.listen((event) async {
    //   switch (event.connectionState) {
    //     // We're connected and good to go!
    //     case DeviceConnectionState.connected:
    //       {
    //         // setState(() {
    //         //   _foundDeviceWaitingToConnect = false;
    //         //   _connected = true;
    //         // });
    //         print("Device Connected");
    //         break;
    //       }
    //     // Can add various state state updates on disconnect
    //     case DeviceConnectionState.disconnected:
    //       {
    //         break;
    //       }
    //     default:
    //   }
    // });
  }

  void dispose() {
    _scanStream.cancel();
    _connectionStream.cancel();
    _deviceController.close();
  }
}
