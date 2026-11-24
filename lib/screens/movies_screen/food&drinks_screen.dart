import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/home_screen.dart';
import 'package:psc_cinema_app/screens/my_booking_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'seat_selection_screen.dart';
import 'checkout_screen.dart';
import 'package:psc_cinema_app/screens/my_booking_screen.dart'
    show currentBooking, bookingExpiryTime, FBItem, Booking;

class FoodItem {
  final String imagePath;
  final String title;
  final double price;
  final int rewardPoints;
  final bool hasOptions;

  FoodItem({
    required this.imagePath,
    required this.title,
    required this.price,
    required this.rewardPoints,
    this.hasOptions = true,
  });
}

class CartItem {
  final String title;
  final double price;
  final int quantity;
  final String popcornOption;
  final String drinkOption;
  final String imagePath;
  final String foodOption;

  CartItem({
    required this.title,
    required this.price,
    required this.quantity,
    required this.popcornOption,
    required this.drinkOption,
    required this.imagePath,
    required this.foodOption,
  });
}

class FoodDrinksScreen extends StatefulWidget {
  final Duration initialTimeLeft;
  final VoidCallback onTimeout;
  final String movieTitle;
  final String cinema;
  final String date;
  final String showtime;
  final String hall;
  final double totalSeatPrice;
  final String selectedSeats;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final String moviePosterPath;
  final String movieBannerPath;
  final List<CartItem> currentCartItems;

  FoodDrinksScreen({
    super.key,
    required this.initialTimeLeft,
    required this.onTimeout,
    required this.movieTitle,
    required this.cinema,
    required this.date,
    required this.showtime,
    required this.hall,
    required this.totalSeatPrice,
    required this.selectedSeats,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
    this.currentCartItems = const [],
  });

  @override
  State<FoodDrinksScreen> createState() => _FoodDrinksScreenState();
}

class _FoodDrinksScreenState extends State<FoodDrinksScreen> {
  late Duration _timeLeft;
  Timer? _timer;
  bool _isCartOpen = false;
  List<CartItem> _cartItems = [];
  bool _isCartDetailsExpanded = true;

