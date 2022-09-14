import 'dart:async';

import 'package:flutter_bluetooth_connect/ble_connection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_connect/dialogs/loading_dialog.dart';
import 'package:flutter_bluetooth_connect/utils/qr_scan_util.dart';
import 'package:flutter_bluetooth_connect/widgets/chasing_dots_indicator.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

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
  final bleConnectionBloc = BLEConnectionBloc();
  final uuidController = TextEditingController();

  bool _hasStartedSearch = false;
  bool _isDeviceConnected = false;

  StreamSubscription<ConnectionStateUpdate>? connectionSubscription;

  void validateAndScan() {
    if (uuidController.text.isNotEmpty) {
      setState(() {
        _hasStartedSearch = true;
      });
      _startScan(uuid: uuidController.text);
    }
  }

  void _startScan({required String uuid}) async {
    //This is the UUID for available Ledger "D43FD8C2-326E-993C-D180-31B0B5114988"
    bleConnectionBloc.findDevices(uuid);
  }

  void connectToDevice(DiscoveredDevice device) {
    showLoader(context);
    final connectionStream = bleConnectionBloc.connectToDevice(device);
    connectionSubscription = connectionStream.listen((event) {
      handleConnectionEventChange(event);
    });
  }

  // TODO(someshubham): Fix Disconnecting a device, never gets scanned again
  // Find the description in the issue created here https://github.com/PhilipsHue/flutter_reactive_ble/issues/575
  void disconnectDevice() {
    setState(() {
      _isDeviceConnected = false;
    });
    connectionSubscription?.cancel();
  }

  void handleConnectionEventChange(ConnectionStateUpdate event) {
    handleOnConnectionError(event);

    switch (event.connectionState) {
      // We're connected and good to go!
      case DeviceConnectionState.connected:
        {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          setState(() {
            _isDeviceConnected = true;
          });
          break;
        }
      // Can add various state state updates on disconnect
      case DeviceConnectionState.disconnected:
        {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          break;
        }
      default:
    }
  }

  void handleOnConnectionError(ConnectionStateUpdate event) {
    if (event.failure?.code == ConnectionError.unknown ||
        event.failure?.code == ConnectionError.failedToConnect) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Text(
              "Connect Ledger",
              style: TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: uuidController,
                    decoration: const InputDecoration(
                      labelText: "Ledger UUID",
                      hintText: "Enter Ledger UUID",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: () => scanQrCode(context),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOpacity(
                opacity: _isDeviceConnected ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 2,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      validateAndScan();
                    },
                    icon: const Icon(Icons.search),
                    label: const Text("Search"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          const Divider(),
          const SizedBox(
            height: 16,
          ),
          Expanded(
            child: StreamBuilder<DiscoveredDevice?>(
              stream: bleConnectionBloc.foundDevice,
              builder: (context, snapshot) {
                if (!_hasStartedSearch && snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text("Enter Ledger UUID"),
                        Text("& Press Search"),
                      ],
                    ),
                  );
                }

                if (_hasStartedSearch && snapshot.data == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text("Finding Ledger..."),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasStartedSearch = false;
                            });
                            bleConnectionBloc.stopSearching();
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("Cancel"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            primary: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListTile(
                  title: Row(
                    children: [
                      Text(snapshot.data!.name),
                      const SizedBox(width: 6),
                      if (_isDeviceConnected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(
                              color: Colors.green,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Connected",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(snapshot.data!.id),
                  ),
                  trailing: _isDeviceConnected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Disconnect",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                disconnectDevice();
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            connectToDevice(snapshot.data!);
                          },
                          icon: const Icon(Icons.bluetooth),
                          label: const Text("Connect"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void showLoader(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LoadingDialog(
        canceable: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
          width: MediaQuery.of(context).size.width * 0.3,
          child: const ChasingDotsIndicator(),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> scanQrCode(BuildContext context) async {
    await Future.delayed(const Duration(milliseconds: 10), () {
      FocusScope.of(context).unfocus();
    });

    final res = await QRScanUtil.scan(context);
    if (res.isNotEmpty) {
      if (res[1]) {
        if (res[2] == ResultType.Cancelled) {
          return;
        }
        final String qrCode = res[0];
        uuidController.text = qrCode.trim();
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    connectionSubscription?.cancel();
  }
}
