import 'package:flutter_bluetooth_connect/ble_connection_bloc.dart';
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
  final bleConnectionBloc = BLEConnectionBloc();
  //final Uuid ledgerUuid = Uuid.parse("D43FD8C2-326E-993C-D180-31B0B5114988");

  void _startScan() async {
    bleConnectionBloc.findDevices("D43FD8C2-326E-993C-D180-31B0B5114988");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<DiscoveredDevice>>(
        initialData: const <DiscoveredDevice>[],
        stream: bleConnectionBloc.foundDevices,
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
                  bleConnectionBloc.connectToDevice(device);
                },
              );
            },
          );
        },
      ),
      persistentFooterButtons: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            primary: Colors.blue, // background
            onPrimary: Colors.white, // foreground
          ),
          onPressed: _startScan,
          child: const Icon(Icons.search),
        ),
      ],
    );
  }
}
