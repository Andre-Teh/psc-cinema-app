import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/membership_screen.dart';
import 'voucher_screen.dart';
import 'dart:async';
import 'food&drinks_screen.dart';
import '../payment_screen.dart';
import 'seat_selection_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutScreen extends StatefulWidget {
  final String movieTitle;
  final String cinema;
  final String date;
  final String showtime;
  final String hall;
  final int seatCount;
  final double seatTotal;
  final String selectedSeats;
  final List<CartItem> cartItems;
  final Duration initialTimeLeft;
  final String? voucherCode;
  final double discountAmount;
  final Map<String, String>? selectedReward;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final String moviePosterPath;
  final String movieBannerPath;

  const CheckoutScreen({
    super.key,
    required this.movieTitle,
    required this.cinema,
    required this.date,
    required this.showtime,
    required this.hall,
    required this.seatCount,
    required this.seatTotal,
    required this.cartItems,
    required this.initialTimeLeft,
    required this.selectedSeats,
    this.voucherCode,
    this.discountAmount = 0.0,
    this.selectedReward,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Duration _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.initialTimeLeft;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 0) {
        timer.cancel();
        _showTimeoutDialog();
      } else {
        setState(() {
          _timeLeft -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _createOrder(BuildContext context, double finalPrice) async {
    final orderId = const Uuid().v4().substring(0, 8).toUpperCase();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final email = user?.email ?? '';
    final phone = user?.phoneNumber ?? '';

    final double totalFoodPrice = widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );

    final selectedReward = widget.selectedReward;
    final double rewardDiscount = selectedReward != null ? 7.00 : 0.00;
    final double processingFee = 2.00;

    final bool isVoucherApplied = widget.voucherCode == 'DISCOUNT5';
    final double voucherDiscount = isVoucherApplied ? 5.00 : 0.00;

    final String orderDescription = [
      widget.movieTitle,
      widget.date,
      widget.showtime,
      widget.cinema,
      widget.hall,
      widget.selectedSeats,
    ].join(' - ');

    final List<Map<String, dynamic>> foodItems =
        widget.cartItems.map((item) {
          return {
            'title': item.title,
            'quantity': item.quantity,
            'price': item.price,
            'total': item.quantity * item.price,
          };
        }).toList();

    final List<Map<String, dynamic>> enableDiscounts = [
      {"type": "Student", "price": 7.0, "quantity": 2},
      {"type": "Senior", "price": 5.0, "quantity": 1},
    ];

    final orderData = {
      'uid': uid,
      'email': email,
      'phone': phone,
      'orderID': orderId,
      'paymentID': null,
      'createdAt': Timestamp.now(),

      'movieTitle': widget.movieTitle,
      'cinema': widget.cinema,
      'date': widget.date,
      'showtime': widget.showtime,
      'hall': widget.hall,

      'seats': widget.selectedSeats.split(', '),
      'seatCount': widget.seatCount,
      'seatTotal': widget.seatTotal,

      'foodItems': foodItems,
      'totalFoodPrice': totalFoodPrice,

      'processingFee': processingFee,
      'rewardDiscount': rewardDiscount,
      'voucherDiscount': voucherDiscount,
      'voucherCode': widget.voucherCode,
      'finalPrice': finalPrice,
      'selectedReward': selectedReward?['title'] ?? null,

      'enableDiscounts': enableDiscounts,
      'orderDescription': orderDescription,

      'status': 'UNPAID',
      'usedstatus': 'Unused',
    };

    await FirebaseFirestore.instance
        .collection('order_data')
        .doc(orderId)
        .set(orderData);

    // Navigate to Payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PaymentScreen(
              totalPrice: finalPrice,
              movieTitle: widget.movieTitle,
              cinema: widget.cinema,
              date: widget.date,
              time: widget.showtime,
              showtime: widget.showtime,
              hall: widget.hall,
              movieCategory: widget.movieCategory,
              movieDuration: widget.movieDuration,
              movieLanguage: widget.movieLanguage,
              moviePosterPath: widget.moviePosterPath,
              movieBannerPath: widget.movieBannerPath,
              selectedSeats: widget.selectedSeats.split(', '),
              orderId: orderId,
            ),
      ),
    );
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 16),
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
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "OKAY",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get formattedTime =>
      '${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalItemPrice = widget.cartItems.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );
    print('🛒 Total Item Price: \$${totalItemPrice.toStringAsFixed(2)}');

    final selectedReward = SelectedRewardHolder.getReward();
    final double rewardDiscount = selectedReward != null ? 7.00 : 0.00;
    print('🎁 Reward Discount: \$${rewardDiscount.toStringAsFixed(2)}');

    final bool isVoucherApplied = widget.voucherCode == 'DISCOUNT5';
    final double discountAmount = isVoucherApplied ? 5.00 : 0.00;
    print('🏷️ Voucher Applied: ${isVoucherApplied ? "Yes" : "No"}');
    print('🏷️ Voucher Discount: \$${discountAmount.toStringAsFixed(2)}');

    final double totalBeforeDiscount =
        (totalItemPrice - rewardDiscount).clamp(0, double.infinity) + 2.00;
    print(
      '📦 Total Before Discount (with RM2 fee): \$${totalBeforeDiscount.toStringAsFixed(2)}',
    );

    final double finalPrice = (totalBeforeDiscount - discountAmount).clamp(
      0,
      double.infinity,
    );
    print('💰 Final Price to Pay: \$${finalPrice.toStringAsFixed(2)}');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            "CHECKOUT & PAYMENT",
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
                      children: const [
                        _StepCircle(label: "1"),
                        SizedBox(width: 4),
                        _StepLine(),
                        SizedBox(width: 4),
                        _StepCircle(label: "2"),
                        SizedBox(width: 4),
                        _StepLine(),
                        SizedBox(width: 4),
                        _StepCircle(label: "3", isActive: true),
                      ],
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showExitConfirmation(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                        widget.movieBannerPath.startsWith('http')
                            ? NetworkImage(widget.movieBannerPath)
                            : AssetImage(widget.movieBannerPath)
                                as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movieTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.cinema,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.event,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.date,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.access_time,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.showtime,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/seat_icon.png',
                              width: 14,
                              height: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.selectedSeats,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ORDER DETAILS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "You'll earn ${(widget.seatTotal * 5).toInt()} MovieMoney",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SEATS',
                              style: TextStyle(color: Colors.white),
                            ),
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
                        const SizedBox(height: 4),
                        const SizedBox(height: 16),
                        ...widget.cartItems.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2C2C),
                                    border: Border.all(color: Colors.redAccent),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(15),
                                    ),
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'RM ${(item.price * item.quantity).toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROCESSING FEE',
                              style: TextStyle(color: Colors.white),
                            ),
                            Text(
                              'RM 2.00',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Color.fromARGB(35, 255, 255, 255),
                          thickness: 2,
                          height: 45,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'FOOD & DRINKS',
                              style: TextStyle(color: Colors.white),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Flexible(
                                child: Row(
                                  children: const [
                                    Text(
                                      'ADD',
                                      style: TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => MemberRewardsScreen(
                                      onBack: () => Navigator.pop(context),
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.card_giftcard,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'MY REWARDS',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        selectedReward?['title'] ??
                                            'No reward applied',
                                        style: TextStyle(
                                          color:
                                              selectedReward != null
                                                  ? Colors.white70
                                                  : Colors.white38,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VoucherScreen(),
                              ),
                            );

                            if (result != null && result == 'DISCOUNT5') {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CheckoutScreen(
                                        movieTitle: widget.movieTitle,
                                        cinema: widget.cinema,
                                        date: widget.date,
                                        showtime: widget.showtime,
                                        hall: widget.hall,
                                        seatCount: widget.seatCount,
                                        seatTotal: widget.seatTotal,
                                        cartItems: widget.cartItems,
                                        selectedSeats: widget.selectedSeats,
                                        initialTimeLeft: widget.initialTimeLeft,
                                        voucherCode: result,
                                        discountAmount: 5.0,
                                        selectedReward: selectedReward,
                                        movieCategory: widget.movieCategory,
                                        movieDuration: widget.movieDuration,
                                        movieLanguage: widget.movieLanguage,
                                        moviePosterPath: widget.moviePosterPath,
                                        movieBannerPath: widget.movieBannerPath,
                                      ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 60, // same as MY REWARDS
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.confirmation_num,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'VOUCHER CODE(S)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        widget.voucherCode != null
                                            ? widget.voucherCode!
                                            : 'No voucher applied',
                                        style: TextStyle(
                                          color:
                                              widget.voucherCode != null
                                                  ? Colors.white70
                                                  : Colors.white38,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 90,
            left: 16,
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'TIME LEFT: $formattedTime',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap: () {
                _createOrder(context, finalPrice);
              },

              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF5A6A6),
                      Color.fromARGB(255, 200, 137, 137),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'CHECKOUT - RM ${finalPrice.toStringAsFixed(2)}',
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
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder:
                              (context) => SeatSelectionScreen(
                                movieTitle: widget.movieTitle,
                                cinema: widget.cinema,
                                date: widget.date,
                                showtime: widget.showtime,
                                hall: widget.hall,
                                movieCategory: widget.movieCategory,
                                movieDuration: widget.movieDuration,
                                movieLanguage: widget.movieLanguage,
                                moviePosterPath: widget.moviePosterPath,
                                movieBannerPath: widget.movieBannerPath,
                              ),
                        ),
                      );
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
                      Navigator.of(context).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                          bottomLeft: Radius.circular(18),
                        ),
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
        border: Border.all(color: Color.fromARGB(255, 104, 104, 104)),
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
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, width: 20, color: Colors.white);
  }
}
