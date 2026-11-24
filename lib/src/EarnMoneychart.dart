import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum ChartMode { weekly, monthly, yearly }

class EarnChart extends StatefulWidget {
  final ChartMode mode;

  const EarnChart({super.key, required this.mode});

  @override
  State<EarnChart> createState() => _EarnChartState();
}

class _EarnChartState extends State<EarnChart> {
  List<double> _earnings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  @override
  void didUpdateWidget(covariant EarnChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _fetchEarnings();
    }
  }

  Future<void> _fetchEarnings() async {
    setState(() {
      _isLoading = true;
      _earnings = [];
    });

    List<double> temp = [];
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('Payment_Data')
              .where('Status', isEqualTo: 'Successful')
              .get();

      final now = DateTime.now();

      switch (widget.mode) {
        case ChartMode.weekly:
          temp = List.filled(7, 0.0);
          for (var doc in snapshot.docs) {
            final timestamp = doc['Timestamp'] as Timestamp?;
            final total = doc['TotalPrice'];
            if (timestamp != null && total != null) {
              final date = timestamp.toDate();

              final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
              final endOfWeek = startOfWeek.add(const Duration(days: 6));

              if (date.isAfter(
                    startOfWeek.subtract(const Duration(seconds: 1)),
                  ) &&
                  date.isBefore(endOfWeek.add(const Duration(days: 1)))) {
                final weekdayIndex = date.weekday - 1;
                temp[weekdayIndex] += (total as num).toDouble();
              }
            }
          }
          break;

        case ChartMode.monthly:
          temp = List.filled(4, 0.0); // 分4周
          for (var doc in snapshot.docs) {
            final timestamp = doc['Timestamp'] as Timestamp?;
            final total = doc['TotalPrice'];
            if (timestamp != null && total != null) {
              final date = timestamp.toDate();

              if (date.month == now.month && date.year == now.year) {
                int weekIndex = ((date.day - 1) ~/ 7).clamp(0, 3);
                temp[weekIndex] += (total as num).toDouble();
              }
            }
          }
          break;

        case ChartMode.yearly:
          temp = List.filled(12, 0.0); // 12个月
          for (var doc in snapshot.docs) {
            final timestamp = doc['Timestamp'] as Timestamp?;
            final total = doc['TotalPrice'];
            if (timestamp != null && total != null) {
              final date = timestamp.toDate();

              if (date.year == now.year) {
                int monthIndex = date.month - 1;
                temp[monthIndex] += (total as num).toDouble();
              }
            }
          }
          break;
      }

      setState(() {
        _earnings = temp;
        _isLoading = false;
      });
    } catch (e) {
      print('Fetch earnings error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final labels =
        widget.mode == ChartMode.weekly
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : widget.mode == ChartMode.monthly
            ? ['W1', 'W2', 'W3', 'W4']
            : [
              'Jan',
              'Feb',
              'Mar',
              'Apr',
              'May',
              'Jun',
              'Jul',
              'Aug',
              'Sep',
              'Oct',
              'Nov',
              'Dec',
            ];

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8), // 加点左右内边距防止文字被挤到边缘
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false, interval: 1),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final int index = value.toInt();
                    if (index >= 0 && index < labels.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            minX: 0,
            maxX: (_earnings.length - 1).toDouble(),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.white30),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  _earnings.length,
                  (i) => FlSpot(i.toDouble(), _earnings[i]),
                ),
                isCurved: true,
                color: Colors.yellow,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.yellow.withOpacity(0.4),
                      Colors.yellow.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
