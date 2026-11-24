import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  Future<void> _generatePDF(BuildContext context) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final snapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('status', isEqualTo: 'PAID')
            .get();

    int totalOrders = 0;
    int totalSeats = 0;
    double totalRevenue = 0;
    Map<String, int> movieSales = {};

    for (var doc in snapshot.docs) {
      final timestamp = doc['createdAt'] as Timestamp?;
      final orderDate = DateFormat('yyyy-MM-dd').format(timestamp!.toDate());
      if (orderDate != today) continue;

      totalOrders++;
      final seatCount =
          (doc['seatCount'] is num) ? (doc['seatCount'] as num).toInt() : 0;
      final price =
          (doc['finalPrice'] is num)
              ? (doc['finalPrice'] as num).toDouble()
              : 0.0;
      final movie = doc['movieTitle'];

      totalSeats += seatCount;
      totalRevenue += price;
      movieSales[movie] = (movieSales[movie] ?? 0) + seatCount;
    }

    String topMovie = 'N/A';
    int maxSeats = 0;
    movieSales.forEach((title, count) {
      if (count > maxSeats) {
        topMovie = title;
        maxSeats = count;
      }
    });

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Daily Report - $today',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total Orders: $totalOrders'),
                pw.Text('Total Tickets Sold: $totalSeats'),
                pw.Text('Total Revenue: RM ${totalRevenue.toStringAsFixed(2)}'),
                pw.Text('Top Movie: $topMovie ($maxSeats tickets)'),
              ],
            ),
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      // ✅ Web: use sharePdf to trigger browser download
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'daily_report_$today.pdf',
      );
    } else {
      // ✅ Mobile/Desktop: use layoutPdf to show system dialog
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Download'),
            content: const Text(
              'Are you sure you want to download today\'s Daily Report PDF?',
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text('DOWNLOAD'),
                onPressed: () {
                  Navigator.pop(context);
                  _generatePDF(context);
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Daily Report',
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Download Daily Report PDF'),
          onPressed: () => _showConfirmationDialog(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
        ),
      ),
    );
  }
}
