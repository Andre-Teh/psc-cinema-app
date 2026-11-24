import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'filmList.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final List<String> _times = List.generate(24, (index) {
    final hour = index % 12 == 0 ? 12 : index % 12;
    final suffix = index < 12 ? 'am' : 'pm';
    return '$hour $suffix';
  });

  List<String> _days = [];
  List<Map<String, dynamic>> _scheduleItems = [];
  final Map<String, Color> _hallColors = {};
  final List<Color> _availableColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.orangeAccent,
    Colors.purple,
    Colors.teal,
    Colors.redAccent,
    Colors.amber,
  ];

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _headerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalScrollController.addListener(() {
      _headerScrollController.jumpTo(_horizontalScrollController.offset);
    });
    fetchScheduleData();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _headerScrollController.dispose();
    super.dispose();
  }

  Future<void> fetchScheduleData() async {
    final snapshot = await FirebaseFirestore.instance.collection('films').get();
    List<Map<String, dynamic>> allItems = [];
    int colorIndex = 0;
    Set<String> allDays = {};
    final today = DateTime.now();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      String title = data['films_title'] ?? 'Untitled';
      int duration = data['films_duration'] ?? 90;

      if (data['show_times'] != null) {
        for (final timeData in List.from(data['show_times'])) {
          final Timestamp ts = timeData['datetime'];
          final DateTime start = ts.toDate();
          final DateTime end = start.add(Duration(minutes: duration));
          final hall = timeData['hall'] ?? 'Unknown';

          if (end.isBefore(today)) continue;

          if (!_hallColors.containsKey(hall)) {
            _hallColors[hall] =
                _availableColors[colorIndex % _availableColors.length];
            colorIndex++;
          }

          final startDayLabel = DateFormat('yyyy-MM-dd').format(start);
          final endDayLabel = DateFormat('yyyy-MM-dd').format(end);
          allDays.add(startDayLabel);
          allItems.add({
            'title': title,
            'startTime': start,
            'duration': duration,
            'hall': hall,
            'dayLabel': startDayLabel,
          });

          if (endDayLabel != startDayLabel) {
            allDays.add(endDayLabel);
            final midnight = DateTime(start.year, start.month, start.day + 1);
            final overlap = end.difference(midnight).inMinutes;
            allItems.add({
              'title': title,
              'startTime': midnight,
              'duration': overlap,
              'hall': hall,
              'dayLabel': endDayLabel,
            });
          }
        }
      }
    }

    final sortedDays =
        allDays.toList()
          ..sort()
          ..removeWhere((day) {
            final dayDate = DateTime.parse(day);
            return dayDate.isBefore(
              DateTime(today.year, today.month, today.day),
            );
          });

    setState(() {
      _scheduleItems = allItems;
      _days = sortedDays;
    });
  }

  double getTopOffset(DateTime time) {
    return (time.hour + time.minute / 60.0) * 60;
  }

  void viewToday() {
    final todayLabel = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final index = _days.indexOf(todayLabel);
    if (index != -1) {
      final targetOffset = index * 140.0;
      _horizontalScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No schedule for today.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Cinema Timeline Schedule'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                // 日期 Header
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      const SizedBox(width: 52),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _headerScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                _days
                                    .map(
                                      (day) => Container(
                                        width: 140,
                                        alignment: Alignment.center,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: Text(
                                          day,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 时间表内容
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children:
                              _times
                                  .map(
                                    (t) => Container(
                                      height: 60,
                                      width: 50,
                                      margin: const EdgeInsets.all(1),
                                      alignment: Alignment.center,
                                      child: Text(
                                        t,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children:
                                  _days.map((dayLabel) {
                                    final itemsOfDay =
                                        _scheduleItems
                                            .where(
                                              (item) =>
                                                  item['dayLabel'] == dayLabel,
                                            )
                                            .toList();
                                    itemsOfDay.sort(
                                      (a, b) => a['startTime'].compareTo(
                                        b['startTime'],
                                      ),
                                    );

                                    final List<List<Map<String, dynamic>>>
                                    slots = [];
                                    final Set<Map<String, dynamic>> assigned =
                                        {};

                                    for (final item in itemsOfDay) {
                                      if (assigned.contains(item)) continue;
                                      final offsetA = getTopOffset(
                                        item['startTime'],
                                      );
                                      final endA = offsetA + item['duration'];
                                      bool placed = false;

                                      for (final slot in slots) {
                                        bool conflict = slot.any((e) {
                                          final offsetB = getTopOffset(
                                            e['startTime'],
                                          );
                                          final endB = offsetB + e['duration'];
                                          return !(endA <= offsetB ||
                                              offsetA >= endB);
                                        });

                                        if (!conflict) {
                                          slot.add(item);
                                          assigned.add(item);
                                          placed = true;
                                          break;
                                        }
                                      }

                                      if (!placed) {
                                        slots.add([item]);
                                        assigned.add(item);
                                      }
                                    }

                                    final double columnWidth = 140;

                                    return Container(
                                      width: columnWidth,
                                      margin: const EdgeInsets.all(4),
                                      child: SizedBox(
                                        height: _times.length * 60 + 300,
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Column(
                                              children: List.generate(
                                                _times.length,
                                                (i) => Container(
                                                  height: 60,
                                                  margin: const EdgeInsets.all(
                                                    1,
                                                  ),
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ),
                                            ...slots.asMap().entries.expand((
                                              entry,
                                            ) {
                                              final slotIndex = entry.key;
                                              final slotItems = entry.value;

                                              return slotItems.map((item) {
                                                final offset = getTopOffset(
                                                  item['startTime'],
                                                );
                                                final height =
                                                    item['duration'].toDouble();
                                                final color =
                                                    _hallColors[item['hall']] ??
                                                    Colors.blueGrey;
                                                final blockWidth =
                                                    columnWidth / slots.length;
                                                final left =
                                                    slotIndex * blockWidth;

                                                return Positioned(
                                                  top: offset,
                                                  left: left,
                                                  width: blockWidth,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      showDialog(
                                                        context: context,
                                                        builder:
                                                            (_) => Theme(
                                                              data: Theme.of(
                                                                context,
                                                              ).copyWith(
                                                                dialogBackgroundColor:
                                                                    Colors
                                                                        .black87,
                                                              ),
                                                              child: AlertDialog(
                                                                title: const Text(
                                                                  'Movie Details',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                ),
                                                                content: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Text(
                                                                      '🎬 Title: ${item['title']}',
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '📍 Hall: ${item['hall']}',
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '⏰ Start: ${item['startTime']}',
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '⏳ Duration: ${item['duration']} mins',
                                                                      style: const TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed:
                                                                        () => Navigator.pop(
                                                                          context,
                                                                        ),
                                                                    child: const Text(
                                                                      'Close',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colors.white,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                            1,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                            4,
                                                          ),
                                                      height: height,
                                                      decoration: BoxDecoration(
                                                        color: color,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        item['title'],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              });
                                            }),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MovieScheduleScreen(),
                      ),
                    );
                  },
                  child: const Text("VIEW TODAY"),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Edit Schedule Clicked")),
                    );
                  },
                  child: const Text("EDIT SCHEDULE"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
