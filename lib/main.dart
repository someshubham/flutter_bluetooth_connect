import 'dart:async';

import 'package:flutter_bluetooth_connect/ble_connection_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_connect/dialogs/loading_dialog.dart';
import 'package:flutter_bluetooth_connect/widgets/chasing_dots_indicator.dart';
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
  final bleConnectionBloc = BLEConnectionBloc();
  final uuidController = TextEditingController();
  //final Uuid ledgerUuid = Uuid.parse("D43FD8C2-326E-993C-D180-31B0B5114988");

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
    //"D43FD8C2-326E-993C-D180-31B0B5114988"
    bleConnectionBloc.findDevices(uuid);
  }

  void connectToDevice(DiscoveredDevice device) {
    showLoader(context);
    final connectionStream = bleConnectionBloc.connectToDevice(device);
    connectionSubscription = connectionStream.listen((event) {
      if (event.failure?.code == ConnectionError.unknown ||
          event.failure?.code == ConnectionError.failedToConnect) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }

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
    });
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
            child: TextField(
              controller: uuidController,
              decoration: const InputDecoration(
                labelText: "Ledger UUID",
                hintText: "Enter Ledger UUID",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
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
            child: StreamBuilder<DiscoveredDevice>(
              stream: bleConnectionBloc.foundDevice,
              builder: (context, snapshot) {
                if (!_hasStartedSearch && !snapshot.hasData) {
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

                if (_hasStartedSearch && !snapshot.hasData) {
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
                  title: Text(snapshot.data!.name),
                  subtitle: Text(snapshot.data!.id),
                  trailing: _isDeviceConnected
                      ? const Text(
                          "Connected",
                          style: TextStyle(
                            color: Colors.grey,
                          ),
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

  @override
  void dispose() {
    super.dispose();
    connectionSubscription?.cancel();
  }
}
