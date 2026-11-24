import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psc_cinema_app/screens/movies_screen/food&drinks_screen.dart';
import 'package:psc_cinema_app/screens/my_booking_screen.dart';
import 'package:psc_cinema_app/screens/discount.dart';

class ConfirmSeatScreen extends StatefulWidget {
  final String movieTitle;
  final String cinema;
  final String date;
  final String showtime;
  final String hall;
  final List<String> selectedSeats;
  final double totalSeatPrice;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final Duration? initialTimeLeft;
  final String moviePosterPath;
  final String movieBannerPath;

  const ConfirmSeatScreen({
    super.key,
    this.initialTimeLeft,
    required this.movieTitle,
    required this.cinema,
    required this.date,
    required this.showtime,
    required this.selectedSeats,
    required this.hall,
    required this.totalSeatPrice,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
  });

  @override
  State<ConfirmSeatScreen> createState() => _ConfirmSeatScreenState();
}

class _ConfirmSeatScreenState extends State<ConfirmSeatScreen> {
  int maybankQty = 0;
  int seniorQty = 0;

  int get seatCount => widget.selectedSeats.length;

  Map<String, int> discountQty = {};
  Map<String, double> discountRates = {}; // key: Student, value: 0.5
  double? priceRange;
  bool isLoading = true;

  late Timer _timer;
  late Duration _timeLeft;

  int get singleQty =>
      widget.selectedSeats.length -
      discountQty.values.fold(0, (sum, v) => sum + v);

  double get total {
    if (priceRange == null) return 0.0;
    double t = singleQty * priceRange!;
    discountRates.forEach((key, rate) {
      t += discountQty[key]! * priceRange! * rate;
    });
    return t;
  }

  Future<void> _fetchDiscountData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('films')
              .where('poster_url', isEqualTo: widget.moviePosterPath)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();

        priceRange = (data['price_range'] ?? 17.0).toDouble();

        final List<dynamic> enabled = data['enabled_discounts'] ?? [];

