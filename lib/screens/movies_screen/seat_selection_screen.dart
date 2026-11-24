import 'package:flutter/material.dart';
import 'dart:math';
import 'confirm_seat_screen.dart';
import 'food&drinks_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final String movieTitle;
  final String showtime;
  final String cinema;
  final String date;
  final String hall;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final String moviePosterPath;
  final String movieBannerPath;

  const SeatSelectionScreen({
    super.key,
    required this.movieTitle,
    required this.showtime,
    required this.cinema,
    required this.date,
    required this.hall,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<String> selectedSeats = {};
  final Set<String> soldSeats = {};

  double get _estimatedSeatTotal => selectedSeats.length * 17.0;

  @override
  void initState() {
    super.initState();
    _generateRandomSoldSeats();
  }

  void _generateRandomSoldSeats() {
    final rand = Random();
    const individualRows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    const seatsPerRow = 10;

    // --- 1. For each row, mark 5 unique seats as sold ---
    for (var row in individualRows) {
      final rowIndices = List.generate(seatsPerRow, (i) => i)..shuffle();
      for (int i = 0; i < 3; i++) {
        final seatId = '$row${rowIndices[i]}';
        soldSeats.add(seatId);
      }
    }

    // --- 2. Generate 2 random twin sold seats (from J0 to J5) ---
    const twinRow = 'J';
    final twinIndices = List.generate(6, (i) => i)..shuffle(); // J0 to J5

    for (int i = 0; i < 2; i++) {
      soldSeats.add('$twinRow${twinIndices[i]}');
    }
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            // ✅ Prevent overflow
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ Adjust height dynamically
              children: [
                Image.asset(
                  'assets/images/exit_icon.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'LEAVING SO SOON?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Any details entered will be lost.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Stay
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'STAY ON THIS PAGE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Leave
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero, // Required to match container
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      backgroundColor:
                          Colors.transparent, // Transparent to show gradient
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFF5A6A6),
                            Color.fromARGB(255, 200, 137, 137),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: const Text(
                          'LEAVE THIS PAGE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurvedScreen() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        children: [
          SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(painter: CurvedScreenPainter()),
          ),
          const SizedBox(height: 2),
          const Text(
            'SCREEN',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: const [
                Icon(Icons.arrow_back, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  "SELECT SEATS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            children: [
              _StepCircle(label: "1", isActive: true),
              SizedBox(width: 4),
              _StepLine(),
              SizedBox(width: 4),
              _StepCircle(label: "2"),
              SizedBox(width: 4),
              _StepLine(),
              SizedBox(width: 4),
              _StepCircle(label: "3"),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _showExitConfirmation(context),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildStepHeader(context),
            const SizedBox(height: 15),
            _buildMovieInfo(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(
                    'assets/images/seat_selected.png',
                    'SELECTED',
                  ),
                  _buildLegendItem('assets/images/seat_sold.png', 'SOLD'),
                  _buildLegendItem(
                    'assets/images/seat_available.png',
                    'SINGLE',
                  ),
                  _buildLegendItem('assets/images/seat_twin.png', 'TWIN'),
                ],
              ),
            ),
            _buildCurvedScreen(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 32),
                child: _buildSeatLayout(),
              ),
            ),
            if (selectedSeats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 1.0),
                child: Text(
                  'YOUR SEAT(S): ${selectedSeats.toList()..sort((a, b) => a.compareTo(b))}'
                      .replaceAll('[', '')
                      .replaceAll(']', '')
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  decoration: BoxDecoration(
                    gradient:
                        selectedSeats.isEmpty
                            ? null // Optional: No gradient if button is disabled
                            : const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFFF5A6A6),
                                Color.fromARGB(255, 200, 137, 137),
                              ],
                            ),
                    color:
                        selectedSeats.isEmpty
                            ? const Color.fromARGB(255, 127, 87, 87)
                            : null,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomRight: Radius.circular(5),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed:
                        selectedSeats.isEmpty
                            ? null
                            : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ConfirmSeatScreen(
                                        movieTitle: widget.movieTitle,
                                        cinema: widget.cinema,
                                        date: widget.date,
                                        showtime: widget.showtime,
                                        selectedSeats: selectedSeats.toList(),
                                        hall: widget.hall,
                                        totalSeatPrice: _estimatedSeatTotal,
                                        movieCategory: widget.movieCategory,
                                        movieDuration: widget.movieDuration,
                                        movieLanguage: widget.movieLanguage,
                                        moviePosterPath: widget.moviePosterPath,
                                        movieBannerPath: widget.movieBannerPath,
                                      ),
                                ),
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                    ),
                    child: const Text(
                      'BOOK SEAT(S)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              widget.moviePosterPath,
              width: 80,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white54),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.movieTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.cinema} | ${widget.hall}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${widget.movieCategory} | ${widget.movieDuration} | ${widget.movieLanguage}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.date}, ${widget.showtime}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String iconPath, String label) {
    return Column(
      children: [
        Image.asset(iconPath, width: 30, height: 30),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatLayout() {
    const rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J'];
    const seatsPerRow = 10;

    return SingleChildScrollView(
      child: Column(
        children:
            rows.map((row) {
              final isTwinRow = row == 'J';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        width: 16,
                        child: Text(
                          row,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(isTwinRow ? 6 : seatsPerRow, (
                          index,
                        ) {
                          final seatId = '$row$index';
                          bool isSold = soldSeats.contains(seatId);
                          bool isSelected = selectedSeats.contains(seatId);
                          String assetPath;

                          if (isTwinRow) {
                            if (isSold) {
                              assetPath = 'assets/images/seat_twin_sold.png';
                            } else if (isSelected) {
                              assetPath =
                                  'assets/images/seat_twin_selected.png';
                            } else {
                              assetPath = 'assets/images/seat_twin.png';
                            }
                          } else {
                            if (isSold) {
                              assetPath = 'assets/images/seat_sold.png';
                            } else if (isSelected) {
                              assetPath = 'assets/images/seat_selected.png';
                            } else {
                              assetPath = 'assets/images/seat_available.png';
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: GestureDetector(
                              onTap: () {
                                if (!isSold) {
                                  setState(() {
                                    if (isSelected) {
                                      selectedSeats.remove(seatId);
                                    } else {
                                      selectedSeats.add(seatId);
                                    }
                                  });
                                }
                              },
                              child: Image.asset(
                                assetPath,
                                width: isTwinRow ? 40 : 28,
                                height: isTwinRow ? 40 : 28,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 16,
                        child: Text(
                          row,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class CurvedScreenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.white.withOpacity(0.8),
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, 0, size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StepCircle extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StepCircle({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isActive ? Color(0xFFF5A6A6) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: const Color.fromARGB(255, 104, 104, 104)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, width: 20, color: Colors.white);
  }
}
