import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRGenerateScreen extends StatelessWidget {
  final String orderId = 'order_abc123';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Generator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Scan this QR to verify order'),
            SizedBox(height: 20),
            QrImageView(data: orderId, size: 200.0),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .set({'status': 'pending'});
              },
              child: Text('Create Order'),
            ),
          ],
        ),
      ),
    );
  }
}
