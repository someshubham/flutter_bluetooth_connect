import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:velocity_x/velocity_x.dart';

mixin QRScanUtil {
  static Future<List> scan(BuildContext context) async {
    final List<dynamic> barcodeResult =
        List<dynamic>.filled(3, null, growable: false);
    final Barcode? res = await context.push((context) => QRViewScreen());
    if (res != null && res.code != null) {
      final String content = res.code!;
      final startIndex = content.contains(RegExp(r'://'))
          ? content.lastIndexOf(RegExp(r'://')) + 3
          : 0;
      barcodeResult[0] = content.substring(startIndex);
      barcodeResult[1] = true;
      barcodeResult[2] = res.format.formatName;
      return barcodeResult;
    }
    barcodeResult[0] = "Something Went Wrong";
    barcodeResult[1] = false;
    barcodeResult[2] = "Some error occured";
    return barcodeResult;
  }

//   static Future<List> scan1(BuildContext context) async {
//     final List<dynamic> barcodeResult = List<dynamic>(3);
//     try {
//       final ScanResult barcode = await BarcodeScanner.scan();
//       final content = barcode.rawContent;
//       // To remove the wallet name or chain name before address
//       final startIndex = content.contains(RegExp(r'://'))
//           ? content.lastIndexOf(RegExp(r'://')) + 3
//           : 0;
//       barcodeResult[0] = content.substring(startIndex);
//       barcodeResult[1] = true;
//       barcodeResult[2] = barcode.type;
//       return barcodeResult;
//     } on PlatformException catch (e) {
//       if (e.code == BarcodeScanner.cameraAccessDenied) {
//         barcodeResult[0] = 'You need to grant the camera permission!';
//         showPermissionDialog(context);
//       } else {
//         barcodeResult[0] = 'Unknown error: $e';
//       }
//     } on FormatException {
//       barcodeResult[0] = 'Back-Button pressed before scanning anything.)';
//     } catch (e) {
//       barcodeResult[0] = 'Unknown error: $e';
//     }
//     barcodeResult[1] = false;
//     barcodeResult[2] = ResultType.Error;
//     return barcodeResult;
//   }
}

void showPermissionDialog(BuildContext context) {
  const textStyle = TextStyle(fontFamily: "Metropolis");
  showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      actions: [
        CupertinoDialogAction(
          isDefaultAction: false,
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          child: const Text(
            "Cancel",
            style: textStyle,
          ),
        ),
        CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              AppSettings.openAppSettings();
            },
            child: const Text(
              "Settings",
              style: textStyle,
            )),
      ],
      title: const Text(
        "Unable to access Camera",
      ),
      content: const Text(
        "To allow this app to use Camera, open settings and allow this app to access Camera",
      ).py8(),
    ),
  );
}

class QRViewScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRViewScreenState();
}

class _QRViewScreenState extends State<QRViewScreen> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  // Future<void> fetchQRCodeFromImage(BuildContext context) async {
  //   showDialog(
  //     context: context,
  //     builder: (context) => LoadingDialog(
  //       canceable: false,
  //       child: SizedBox(
  //         height: MediaQuery.of(context).size.height * 0.15,
  //         width: MediaQuery.of(context).size.width * 0.3,
  //         child: const ChasingDotsIndicator(),
  //       ),
  //     ),
  //     barrierDismissible: false,
  //   );
  //   final XFile? file =
  //       await ImagePicker().pickImage(source: ImageSource.gallery);
  //   if (file == null) {
  //     context.pop();
  //   } else {
  //     final String? data = await NewFrontier.channel
  //         .invokeMethod(NewFrontier.readQRMethodName, {"file": file.path});
  //     context.pop();
  //     if (data != null) {
  //       goBackWithResult(Barcode(data, BarcodeFormat.qrcode, []));
  //     } else {
  //       goBackWithResult(null);
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: OutlinedButton.icon(
      //   onPressed: () {
      //     fetchQRCodeFromImage(context);
      //   },
      //   icon: const LeadingImage(
      //     url: "${NewFrontier.iconAssets}ic_gallery.svg",
      //     size: 22.0,
      //   ),
      //   label: context.text(NewFrontier.albumText).text.xl.make(),
      //   style: OutlinedButton.styleFrom(
      //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      //     shape: RoundedRectangleBorder(
      //       borderRadius: BorderRadius.circular(
      //         SizeConfig.buttonCornerRadius,
      //       ),
      //     ),
      //     primary: NewAppColor.brandColor,
      //     side: BorderSide(
      //       width: 1.5,
      //       color: NewAppColor.brandColor,
      //     ),
      //   ),
      // ),
      appBar: AppBar(
        title: "Scan".text.make(),
        actions: [
          IconButton(
            icon: FutureBuilder(
              future: controller?.getFlashStatus(),
              builder: (context, snapshot) {
                Icon status = const Icon(Icons.flash_off_outlined);
                if (snapshot.data == null) {
                  status = const Icon(Icons.flash_off_outlined);
                } else {
                  status = snapshot.data == true
                      ? const Icon(Icons.flash_on_outlined)
                      : const Icon(Icons.flash_off_outlined);
                }
                return status;
              },
            ),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {});
            },
          )
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    final scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 300.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      goBackWithResult(scanData);
    });
  }

  void goBackWithResult(Barcode? scanData) {
    result = scanData;
    controller!.dispose();
    context.pop(result);
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      showPermissionDialog(context);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(
      //       content: Text('You need to grant the camera permission!')),
      // );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