  double get totalCartFoodPrice {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  Future<void> fetchFBPackageItems() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('FandBPackage')
            .where('fbstatus', isEqualTo: 'Open')
            .get();

    List<FoodItem> fetchedItems =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return FoodItem(
            imagePath: data['image_url'] ?? '',
            title: data['package_name'] ?? '',
            price: (data['unit_price'] ?? 0).toDouble(),
            rewardPoints: ((data['unit_price'] ?? 0) * 0.5).toInt(),
            hasOptions: true,
          );
        }).toList();

    setState(() {
      bestsellerItems = fetchedItems;
      popcornComboItems =
          fetchedItems
              .where((item) => item.title.toLowerCase().contains('popcorn'))
              .toList();
      hotBitesItems =
          fetchedItems
              .where(
                (item) =>
                    item.title.toLowerCase().contains('chicken') ||
                    item.title.toLowerCase().contains('tofu'),
              )
              .toList();
    });
  }

  List<Map<String, dynamic>> drinkOptions = [];

  Future<void> loadDrinkOptions() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Beverages').get();

    final drinks =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['bevname'] ?? 'Unknown',
            'size': data['size'] ?? 'Unknown',
            'price': data['price'] ?? 'Unknown',
            'status': data['status'] ?? 'Close',
          };
        }).toList();

    setState(() {
      drinkOptions = drinks.where((d) => d['status'] == 'Open').toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchDrinkOptions() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Beverages').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['bevname'] ?? 'Unknown',
        'size': data['size'] ?? 'Unknown',
        'status': data['status'] ?? 'Close',
        'price': data['price'] ?? 'Unknown',
        'image': data['img_url'],
      };
    }).toList();
  }

  double? getSelectedDrinkPrice(String selectedDrinkName) {
    final selected = drinkOptions.firstWhere(
      (item) => "${item['name']} (${item['size']})" == selectedDrinkName,
      orElse: () => {},
    );

    if (selected.isEmpty || selected['price'] == null) return null;

    return double.tryParse(selected['price'].toString());
  }

  List<Map<String, dynamic>> foodOptions = [];

  Future<void> loadFoodOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('Food').get();

    final foods =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': data['foodname'] ?? 'Unknown',
            'size': data['size'] ?? 'Unknown',
            'price': data['price'] ?? 'Unknown',
            'status': data['status'] ?? 'Close',
          };
        }).toList();

    setState(() {
      print('Raw food snapshot: ${snapshot.docs.length}');
      foodOptions = foods.where((d) => d['status'] == 'Open').toList();
    });
  }

  Future<List<Map<String, dynamic>>> fetchFoodOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('Food').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['bevname'] ?? 'Unknown',
        'size': data['size'] ?? 'Unknown',
        'status': data['status'] ?? 'Close',
        'price': data['price'] ?? 'Unknown',
        'image': data['img_url'],
      };
    }).toList();
  }

  double? getSelectedFoodPrice(String selectedFoodName) {
    final selected = foodOptions.firstWhere(
      (item) => "${item['name']} (${item['size']})" == selectedFoodName,
      orElse: () => {},
    );

    if (selected.isEmpty || selected['price'] == null) return null;
    return double.tryParse(selected['price'].toString());
  }

  Future<List<Map<String, dynamic>>> fetchAvailableOptions(
    String collectionName,
  ) async {
    final snapshot =
        await FirebaseFirestore.instance.collection(collectionName).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'name': data['bevname'] ?? data['foodname'],
        'status': data['status'] ?? 'Close',
        'price': data['price'] ?? 'Unknown',
        'image': data['img_url'],
      };
    }).toList();
  }

  Widget _buildFoodGrid(List<FoodItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => _showFoodDetailModal(context, item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child:
                      item.imagePath.startsWith('http')
                          ? Image.network(
                            item.imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.broken_image),
                          )
                          : Image.asset(
                            item.imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFF5A6A6),
                        Color.fromARGB(255, 200, 137, 137),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Earn ${item.rewardPoints} MovieMoney',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add more if needed
  List<FoodItem> bestsellerItems = [];
  List<FoodItem> popcornComboItems = [];
  List<FoodItem> hotBitesItems = [];

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

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.initialTimeLeft;
    _cartItems = List.from(widget.currentCartItems);
    _startTimer();
    fetchFBPackageItems();
    loadDrinkOptions();
    loadFoodOptions();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 1) {
        widget.onTimeout();
        timer.cancel();
        _showTimeoutDialog();
      } else {
        setState(() => _timeLeft -= Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime =>
      '${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}';

  void _showFoodDetailModal(
    BuildContext context,
    FoodItem item, {
    CartItem? cartItemToEdit,
    int? editIndex,
  }) {
    loadDrinkOptions();
    // Initialize with existing data if editing
    int quantity = cartItemToEdit?.quantity ?? 1;
    String selectedPopcorn = cartItemToEdit?.popcornOption ?? '';
    String selectedDrink = cartItemToEdit?.drinkOption ?? '';
    String selectedFood = cartItemToEdit?.foodOption ?? '';
    bool isSimpleItem = !item.hasOptions;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bool isFormComplete =
                isSimpleItem ||
                (selectedFood.isNotEmpty && selectedDrink.isNotEmpty);

            return FractionallySizedBox(
              heightFactor: 0.95,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Color(0xFF7A4F4F)],
                    stops: [0.5, 0.8],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imagePath,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'RM ${item.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Earn ${item.rewardPoints} MovieMoney',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(5),
                                      topRight: Radius.circular(15),
                                      bottomRight: Radius.circular(5),
                                      bottomLeft: Radius.circular(15),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color:
                                              quantity == 1
                                                  ? Colors.grey
                                                  : Colors.black,
                                        ),
                                        onPressed:
                                            quantity > 1
                                                ? () {
                                                  setModalState(() {
                                                    quantity--;
                                                  });
                                                }
                                                : null,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.redAccent,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '$quantity',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          setModalState(() {
                                            quantity++;
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isSimpleItem) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Please Select Your Options',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            foodOptions.map((option) {
                              final size = option['size'] ?? 'Unknown';
                              final foodName = "${option['name']} ($size)";
                              final isSelectedFood = selectedFood == foodName;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() => selectedFood = foodName);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        isSelectedFood
                                            ? const LinearGradient(
                                              colors: [
                                                Color(0xFFF5A6A6),
                                                Color.fromARGB(
                                                  255,
                                                  200,
                                                  137,
                                                  137,
                                                ),
                                              ],
                                            )
                                            : null,
                                    color: isSelectedFood ? null : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Text(
                                    foodName,
                                    style: TextStyle(
                                      color:
                                          isSelectedFood
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(height: 20),

                      const SizedBox(height: 20),
                      const Text('DRINK OPTION'),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            drinkOptions.map((option) {
                              final size = option['size'] ?? 'Unknown';
                              final drinkName = "${option['name']} ($size)";
                              final isSelected = selectedDrink == drinkName;
                              return GestureDetector(
                                onTap: () {
                                  setModalState(
                                    () => selectedDrink = drinkName,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient:
                                        isSelected
                                            ? const LinearGradient(
                                              colors: [
                                                Color(0xFFF5A6A6),
                                                Color.fromARGB(
                                                  255,
                                                  200,
                                                  137,
                                                  137,
                                                ),
                                              ],
                                            )
                                            : null,
                                    color: isSelected ? null : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5),
                                    ),
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Text(
                                    drinkName,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],

                    const Spacer(),
                    Column(
                      children: [
                        GestureDetector(
                          onTap:
                              isFormComplete
                                  ? () {
                                    final foodExtraPrice = getSelectedFoodPrice(
                                      selectedFood,
                                    );
                                    final drinkExtraPrice =
                                        getSelectedDrinkPrice(selectedDrink);

                                    final totalPricePerUnit =
                                        item.price +
                                        (foodExtraPrice ?? 0) +
                                        (drinkExtraPrice ?? 0);

                                    setState(() {
                                      final newItem = CartItem(
                                        title: item.title,
                                        price: totalPricePerUnit,
                                        quantity: quantity,
                                        popcornOption: selectedPopcorn,
                                        drinkOption: selectedDrink,
                                        imagePath: item.imagePath,
                                        foodOption: selectedFood,
                                      );

                                      if (editIndex != null) {
                                        _cartItems[editIndex] = newItem;
                                      } else {
                                        _cartItems.add(newItem);
                                      }

                                      // 🔄 Immediately update currentCartItems & booking here

                                      currentBooking = Booking(
                                        title: widget.movieTitle,
                                        date: widget.date,
                                        time: widget.showtime,
                                        cinema: widget.cinema,
                                        hall: widget.hall,
                                        seats: widget.selectedSeats.split(', '),
                                        fbItems:
                                            _cartItems
                                                .map(
                                                  (item) => FBItem(
                                                    title: item.title,
                                                    quantity: item.quantity,
                                                    popcorn: item.popcornOption,
                                                    drink: item.drinkOption,
                                                    food: item.foodOption,
                                                  ),
                                                )
                                                .toList(),
                                        posterPath: widget.moviePosterPath,
                                        movieBannerPath: widget.movieBannerPath,
                                        isConfirmed: false,
                                      );

                                      bookingExpiryTime = DateTime.now().add(
                                        _timeLeft,
                                      );

                                      _isCartOpen = true;
                                    });

                                    Navigator.of(context).pop();
                                  }
                                  : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient:
                                  isFormComplete
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFFF5A6A6),
                                          Color.fromARGB(255, 200, 137, 137),
                                        ],
                                      )
                                      : null,
                              color:
                                  isFormComplete
                                      ? null
                                      : const Color(
                                        0xFFF5A6A6,
                                      ).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'ADD TO CART',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
          },
        );
      },
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

                // Stay button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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

                // Leave button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).popUntil(
                        (route) => route.isFirst,
                      ); // Close Food & Drinks page
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
                  "FOOD & DRINKS",
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
              _StepCircle(label: "1"),
              SizedBox(width: 4),
              _StepLine(),
              SizedBox(width: 4),
              _StepCircle(label: "2", isActive: true),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 20),
                _buildStepHeader(context),
                Container(
                  color: Colors.black,
                  child: const TabBar(
                    indicatorColor: Colors.redAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                    tabs: [
                      Tab(text: 'BESTSELLERS'),
                      Tab(text: 'POPCORN COMBO'),
                      Tab(text: 'HOT BITES COMBO'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      _buildFoodGrid(bestsellerItems),
                      _buildFoodGrid(popcornComboItems),
                      _buildFoodGrid(hotBitesItems),
                    ],
                  ),
                ),
              ],
            ),

            // Timer outside bottom bar
            Positioned(
              bottom: 90,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'TIME LEFT: $formattedTime',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF5A6A6),
                      Color.fromARGB(255, 200, 137, 137),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // VIEW CART - toggles cart
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCartOpen = !_isCartOpen;
                          });
                        },
                        child: Row(
                          children: const [
                            Text(
                              'VIEW CART',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_up, color: Colors.white),
                          ],
                        ),
                      ),

                      // CONTINUE - navigates to checkout
                      GestureDetector(
                        onTap: () {
                          currentBooking = Booking(
                            title: widget.movieTitle,
                            date: widget.date,
                            time: widget.showtime,
                            cinema: widget.cinema,
                            hall: widget.hall,
                            seats: widget.selectedSeats.split(', '),
                            fbItems:
                                _cartItems
                                    .map(
                                      (item) => FBItem(
                                        title: item.title,
                                        quantity: item.quantity,
                                        popcorn: item.popcornOption,
                                        drink: item.drinkOption,
                                        food: item.foodOption,
                                      ),
                                    )
                                    .toList(),
                            posterPath: widget.moviePosterPath,
                            movieBannerPath: widget.movieBannerPath,
                            isConfirmed: false,
                          );

                          bookingExpiryTime = DateTime.now().add(_timeLeft);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CheckoutScreen(
                                    movieTitle: widget.movieTitle,
                                    cinema: widget.cinema,
                                    date: widget.date,
                                    showtime: widget.showtime,
                                    hall: widget.hall,
                                    seatCount:
                                        (widget.totalSeatPrice / 17).round(),
                                    seatTotal: widget.totalSeatPrice,
                                    cartItems: _cartItems,
                                    initialTimeLeft: _timeLeft,
                                    selectedSeats: widget.selectedSeats,
                                    movieCategory: widget.movieCategory,
                                    movieDuration: widget.movieDuration,
                                    movieLanguage: widget.movieLanguage,
                                    moviePosterPath: widget.moviePosterPath,
                                    movieBannerPath: widget.movieBannerPath,
                                  ),
                            ),
                          );
                        },
                        child: Text(
                          'RM ${(totalCartFoodPrice).toStringAsFixed(2)} | CONTINUE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isCartOpen)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: 570,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'CART DETAILS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),

                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCartOpen = false;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'SEATS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
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
                                const SizedBox(height: 20),
                                const Text(
                                  'FOOD & DRINKS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                ..._cartItems.map((cartItem) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.network(
                                          cartItem.imagePath,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => const Icon(
                                                Icons.broken_image,
                                              ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${cartItem.title} x${cartItem.quantity}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              Text(
                                                '${cartItem.popcornOption}, ${cartItem.drinkOption}',
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                'RM ${cartItem.price.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            size: 16,
                                            color: Colors.redAccent,
                                          ),
                                          onPressed: () {
                                            _showFoodDetailModal(
                                              context,
                                              FoodItem(
                                                // Reconstruct FoodItem from CartItem
                                                title: cartItem.title,
                                                price: cartItem.price,
                                                rewardPoints:
                                                    325, // or use a field if stored
                                                imagePath: cartItem.imagePath,
                                              ),
                                              cartItemToEdit: cartItem,
                                              editIndex: _cartItems.indexOf(
                                                cartItem,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),

                        // Fixed bottom: timer + hide cart
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.timer,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'TIME LEFT: $formattedTime',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(5),
                                    topRight: Radius.circular(18),
                                    bottomRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(18),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF5A6A6),
                                      Color.fromARGB(255, 200, 137, 137),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,

                                  children: [
                                    // HIDE CART (left side)
                                    GestureDetector(
                                      onTap:
                                          () => setState(
                                            () => _isCartOpen = false,
                                          ),
                                      child: const Row(
                                        children: [
                                          Text(
                                            'HIDE CART',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_down,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // CONTINUE (right side)
                                    GestureDetector(
                                      onTap: () {
                                        currentBooking = Booking(
                                          title: widget.movieTitle,
                                          date: widget.date,
                                          time: widget.showtime,
                                          cinema: widget.cinema,
                                          hall: widget.hall,
                                          seats: widget.selectedSeats.split(
                                            ', ',
                                          ),
                                          fbItems:
                                              _cartItems
                                                  .map(
                                                    (item) => FBItem(
                                                      title: item.title,
                                                      quantity: item.quantity,
                                                      popcorn:
                                                          item.popcornOption,
                                                      drink: item.drinkOption,
                                                      food: item.foodOption,
                                                    ),
                                                  )
                                                  .toList(),
                                          posterPath: widget.moviePosterPath,
                                          movieBannerPath:
                                              widget.movieBannerPath,
                                          isConfirmed: false,
                                        );

                                        bookingExpiryTime = DateTime.now().add(
                                          _timeLeft,
                                        );

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => CheckoutScreen(
                                                  movieTitle: widget.movieTitle,
                                                  cinema: widget.cinema,
                                                  date: widget.date,
                                                  showtime: widget.showtime,
                                                  hall: widget.hall,
                                                  seatCount:
                                                      (widget.totalSeatPrice /
                                                              17)
                                                          .round(),
                                                  seatTotal:
                                                      widget.totalSeatPrice,
                                                  cartItems: _cartItems,
                                                  initialTimeLeft: _timeLeft,
                                                  selectedSeats:
                                                      widget.selectedSeats,
                                                  movieCategory:
                                                      widget.movieCategory,
                                                  movieDuration:
                                                      widget.movieDuration,
                                                  movieLanguage:
                                                      widget.movieLanguage,
                                                  moviePosterPath:
                                                      widget.moviePosterPath,
                                                  movieBannerPath:
                                                      widget.movieBannerPath,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'RM ${(totalCartFoodPrice).toStringAsFixed(2)} | CONTINUE',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
