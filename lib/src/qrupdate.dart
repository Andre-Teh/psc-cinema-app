import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({Key? key}) : super(key: key);

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedOrderId;
  String? currentStatus;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (scanData.code != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('orders')
                .doc(scanData.code)
                .get();

        if (doc.exists) {
          setState(() {
            scannedOrderId = scanData.code;
            currentStatus = doc['status'];
          });
          controller.pauseCamera();
        } else {
          setState(() {
            scannedOrderId = 'Not found';
            currentStatus = '';
          });
        }
      }
    });
  }

  Future<void> markAsUsed() async {
    if (scannedOrderId != null && scannedOrderId != 'Not found') {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(scannedOrderId)
          .update({'status': 'used'});

      setState(() {
        currentStatus = 'used';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to USED')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (scannedOrderId != null)
                  Column(
                    children: [
                      Text('Order ID: $scannedOrderId'),
                      Text('Current Status: $currentStatus'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: currentStatus == 'used' ? null : markAsUsed,
                        child: Text('Mark as Used'),
                      ),
                    ],
                  )
                else
                  Text('Scan a QR code to begin.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
