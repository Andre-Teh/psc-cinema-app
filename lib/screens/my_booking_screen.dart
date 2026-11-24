import 'dart:async';
import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/movies_screen/confirm_seat_screen.dart';
import 'package:psc_cinema_app/screens/movies_screen/food&drinks_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../src/loading.dart';

class FBItem {
  final String title;
  final int quantity;
  final String popcorn;
  final String drink;
  final String food;

  FBItem({
    required this.title,
    required this.quantity,
    required this.popcorn,
    required this.drink,
    required this.food,
  });
}

class Booking {
  final String title;
  final String date;
  final String time;
  final String cinema;
  final String hall;
  final List<String> seats;
  final List<FBItem> fbItems;
  final String posterPath;
  final bool isConfirmed;
  final String movieBannerPath;

  Booking({
    required this.title,
    required this.date,
    required this.time,
    required this.cinema,
    required this.hall,
    required this.seats,
    this.fbItems = const [],
    required this.posterPath,
    this.isConfirmed = false,
    required this.movieBannerPath,
  });

  Booking copyWith({
    String? title,
    String? date,
    String? time,
    String? cinema,
    String? hall,
    List<String>? seats,
    List<FBItem>? fbItems,
    String? posterPath,
    String? movieBannerPath,
    bool? isConfirmed,
  }) {
    return Booking(
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      cinema: cinema ?? this.cinema,
      hall: hall ?? this.hall,
      seats: seats ?? this.seats,
      fbItems: fbItems ?? this.fbItems,
      posterPath: posterPath ?? this.posterPath,
      movieBannerPath: movieBannerPath ?? this.movieBannerPath,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

List<Booking> historyBookings = [];
List<Booking> ticketBookings = [];
Booking? currentBooking;
DateTime? bookingExpiryTime;
bool _isLoading = true;

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  String selectedLocation = "Klang Valley";
  String tempSelectedLocation = "Klang Valley";
  bool rememberLocation = false;
  String? userID;
  String? area;
  List<String> seats = [];
  List<Map<String, dynamic>> discountList = [];
  String? filmname;
  String? cinema;
  String? hall;
  String? time;
  String? date;
  String? filmpng;
  List<Map<String, dynamic>> fooditem = [];
  String? status;
  String? amount;

  Future<void> fetchUserLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot =
          await FirebaseFirestore.instance.collection('Client').doc(uid).get();
      if (snapshot.exists) {
        final data = snapshot.data();
        setState(() {
          userID = data?['uid'] ?? 'uid';
          area = (data?['district'] ?? 'KLANG VALLEY').toString();
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchMovies() async {
    final snapshot = await FirebaseFirestore.instance.collection('films').get();

    final movies =
        snapshot.docs.map((doc) {
          final data = doc.data();

          return {
            "fid": doc.id,
            "title": data["films_title"],
            "duration": "${data["films_duration"] ?? 0} mins",
            "language": (data["films_language"] as List<dynamic>).join(", "),
            "poster": data["poster_url"],
            "package": List<String>.from(data["package"] ?? []),
          };
        }).toList();

    return movies;
  }

  Future<List<Map<String, dynamic>>> fetchOrder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('uid', isEqualTo: uid)
            .where('status', isEqualTo: 'PAID')
            .where('usedstatus', whereIn: ['Used', ''])
            .get();

    List<Map<String, dynamic>> orders = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      final String movieTitle = data['movieTitle'] ?? '';
      final String? posterUrl = await fetchPosterUrlFromMovieTitle(movieTitle);

      orders.add({
        'movieTitle': movieTitle,
        'date': data['date'] ?? '',
        'showtime': data['showtime'] ?? '',
        'hall': data['hall'] ?? '',
        'seats': List<String>.from(data['seats'] ?? []),
        'foodItems': List<Map<String, dynamic>>.from(data['foodItems'] ?? []),
        'poster': posterUrl ?? '',
      });
      print("Booking History fetched: ${querySnapshot.docs.length}");
    }

    return orders;
  }

  Future<List<Map<String, dynamic>>> fetchOrderUnused() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('order_data')
            .where('uid', isEqualTo: uid)
            .where('status', isEqualTo: 'PAID')
            .where('usedstatus', whereIn: ['Unused', ''])
            .get();

    List<Map<String, dynamic>> unorders = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      final String movieTitle = data['movieTitle'] ?? '';
      final String? posterUrl = await fetchPosterUrlFromMovieTitle(movieTitle);

      unorders.add({
        'id': doc.id,
        'movieTitle': movieTitle,
        'date': data['date'] ?? '',
        'showtime': data['showtime'] ?? '',
        'hall': data['hall'] ?? '',
        'seats': List<String>.from(data['seats'] ?? []),
        'foodItems': List<Map<String, dynamic>>.from(data['foodItems'] ?? []),
        'poster': posterUrl ?? '',
      });
      print("Booking Not fetched: ${querySnapshot.docs.length}");
    }

    return unorders;
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> fetchPosterUrlFromMovieTitle(String title) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('films')
            .where('films_title', isEqualTo: title)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return data['poster_url'] as String?;
    } else {
      return null;
    }
  }

