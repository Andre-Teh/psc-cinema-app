import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class Film {
  final String fid;
  final String filmsTitle;
  final List<dynamic> showTimes; // List of maps with datetime, hall
  final String status; // Firestore status (not used for logic)
  final String bannerUrl;
  final int filmsDuration; // minutes

  Film({
    required this.fid,
    required this.filmsTitle,
    required this.showTimes,
    required this.status,
    required this.bannerUrl,
    required this.filmsDuration,
  });

  factory Film.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Film(
      fid: data['fid'] ?? '',
      filmsTitle: data['films_title'] ?? '',
      showTimes: data['show_times'] ?? [],
      status: data['status'] ?? '',
      bannerUrl: data['banner_url'] ?? '',
      filmsDuration: data['films_duration'] ?? 90,
    );
  }
}

enum ShowTimeStatus { completed, showing, preparing, comingSoon }

class _ShowTimeEntry {
  final String fid;
  final String title;
  final DateTime datetime;
  final String hall;
  final int durationMinutes;

  _ShowTimeEntry({
    required this.fid,
    required this.title,
    required this.datetime,
    required this.hall,
    required this.durationMinutes,
  });
}

ShowTimeStatus getShowTimeStatus(_ShowTimeEntry entry) {
  final now = DateTime.now();
  final start = entry.datetime;
  final end = start.add(Duration(minutes: entry.durationMinutes));
  final diff = start.difference(now);

  if (now.isAfter(end)) {
    return ShowTimeStatus.completed;
  } else if (now.isAfter(start) && now.isBefore(end)) {
    return ShowTimeStatus.showing;
  } else if (diff.inMinutes <= 10 && diff.isNegative == false) {
    return ShowTimeStatus.preparing;
  } else {
    return ShowTimeStatus.comingSoon;
  }
}

class MovieScheduleScreen extends StatefulWidget {
  const MovieScheduleScreen({Key? key}) : super(key: key);

  @override
  State<MovieScheduleScreen> createState() => _MovieScheduleScreenState();
}

class _MovieScheduleScreenState extends State<MovieScheduleScreen> {
  List<Film> films = [];
  List<_ShowTimeEntry> showTimeEntries = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFilms();
  }

  Future<void> fetchFilms() async {
    final snapshot = await FirebaseFirestore.instance.collection('films').get();
    final allFilms = snapshot.docs.map((doc) => Film.fromDoc(doc)).toList();

    List<_ShowTimeEntry> entries = [];

    for (var film in allFilms) {
      for (var show in film.showTimes) {
        if (show is Map<String, dynamic>) {
          final ts = show['datetime'] as Timestamp?;
          if (ts != null) {
            entries.add(
              _ShowTimeEntry(
                fid: film.fid,
                title: film.filmsTitle,
                datetime: ts.toDate(),
                hall: show['hall'] ?? '',
                durationMinutes: film.filmsDuration,
              ),
            );
          }
        }
      }
    }

    entries.sort((a, b) => a.datetime.compareTo(b.datetime));

    setState(() {
      films = allFilms;
      showTimeEntries = entries;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 过滤今天场次
    final todayShowTimes =
        showTimeEntries
            .where(
              (e) =>
                  e.datetime.year == now.year &&
                  e.datetime.month == now.month &&
                  e.datetime.day == now.day,
            )
            .toList();

    final completedToday =
        todayShowTimes
            .where((e) => getShowTimeStatus(e) == ShowTimeStatus.completed)
            .length;

    final showingToday =
        todayShowTimes
            .where((e) => getShowTimeStatus(e) == ShowTimeStatus.showing)
            .length;

    final preparingToday =
        todayShowTimes
            .where((e) => getShowTimeStatus(e) == ShowTimeStatus.preparing)
            .length;

    final totalToday = todayShowTimes.length;

    double getTodayCompletedRatio() {
      if (totalToday == 0) return 0;
      return completedToday / totalToday;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Movie Schedule"),
        backgroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                : Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _statRow(
                                "Completed Today",
                                completedToday,
                                totalToday,
                              ),
                              const SizedBox(height: 8),
                              _statRow("Showing Now", showingToday),
                              const SizedBox(height: 8),
                              _statRow("Preparing Now", preparingToday),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          height: 130,
                          child: CustomPaint(
                            foregroundPainter: CircleProgressPainter(
                              progress: getTodayCompletedRatio(),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$completedToday / $totalToday',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 700,
                          child: Column(
                            children: [
                              // 表头
                              Row(
                                children: [
                                  _tableHeaderText("#", width: 100),
                                  _tableHeaderText("Name", width: 300),
                                  _tableHeaderText("Season", width: 200),
                                  _tableHeaderText("Hall", width: 100),
                                ],
                              ),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                              // 列表
                              Expanded(
                                child: ListView.separated(
                                  itemCount: todayShowTimes.length,
                                  separatorBuilder:
                                      (_, __) =>
                                          const Divider(color: Colors.white12),
                                  itemBuilder: (context, index) {
                                    final entry = todayShowTimes[index];
                                    final dateStr =
                                        "${entry.datetime.month}/${entry.datetime.day}/${entry.datetime.year} ${entry.datetime.hour.toString().padLeft(2, '0')}:${entry.datetime.minute.toString().padLeft(2, '0')}";

                                    return Row(
                                      children: [
                                        _tableCell('${index + 1}', width: 100),
                                        _tableCell(entry.title, width: 300),
                                        _tableCell(dateStr, width: 200),
                                        _tableCell(entry.hall, width: 100),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.yellow,
        onPressed: () {
          // TODO: 添加筛选功能
        },
        child: const Icon(Icons.filter_list, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _statRow(String label, int completed, [int? total]) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            total != null ? '$completed / $total' : completed.toString(),
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeaderText(String text, {double? width}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {double? width, bool multiline = false}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          maxLines: multiline ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;

  CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 8.0;
    final radius = (size.width / 2) - strokeWidth / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final backgroundPaint =
        Paint()
          ..color = Colors.white12
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final foregroundPaint =
        Paint()
          ..shader = SweepGradient(
            colors: [Colors.white, Colors.redAccent],
            stops: [0.0, progress],
            startAngle: 0,
            endAngle: 2 * pi,
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    double sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
