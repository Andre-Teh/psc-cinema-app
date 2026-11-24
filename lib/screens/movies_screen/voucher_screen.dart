import 'package:flutter/material.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final TextEditingController _voucherController = TextEditingController();
  bool _isInputNotEmpty = false;
  bool _isValidVoucher = false;

  @override
  void initState() {
    super.initState();
    _voucherController.addListener(() {
      final input = _voucherController.text.trim();
      setState(() {
        _isInputNotEmpty = input.isNotEmpty;
        _isValidVoucher = input.toUpperCase() == 'DISCOUNT5';
      });
    });
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: BackButton(color: Colors.white),
        title: const Text(
          "VOUCHER CODE(S)",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ENTER VOUCHER CODE",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _voucherController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "E.g. DISCOUNT5",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF2C2C2C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isInputNotEmpty && !_isValidVoucher)
                  const Text(
                    "Invalid voucher code.",
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
              ],
            ),
          ),

          // APPLY VOUCHER BUTTON
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: GestureDetector(
              onTap:
                  _isValidVoucher
                      ? () {
                        Navigator.pop(context, _voucherController.text.trim());
                      }
                      : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient:
                      _isValidVoucher
                          ? const LinearGradient(
                            colors: [
                              Color(0xFFF5A6A6),
                              Color.fromARGB(255, 200, 137, 137),
                            ],
                          )
                          : null,
                  color:
                      _isValidVoucher
                          ? null
                          : const Color(0xFFF5A6A6).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "APPLY VOUCHER",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