  final List<FoodItem> bestsellerItems = [
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_limited_combo.jpg',
      title: 'STITCH TUMBLER COMBO\n',
      price: 65.0,
      rewardPoints: 325,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_limited.jpg',
      title: 'STITCH TUMBLER\n',
      price: 60.0,
      rewardPoints: 300,
      hasOptions: false,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_air_freshener_combo.jpg',
      title: 'STITCH PERFUME COMBO\n',
      price: 45.0,
      rewardPoints: 225,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/angel_air_freshener_combo.jpg',
      title: 'ANGEL PERFUME COMBO\n',
      price: 45.0,
      rewardPoints: 225,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_air_freshener.jpg',
      title: 'STITCH PERFUME\n',
      price: 40.0,
      rewardPoints: 200,
      hasOptions: false,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/angel_air_freshener.jpg',
      title: 'ANGEL PERFUME\n',
      price: 40.0,
      rewardPoints: 200,
      hasOptions: false,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_uno_cards.jpg',
      title: 'STITCH UNO CARD\n',
      price: 40.0,
      rewardPoints: 200,
      hasOptions: false,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks2.jpg',
      title: 'ROYALE POPCORN WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks3.jpg',
      title: 'ROYALE POPCORN WITH HOT DRINK',
      price: 21.0,
      rewardPoints: 105,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks5.jpg',
      title: 'SIGNATURE POPCORN WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks4.jpg',
      title: 'SIGNATURE POPCORN WITH HOT DRINK',
      price: 21.0,
      rewardPoints: 105,
    ),
  ];

  final List<FoodItem> popcornComboItems = [
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_limited_combo.jpg',
      title: 'STITCH TUMBLER COMBO\n',
      price: 65.0,
      rewardPoints: 325,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/stitch_air_freshener_combo.jpg',
      title: 'STITCH PERFUME COMBO\n',
      price: 45.0,
      rewardPoints: 225,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/angel_air_freshener_combo.jpg',
      title: 'ANGEL PERFUME COMBO\n',
      price: 45.0,
      rewardPoints: 225,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks2.jpg',
      title: 'ROYALE POPCORN WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks3.jpg',
      title: 'ROYALE POPCORN WITH HOT DRINK',
      price: 21.0,
      rewardPoints: 105,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks5.jpg',
      title: 'SIGNATURE POPCORN WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/food&drinks4.jpg',
      title: 'SIGNATURE POPCORN WITH HOT DRINK',
      price: 21.0,
      rewardPoints: 105,
    ),
  ];

  final List<FoodItem> hotBitesItems = [
    FoodItem(
      imagePath: 'assets/food&drinks/seafood_tofu.png',
      title: 'SEAFOOD TOFU WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/seafood_tofu_hot.png',
      title: 'SEAFOOD TOFU WITH HOT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/chicken_minis.webp',
      title: 'CHICKEN MINIS WITH SOFT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    FoodItem(
      imagePath: 'assets/food&drinks/chicken_minis_hot.webp',
      title: 'CHICKEN MINIS WITH HOT DRINK',
      price: 19.0,
      rewardPoints: 95,
    ),
    // Add more if needed
  ];

  double _getPriceForItem(String title) {
    final item = [
      ...bestsellerItems,
      ...popcornComboItems,
      ...hotBitesItems,
    ].firstWhere(
      (item) => item.title.trim() == title,
      orElse:
          () => FoodItem(title: '', price: 0.0, imagePath: '', rewardPoints: 0),
    );
    return item.price;
  }

  String _getImagePathForItem(String title) {
    final item = [
      ...bestsellerItems,
      ...popcornComboItems,
      ...hotBitesItems,
    ].firstWhere(
      (item) => item.title.trim() == title,
      orElse:
          () => FoodItem(title: '', price: 0.0, imagePath: '', rewardPoints: 0),
    );
    return item.imagePath;
  }

  String _getTimeLeft() {
    if (bookingExpiryTime == null) return "00:00";

    final remaining = bookingExpiryTime!.difference(DateTime.now());

    if (remaining.isNegative) return "EXPIRED";

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  Timer? _refreshTimer;

  List<Map<String, dynamic>> paidOrders = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    fetchUserLocation();

    historyBookings.clear();
    ticketBookings.clear();

    fetchOrder().then((orders) async {
      try {
        for (var order in orders) {
          final booking = Booking(
            title: order['movieTitle'] ?? '',
            date: order['date'] ?? '',
            time: order['showtime'] ?? '',
            cinema: order['cinema'] ?? '',
            hall: order['hall'] ?? '',
            seats: List<String>.from(order['seats'] ?? []),
            fbItems: List<FBItem>.from(
              (order['foodItems'] ?? []).map((f) {
                return FBItem(
                  title: f['title'] ?? '',
                  quantity: f['quantity'] ?? 1,
                  popcorn: '',
                  drink: '',
                  food: '',
                );
              }),
            ),
            posterPath: order['poster'] ?? '',
            movieBannerPath: order['poster'] ?? '',
            isConfirmed: true,
          );

          historyBookings.add(booking);
        }

        setState(() {});
      } catch (e, stack) {
        print("🔥 ERROR: $e");
        print("📍 StackTrace: $stack");
      }
    });

    fetchOrderUnused().then((orders) async {
      try {
        for (var order in orders) {
          final unbooking = Booking(
            title: order['movieTitle'] ?? '',
            date: order['date'] ?? '',
            time: order['showtime'] ?? '',
            cinema: order['cinema'] ?? '',
            hall: order['hall'] ?? '',
            seats: List<String>.from(order['seats'] ?? []),
            fbItems: List<FBItem>.from(
              (order['foodItems'] ?? []).map((f) {
                return FBItem(
                  title: f['title'] ?? '',
                  quantity: f['quantity'] ?? 1,
                  popcorn: '',
                  drink: '',
                  food: '',
                );
              }),
            ),
            posterPath: order['poster'] ?? '',
            movieBannerPath: order['poster'] ?? '',
            isConfirmed: true,
          );

          ticketBookings.add(unbooking);
        }

        setState(() {});
      } catch (e, stack) {
        print("🔥 ERROR: $e");
        print("📍 StackTrace: $stack");
      }
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _showLocationDialog() {
    tempSelectedLocation = selectedLocation;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "SET YOUR PREFERRED STATE/AREA",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Experience what’s around you",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        for (String area in [
                          "All States/Areas",
                          "Klang Valley",
                          "Johor",
                          "Perak",
                          "Pulau Pinang",
                          "Sarawak",
                          "Negeri Sembilan",
                          "Terengganu",
                        ])
                          ListTile(
                            title: Text(
                              area,
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing:
                                tempSelectedLocation == area
                                    ? const Icon(Icons.check, color: Colors.red)
                                    : null,
                            onTap: () {
                              setModalState(() {
                                tempSelectedLocation = area;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: rememberLocation,
                        onChanged: (value) {
                          setModalState(() {
                            rememberLocation = value ?? false;
                          });
                        },
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                      ),
                      const Text(
                        "Remember my state/area",
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
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
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedLocation = tempSelectedLocation;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              topRight: Radius.circular(18),
                              bottomLeft: Radius.circular(18),
                              bottomRight: Radius.circular(5),
                            ),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 13),
                          child: Text(
                            "CONFIRM",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget bookingCard(Booking booking, bool isCurrent) {
    return Card(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.date,
                        style: const TextStyle(
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        booking.time,
                        style: const TextStyle(
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Ticket: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: booking.cinema,
                              style: const TextStyle(
                                color: Color.fromARGB(230, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Hall: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: booking.hall,
                              style: const TextStyle(
                                color: Color.fromARGB(230, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Seat(s): ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: booking.seats.join(', '),
                              style: const TextStyle(
                                color: Color.fromARGB(230, 255, 255, 255),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Order List:",
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      booking.fbItems.isNotEmpty
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                booking.fbItems.map((item) {
                                  String subtitle = '';
                                  if (item.popcorn.isNotEmpty ||
                                      item.drink.isNotEmpty) {
                                    subtitle =
                                        '(${item.popcorn}, ${item.drink})';
                                  }
                                  return Text(
                                    "${item.title} x${item.quantity} $subtitle",
                                    style: const TextStyle(
                                      color: Color.fromARGB(230, 255, 255, 255),
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList(),
                          )
                          : const Text(
                            "Not selected",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                    ],
                  ),
                ),
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        booking.posterPath.startsWith('http')
                            ? Image.network(
                              booking.posterPath,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                            )
                            : Image.asset(
                              booking.posterPath,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.broken_image,
                                    color: Colors.white,
                                  ),
                            ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
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
                    child: ElevatedButton(
                      onPressed: () {
                        if (bookingExpiryTime == null || currentBooking == null)
                          return;
                        final remaining = bookingExpiryTime!.difference(
                          DateTime.now(),
                        );
                        if (remaining.isNegative) return;

                        if (!currentBooking!.isConfirmed) {
                          // Navigate to F&B screen if seat not confirmed yet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => FoodDrinksScreen(
                                    initialTimeLeft: remaining,
                                    onTimeout: () {},
                                    movieTitle: currentBooking!.title,
                                    cinema: currentBooking!.cinema,
                                    date: currentBooking!.date,
                                    showtime: currentBooking!.time,
                                    selectedSeats: currentBooking!.seats.join(
                                      ', ',
                                    ),
                                    hall: currentBooking!.hall,
                                    totalSeatPrice:
                                        currentBooking!.seats.length * 17.00,
                                    movieCategory: "Action",
                                    movieDuration: "120 min",
                                    movieLanguage: "EN",
                                    moviePosterPath: currentBooking!.posterPath,
                                    movieBannerPath:
                                        currentBooking!.movieBannerPath,
                                    currentCartItems:
                                        currentBooking!.fbItems
                                            .map(
                                              (fbItem) => CartItem(
                                                title: fbItem.title,
                                                quantity: fbItem.quantity,
                                                popcornOption: fbItem.popcorn,
                                                drinkOption: fbItem.drink,
                                                price: _getPriceForItem(
                                                  fbItem.title.trim(),
                                                ),
                                                foodOption: fbItem.food,
                                                imagePath: _getImagePathForItem(
                                                  fbItem.title.trim(),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ConfirmSeatScreen(
                                    initialTimeLeft: remaining,
                                    movieTitle: currentBooking!.title,
                                    cinema: currentBooking!.cinema,
                                    date: currentBooking!.date,
                                    showtime: currentBooking!.time,
                                    selectedSeats: currentBooking!.seats,
                                    hall: currentBooking!.hall,
                                    totalSeatPrice:
                                        currentBooking!.seats.length * 17.00,
                                    movieCategory: "Action",
                                    movieDuration: "120 min",
                                    movieLanguage: "EN",
                                    moviePosterPath: currentBooking!.posterPath,
                                    movieBannerPath:
                                        currentBooking!.movieBannerPath,
                                  ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(5),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                      ),
                      child: const Text(
                        "VIEW DETAILS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
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

                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(18),
                            bottomRight: Radius.circular(5),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                      ),
                      child: Text(
                        isCurrent ? _getTimeLeft() : "COMMENT",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: PulsingLogo());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "My Booking",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: _showLocationDialog,
            icon: const Icon(Icons.location_on, color: Colors.white, size: 18),
            label: Text(
              (area ?? "KLANG VALLEY").toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Current Booking",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (currentBooking != null &&
              bookingExpiryTime != null &&
              !DateTime.now().isAfter(bookingExpiryTime!))
            bookingCard(currentBooking!, true)
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "No current bookings.",
                style: TextStyle(color: Colors.white54),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Ticket",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (ticketBookings.isNotEmpty)
            ...ticketBookings
                .map((booking) => bookingCard(booking, false))
                .toList()
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "No tickets available.",
                style: TextStyle(color: Colors.white54),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "History Booking",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          if (historyBookings.isNotEmpty)
            ...historyBookings
                .map((booking) => bookingCard(booking, false))
                .toList()
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "No past bookings.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}
