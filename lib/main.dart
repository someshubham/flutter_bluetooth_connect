import 'dart:async';
import 'dart:io' show Platform;

import 'package:location_permissions/location_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

void main() {
  return runApp(
    const MaterialApp(home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
// Some state management stuff
  bool _foundDeviceWaitingToConnect = false;
  bool _scanStarted = false;
  bool _connected = false;
// Bluetooth related variables
  late DiscoveredDevice _ubiqueDevice;
  final flutterReactiveBle = FlutterReactiveBle();
  late StreamSubscription<DiscoveredDevice> _scanStream;
  late QualifiedCharacteristic _rxCharacteristic;
  final Uuid ledgerUuid = Uuid.parse("D43FD8C2-326E-993C-D180-31B0B5114988");

  List<DiscoveredDevice> devices = [];

  StreamController<List<DiscoveredDevice>> deviceListController =
      StreamController<List<DiscoveredDevice>>();

  void _startScan() async {
// Platform permissions handling stuff
    bool permGranted = false;
    setState(() {
      _scanStarted = true;
    });
    PermissionStatus permission;
    if (Platform.isAndroid) {
      permission = await LocationPermissions().requestPermissions();
      if (permission == PermissionStatus.granted) permGranted = true;
    } else if (Platform.isIOS) {
      permGranted = true;
    }
// Main scanning logic happens here ⤵️
    if (permGranted) {
      _scanStream = flutterReactiveBle.scanForDevices(
        withServices: [],
      ).listen((device) {
        if (device.name.isNotEmpty) {
          final alreadyAdded =
              devices.any((element) => element.id == device.id);

          if (!alreadyAdded) {
            devices.add(device);
            deviceListController.add(devices);
          }
        }
      });
    }
  }

  void _connectToDevice() {
    // We're done scanning, we can cancel it
    _scanStream.cancel();
    // Let's listen to our connection so we can make updates on a state change
    Stream<ConnectionStateUpdate> _currentConnectionStream =
        flutterReactiveBle.connectToAdvertisingDevice(
      id: _ubiqueDevice.id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [],
    );
    _currentConnectionStream.listen((event) async {
      switch (event.connectionState) {
        // We're connected and good to go!
        case DeviceConnectionState.connected:
          {
            final data =
                await flutterReactiveBle.discoverServices(_ubiqueDevice.id);

            _rxCharacteristic = QualifiedCharacteristic(
                serviceId: data.first.serviceId,
                characteristicId: data.first.characteristicIds.first,
                deviceId: event.deviceId);
            setState(() {
              _foundDeviceWaitingToConnect = false;
              _connected = true;
            });
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

  void performOperation() async {
    if (_connected) {
      final data =
          await flutterReactiveBle.readCharacteristic(_rxCharacteristic);
      // flutterReactiveBle
      //     .writeCharacteristicWithResponse(_rxCharacteristic, value: [
      //   0xff,
      // ]);
      final modifiedData = String.fromCharCodes(data);
      print(modifiedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<DiscoveredDevice>>(
        initialData: const <DiscoveredDevice>[],
        stream: deviceListController.stream,
        builder: (context, snapshot) {
          if (snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Click on Search to find Devices"),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final device = snapshot.data![index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text(device.id),
                onTap: () {
                  setState(() {
                    _ubiqueDevice = device;
                    _foundDeviceWaitingToConnect = true;
                  });
                },
              );
            },
          );
        },
      ),
      persistentFooterButtons: [
        // We want to enable this button if the scan has NOT started
        // If the scan HAS started, it should be disabled.
        _scanStarted
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.search),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _startScan,
                child: const Icon(Icons.search),
              ),
        _foundDeviceWaitingToConnect
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: _connectToDevice,
                child: const Icon(Icons.bluetooth),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.bluetooth),
              ),
        _connected
            // True condition
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: performOperation,
                child: const Icon(Icons.celebration_rounded),
              )
            // False condition
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.grey, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {},
                child: const Icon(Icons.celebration_rounded),
              ),
      ],
    );
  }
}
