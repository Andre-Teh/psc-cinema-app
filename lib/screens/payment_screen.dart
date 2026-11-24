import 'package:flutter/material.dart';
import 'package:psc_cinema_app/screens/my_booking_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:psc_cinema_app/screens/movies_screen/seat_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class PaymentScreen extends StatefulWidget {
  final double totalPrice;
  final String movieTitle;
  final String cinema;
  final String date;
  final String time;
  final String showtime;
  final String hall;
  final String movieCategory;
  final String movieDuration;
  final String movieLanguage;
  final String moviePosterPath;
  final String movieBannerPath;
  final List<String> selectedSeats;
  final String orderId;

  const PaymentScreen({
    super.key,
    required this.totalPrice,
    required this.movieTitle,
    required this.cinema,
    required this.date,
    required this.time,
    required this.showtime,
    required this.hall,
    required this.movieCategory,
    required this.movieDuration,
    required this.movieLanguage,
    required this.moviePosterPath,
    required this.movieBannerPath,
    required this.selectedSeats,
    required this.orderId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _bankAccController = TextEditingController();
  final _bankHolderController = TextEditingController();
  final _walletAccController = TextEditingController();
  final _walletHolderController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cardNumberParts = List.generate(4, (_) => TextEditingController());
  final _cardNumberFocus = List.generate(4, (_) => FocusNode());
  String selectedMethod = "CREDIT / DEBIT CARD";
  String? selectedBank;
  String? selectedEWallet;
  bool termsAccepted = false;
  final uuid = Uuid();
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> wallets = [];
  bool isLoadingBanks = true;
  bool isLoadingWallets = true;

  late String orderId;
  late String paymentId;
  late String orderDescription;

  @override
  void initState() {
    super.initState();
    orderId = widget.orderId;
    paymentId = uuid.v4().substring(0, 8).toUpperCase();
    orderDescription = "";
    _fetchOrderDescription();
    _loadBanks();
    _loadEWallets();
  }

  void _updateFullCardNumber() {
    final fullNumber = _cardNumberParts
        .map((c) => c.text.padRight(4, ' '))
        .join('-');
    _cardNumberController.text = fullNumber.trim();
  }

  void _fetchOrderDescription() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('order_data')
            .doc(widget.orderId)
            .get();

    if (doc.exists) {
      final data = doc.data();
      setState(() {
        orderDescription = data?['orderDescription'] ?? '';
        _emailController.text = data?['email'] ?? '';
      });
    }
  }

  void _loadBanks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Bank_Type').get();
      setState(() {
        banks =
            snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        isLoadingBanks = false;
      });
    } catch (e) {
      print(" Failed to load banks: $e");
      setState(() => isLoadingBanks = false);
    }
  }

  void _loadEWallets() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('e-wallet').get();
      setState(() {
        wallets =
            snapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
        isLoadingWallets = false;
      });
    } catch (e) {
      print("❌ Failed to load e-wallets: $e");
      setState(() => isLoadingWallets = false);
    }
  }

  Future<void> _savePaymentData() async {
    try {
      final orderRef = FirebaseFirestore.instance
          .collection('order_data')
          .doc(widget.orderId);
      final orderSnapshot = await orderRef.get();

      if (!orderSnapshot.exists) {
        print("Order not found");
        return;
      }

      final orderData = orderSnapshot.data()!;
      final email = orderData['email'] ?? '';
      final description = orderData['orderDescription'] ?? '';

      final paymentData = {
        'OrderID': widget.orderId,
        'PaymentID': paymentId,
        'OrderDescription': description,
        'Email': email,
        'PaymentMethod': selectedMethod,
        'TotalPrice': widget.totalPrice,
        'Card_Holder':
            selectedMethod == 'CREDIT / DEBIT CARD'
                ? _cardHolderController.text
                : null,
        'Card_Number':
            selectedMethod == 'CREDIT / DEBIT CARD'
                ? _cardNumberController.text
                : null,
        'BankAcc':
            selectedMethod == 'ONLINE TRANSFER'
                ? _bankAccController.text
                : null,
        'Bank Holder Name':
            selectedMethod == 'ONLINE TRANSFER'
                ? _bankHolderController.text
                : null,
        'E-WalletAcc':
            selectedMethod == 'E-WALLET' ? _walletAccController.text : null,
        'E-Wallet Holder':
            selectedMethod == 'E-WALLET' ? _walletHolderController.text : null,
        'Status': 'Successful',
        'Timestamp': FieldValue.serverTimestamp(),
      };

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final clientRef = FirebaseFirestore.instance
            .collection('Client')
            .doc(user.uid);
        final clientSnapshot = await clientRef.get();

        if (clientSnapshot.exists) {
          final currentRewards =
              (clientSnapshot.data()?['Rewards'] ?? 0).toInt();
          final newRewards =
              currentRewards + widget.totalPrice.toInt(); // 1 RM = 1 Point

          await clientRef.update({'Rewards': newRewards});
          print("Rewards updated to $newRewards");
        }
      }

      await FirebaseFirestore.instance
          .collection('Payment_Data')
          .add(paymentData);
      print("Payment data saved");

      await orderRef.update({'status': 'PAID', 'paymentID': paymentId});

      print("Order status updated to PAID");
    } catch (e) {
      print("Failed to save payment or update order: $e");

      await FirebaseFirestore.instance.collection('Payment_Data').add({
        'OrderID': widget.orderId,
        'PaymentID': paymentId,
        'Status': 'Failed',
        'Error': e.toString(),
        'Timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _buildBankOptions(List<Map<String, dynamic>> banks) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          banks.map((bank) {
            return GestureDetector(
              onTap: () {
                if (selectedBank != bank['bank_name']) {
                  selectedBank = bank['bank_name'];
                  setState(() {});
                }
              },
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.network(
                  bank['bank_image'] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEWalletOptions(List<Map<String, dynamic>> wallets) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          wallets.map((wallet) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedEWallet = wallet['e-wallet_name'] ?? '';
                });
              },
              child: Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.network(
                  wallet['e-wallet_image'] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                ),
              ),
            );
          }).toList(),
    );
  }

  void _confirmAndSubmit() async {
    if (!termsAccepted) return;
    await _savePaymentData();

    final booking = Booking(
      title: widget.movieTitle,
      date: widget.date,
      time: widget.time,
      cinema: widget.cinema,
      hall: widget.hall,
      seats: widget.selectedSeats,
      posterPath: widget.moviePosterPath,
      movieBannerPath: widget.movieBannerPath,
      isConfirmed: true,
    );

    currentBooking = null;
    bookingExpiryTime = null;
    historyBookings.add(booking);

    Navigator.of(context).popUntil((route) => route.isFirst);
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
                      Navigator.of(context).pop(); // Close the dialog
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showExitConfirmation(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/psc logo.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    "PSC",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Divider(color: Colors.white, thickness: 1.5),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Payment Details",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            _detailText("Order ID:", orderId),
            _detailText("Payment ID:", paymentId),
            _orderDescriptionText("Order Description:", orderDescription),

            const SizedBox(height: 8),
            _inputField("Email", Icons.email, controller: _emailController),

            const SizedBox(height: 8),
            _inputField("Phone", Icons.phone, controller: _phoneController),
            const SizedBox(height: 16),

            Text(
              "Payment Methods",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _paymentOption("CREDIT / DEBIT CARD"),
                _paymentOption("ONLINE TRANSFER"),
                _paymentOption("E-WALLET"),
              ],
            ),
            const SizedBox(height: 25),

            if (selectedMethod == "CREDIT / DEBIT CARD") ...[
              _inputField(
                "Card Holder Name",
                null,
                hintText: "Enter Card Name",
                controller: _cardHolderController,
              ),
              const SizedBox(height: 20),
              Text(
                "Card Number",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _cardNumberParts[i],
                        focusNode: _cardNumberFocus[i],
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          if (value.length == 4 && i < 3) {
                            FocusScope.of(
                              context,
                            ).requestFocus(_cardNumberFocus[i + 1]);
                          }
                          _updateFullCardNumber();
                        },
                        decoration: const InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text("Card Type", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _cardTypeBox("assets/payment/Visa.webp"),
                  _cardTypeBox("assets/payment/mastercard.png"),
                  _cardTypeBox("assets/payment/american_express.png"),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Expiration Date",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      hint: Text("MM"),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          child: Text("${(i + 1).toString().padLeft(2, '0')}"),
                          value: "${i + 1}",
                        ),
                      ),
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                      hint: Text("YYYY"),
                      items: List.generate(
                        10,
                        (i) => DropdownMenuItem(
                          child: Text("${2024 + i}"),
                          value: "${2024 + i}",
                        ),
                      ),
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 3,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  labelText: "CCV2",
                  hintText: "CCV2",
                  counterText: "",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (selectedMethod == "ONLINE TRANSFER" &&
                !isLoadingBanks &&
                banks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBankOptions(banks),
                  const SizedBox(height: 20),
                  _inputField(
                    "Bank Holder Name",
                    null,
                    controller: _bankHolderController,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    "Bank Account Number",
                    null,
                    controller: _bankAccController,
                  ),
                ],
              ),

            if (selectedMethod == "E-WALLET" &&
                !isLoadingWallets &&
                wallets.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEWalletOptions(wallets),
                  const SizedBox(height: 20),
                  _inputField(
                    "E-Wallet Holder Name",
                    null,
                    controller: _walletHolderController,
                  ),
                  const SizedBox(height: 10),
                  _inputField(
                    "E-Wallet Account Number",
                    null,
                    controller: _walletAccController,
                  ),
                ],
              ),
          ],
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        termsAccepted = value;
                      });
                    },
                    activeColor: Color.fromARGB(255, 150, 103, 103),
                    activeTrackColor: Color(0xFFF5A6A6),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "I agree to the terms and conditions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            Opacity(
              opacity: termsAccepted ? 1.0 : 0.6,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient:
                      termsAccepted
                          ? LinearGradient(
                            colors: [
                              Color(0xFFF5A6A6),
                              Color.fromARGB(255, 200, 137, 137),
                            ],
                          )
                          : null,
                  color: termsAccepted ? null : Colors.grey,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
                child: ElevatedButton(
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
                  onPressed: termsAccepted ? _confirmAndSubmit : null,
                  child: Text(
                    "PAYMENT - RM ${widget.totalPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
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

  Widget _detailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label ", style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    IconData? icon, {
    String? hintText,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _paymentOption(String label) {
    bool isSelected = selectedMethod == label;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = label),
      child: Container(
        width: 100,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      Color(0xFFF5A6A6),
                      Color.fromARGB(255, 200, 137, 137),
                    ],
                  )
                  : null,
          border: isSelected ? null : Border.all(color: Colors.grey),
          color: isSelected ? null : Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardTypeBox(String imagePath) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _bankOptionBox(String imagePath) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Image.asset(imagePath, fit: BoxFit.contain),
    );
  }

  Widget _orderDescriptionText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}
