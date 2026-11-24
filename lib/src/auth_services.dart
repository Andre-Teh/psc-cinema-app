import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../admin/admin_dashboard.dart';
import '../manager/manger_dashboard.dart';

class AuthService {
  // SIGN UP
  Future<String?> signup({
    required String email,
    required String password,
    required BuildContext context,
    required ValueNotifier<Locale> localeNotifier,
    String? username,
    String? position,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        final displayName =
            username?.trim().isNotEmpty == true
                ? username!.trim()
                : email.split('@')[0];
        await FirebaseFirestore.instance
            .collection('Client')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'Email': user.email,
              'UserName': displayName,
              'Contact_Number': null,
              'birthday': null,
              'gender': null,
              'position': position ?? "customer",
              'language':
                  localeNotifier.value.languageCode == 'en'
                      ? 'Chinese'
                      : 'English',
              'createdAt': FieldValue.serverTimestamp(),
            });
        print("Successfully written to Firestore!");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(localeNotifier: localeNotifier),
        ),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        return 'An account already exists with that email.';
      } else {
        return 'Signup failed: ${e.message}';
      }
    } catch (e) {
      print(' SIGNUP ERROR: $e');
      return 'Signup failed. Please try again.';
    }
  }

  // Lof in
  Future<String?> signin({
    required String email,
    required String password,
    required BuildContext context,
    required ValueNotifier<Locale> localeNotifier,
  }) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('Client').doc(uid).get();

      if (!context.mounted) return null;

      final data = doc.data();
      if (data == null) {
        print("⚠️ No Firestore profile found for user $uid");
        return 'No profile found.';
      }

      final position =
          data['position']?.toString().toLowerCase().trim() ?? 'customer';
      print("🔐 User position: $position");

      if (position == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else if (position == 'manager') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MangerDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(localeNotifier: localeNotifier),
          ),
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        return 'Wrong password provided.';
      } else {
        return 'Login failed: ${e.message}';
      }
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  // Sign Ouytr
  Future<void> signout({
    required BuildContext context,
    required ValueNotifier<Locale> localeNotifier,
  }) async {
    await FirebaseAuth.instance.signOut();
    await Future.delayed(const Duration(seconds: 1));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => Login(localeNotifier: localeNotifier),
      ),
    );
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null; // 成功
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Failed to send reset email.";
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  // 🔍 获取当前登录用户的 Firestore profile 数据
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc =
        await FirebaseFirestore.instance
            .collection('Client')
            .doc(user.uid)
            .get();
    return doc.data();
  }

  Future<String?> updatePhoneNumber({
    required BuildContext context,
    required String phoneNumber,
    required void Function() onSuccess,
  }) async {
    try {
      final completer = Completer<String?>();
      String verificationId = "";

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 自动验证 (Android)
          await FirebaseAuth.instance.currentUser?.updatePhoneNumber(
            credential,
          );
          await _updatePhoneInFirestore(phoneNumber);
          onSuccess();
          completer.complete(null);
        },
        verificationFailed: (FirebaseAuthException e) {
          completer.complete("Verification failed: \${e.message}");
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          _showOtpInputDialog(
            context: context,
            onSubmit: (smsCode) async {
              final credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: smsCode,
              );
              try {
                await FirebaseAuth.instance.currentUser?.updatePhoneNumber(
                  credential,
                );
                await _updatePhoneInFirestore(phoneNumber);
                onSuccess();
                completer.complete(null);
              } on FirebaseAuthException catch (e) {
                completer.complete("Failed to update phone: \${e.message}");
              }
            },
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );

      return completer.future;
    } catch (e) {
      return "Unexpected error: \$e";
    }
  }

  Future<void> _updatePhoneInFirestore(String phone) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('Client')
          .doc(user.uid)
          .update({'Contact_Number': phone});
    }
  }

  void _showOtpInputDialog({
    required BuildContext context,
    required void Function(String smsCode) onSubmit,
  }) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "6-digit code"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSubmit(otpController.text.trim());
              },
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }
}