import 'dart:async';
import 'dart:io';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:location_permissions/location_permissions.dart';

class BLEConnectionBloc {
  final flutterReactiveBle = FlutterReactiveBle();
  final _devices = <DiscoveredDevice>[];

  final _deviceListController = StreamController<List<DiscoveredDevice>>();

  late StreamSubscription<DiscoveredDevice> _scanStream;
  late StreamSubscription<ConnectionStateUpdate> _connectionStream;

  Stream<List<DiscoveredDevice>> get foundDevices {
    return _deviceListController.stream;
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
      ).listen((device) {
        if (device.id == deviceUuid) {
          _scanStream.cancel();
          _devices.add(device);
          _deviceListController.add(_devices);
        }
        // if (device.name.isNotEmpty) {
        //   final alreadyAdded =
        //       _devices.any((element) => element.id == device.id);

        //   if (!alreadyAdded) {
        //     _devices.add(device);
        //     _deviceListController.add(_devices);
        //   }
        // }
      });
    }
  }

  void connectToDevice(DiscoveredDevice uniqueDevice) {
    _scanStream.cancel();
    Stream<ConnectionStateUpdate> currentConnectionStream =
        flutterReactiveBle.connectToAdvertisingDevice(
      id: uniqueDevice.id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [],
    );
    _connectionStream = currentConnectionStream.listen((event) async {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            // setState(() {
            //   _foundDeviceWaitingToConnect = false;
            //   _connected = true;
            // });
            print("Device Connected");
            break;
          }
        // Can add various state state updates on disconnect
        case DeviceConnectionState.disconnected:
          {
            break;
          }
        default:
      }
    });
  }

  void dispose() {
    _scanStream.cancel();
    _connectionStream.cancel();
    _deviceListController.close();
  }
}
