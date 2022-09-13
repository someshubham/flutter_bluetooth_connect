import 'package:flutter/cupertino.dart';

class ChasingDotsIndicator extends StatelessWidget {
  const ChasingDotsIndicator();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CupertinoActivityIndicator(
        radius: 18.0,
      ),
    );
  }
}