        for (String type in enabled.cast<String>()) {
          final normalizedType = type.toLowerCase();

          double rate = 1.0;
          if (normalizedType == 'student') {
            rate = 0.7; // 30% off
          } else if (normalizedType == 'senior') {
            rate = 0.5; // 50% off
          } else if (normalizedType == 'child') {
            rate = 0.7; // 50% off
          } else if (normalizedType == 'oku') {
            rate = 0.5; // 50% off
          }

          discountRates[type] = rate;
          discountQty[type] = 0;
        }
      }
    } catch (e) {
      print('Failed to load discount data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDiscountData();

    _timeLeft = widget.initialTimeLeft ?? const Duration(minutes: 7);

    currentBooking = Booking(
      title: widget.movieTitle,
      date: widget.date,
      time: widget.showtime,
      cinema: widget.cinema,
      hall: widget.hall,
      seats: widget.selectedSeats,
      posterPath: widget.moviePosterPath,
      movieBannerPath: widget.movieBannerPath,
    );

    bookingExpiryTime = DateTime.now().add(_timeLeft);
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft -= const Duration(seconds: 1);
        });
      } else {
        _timer.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // force the user to acknowledge it
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_empty,
                  size: 60,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 20),
                const Text(
                  "TIMED OUT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Your session has timed out, please try again.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst); // Go home
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "OKAY",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 20.0,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text(
                  "CONFIRM YOUR SEATS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                    widget.movieBannerPath.startsWith('http')
                        ? NetworkImage(widget.movieBannerPath)
                        : AssetImage(widget.movieBannerPath) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.3),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movieTitle.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white70,
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
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.date}, ${widget.showtime}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/seat_icon.png',
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.selectedSeats.join(", "),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                      children: [
                        ...discountRates.entries.map((entry) {
                          final type = entry.key;
                          final rate = entry.value;
                          final qty = discountQty[type]!;
                          final price = priceRange! * rate;

                          return _buildTicketRow(
                            type.toUpperCase(),
                            "RM ${price.toStringAsFixed(2)}",
                            "Discount: ${((1 - rate) * 100).toInt()}% off",
                            quantity: qty,
                            total: qty * price,
                            onIncrement: () {
                              if (discountQty.values.fold(
                                    0,
                                    (sum, val) => sum + val,
                                  ) <
                                  widget.selectedSeats.length) {
                                setState(() {
                                  discountQty[type] = qty + 1;
                                });
                              }
                            },
                            onDecrement: () {
                              if (qty > 0) {
                                setState(() {
                                  discountQty[type] = qty - 1;
                                });
                              }
                            },
                          );
                        }).toList(),

                        const SizedBox(height: 12),
                        // SINGLE
                        _buildTicketRow(
                          "SINGLE",
                          "RM ${priceRange!.toStringAsFixed(2)}",
                          null,
                          quantity: singleQty,
                          total: singleQty * priceRange!,
                          showCounterOnly: true,
                        ),
                      ],
                    ),

                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: const [
                      Text(
                        "EDIT SEAT",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.redAccent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.black),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "⏱ TIME LEFT: ${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      currentBooking = currentBooking!.copyWith(
                        isConfirmed: true,
                      );
                      List<CartItem> ticketCartItems = [];

                      discountQty.forEach((type, qty) {
                        if (qty > 0) {
                          double rate = discountRates[type]!;
                          double price = priceRange! * rate;

                          ticketCartItems.add(
                            CartItem(
                              title: type.toUpperCase() + " TICKET",
                              price: price,
                              quantity: qty,
                              popcornOption: '-',
                              drinkOption: '-',
                              foodOption: '-',
                              imagePath: 'assets/images/ticket_icon.png',
                            ),
                          );
                        }
                      });

                      if (singleQty > 0) {
                        ticketCartItems.add(
                          CartItem(
                            title: "SINGLE TICKET",
                            price: priceRange!,
                            quantity: singleQty,
                            popcornOption: '-',
                            drinkOption: '-',
                            foodOption: '-',
                            imagePath: 'assets/images/ticket_icon.png',
                          ),
                        );
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FoodDrinksScreen(
                                initialTimeLeft: _timeLeft,
                                onTimeout: () {
                                  Navigator.popUntil(
                                    context,
                                    (route) => route.isFirst,
                                  );
                                },
                                movieTitle: widget.movieTitle,
                                cinema: widget.cinema,
                                date: widget.date,
                                showtime: widget.showtime,
                                hall: widget.hall,
                                totalSeatPrice: total,
                                selectedSeats: widget.selectedSeats.join(', '),
                                movieCategory: widget.movieCategory,
                                movieDuration: widget.movieDuration,
                                movieLanguage: widget.movieLanguage,
                                moviePosterPath: widget.moviePosterPath,
                                movieBannerPath: widget.movieBannerPath,
                                currentCartItems: ticketCartItems,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: Colors.transparent,
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
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          "ADD TO CART - RM ${total.toStringAsFixed(2)}",
                          style: const TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildTicketRow(
    String title,
    String price,
    String? subtitle, {
    int quantity = 0,
    double total = 0,
    bool showTotal = true,
    bool showCounterOnly = false,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child:
                      showCounterOnly
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 49,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(18),
                                bottomRight: Radius.circular(5),
                                bottomLeft: Radius.circular(18),
                              ),
                              color: const Color.fromARGB(255, 38, 38, 38),
                            ),
                            child: Text(
                              "$quantity",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : Container(
                            height: 35,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(18),
                                bottomRight: Radius.circular(5),
                                bottomLeft: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: quantity > 0 ? onDecrement : null,
                                  child: Icon(
                                    Icons.remove,
                                    size: 20,
                                    color:
                                        quantity > 0
                                            ? Colors.white
                                            : Colors.white38,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  "$quantity",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: onIncrement,
                                  child: const Icon(
                                    Icons.add,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "RM ${total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (subtitle != null && subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            )
          else
            Text(
              price,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }
}

class TicketItem {
  final String type; // eg. "OKU", "SINGLE"
  final int quantity;
  final double unitPrice;

  TicketItem({
    required this.type,
    required this.quantity,
    required this.unitPrice,
  });
}
