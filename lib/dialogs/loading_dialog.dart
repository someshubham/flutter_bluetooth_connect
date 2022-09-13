import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_connect/widgets/chasing_dots_indicator.dart';

class LoadingDialog extends StatelessWidget {
  final Widget? child;

  final bool canceable;

  const LoadingDialog({
    Key? key,
    this.child,
    this.canceable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => canceable,
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: child ??
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  ChasingDotsIndicator(),
                  SizedBox(
                    height: 10,
                  ),
                  Text("Loading"),
                ],
              ),
        ),
      ),
    );
  }
}
