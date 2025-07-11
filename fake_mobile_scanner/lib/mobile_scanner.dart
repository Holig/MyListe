library mobile_scanner;

import 'package:flutter/widgets.dart';

class MobileScanner extends StatelessWidget {
  final void Function(dynamic)? onDetect;
  const MobileScanner({Key? key, this.onDetect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Le scan de QR code n\'est pas disponible sur le web.'),
    );
  }
}

class Barcode {
  final String? rawValue;
  Barcode(this.rawValue);
} 