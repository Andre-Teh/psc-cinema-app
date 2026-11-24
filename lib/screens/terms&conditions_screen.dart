import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TextStyle normal = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.5,
    );
    TextStyle bold = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "TERMS & CONDITIONS",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/psc logo.png',
                  width: 180,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: normal,
                  children: [
                    TextSpan(
                      text:
                          'Welcome to the PSC Cinemas App (“App”), owned and operated by PSC Cinemas Sdn Bhd (“PSC Cinemas”, “we”, “our”, or “us”). By accessing or using our App, you agree to comply with and be bound by the following Terms and Conditions. Please read them carefully.\n\n',
                    ),
                    TextSpan(text: '1. Acceptance of Terms\n', style: bold),
                    TextSpan(
                      text:
                          'By downloading, installing, or using the PSC Cinemas App, you agree to be bound by these Terms and Conditions, our Privacy Policy, and any additional guidelines or rules applicable to specific features.\n\n',
                    ),
                    TextSpan(text: '2. Eligibility\n', style: bold),
                    TextSpan(
                      text:
                          'You must be at least 18 years old to use this App, or have permission from a parent or legal guardian. By using the App, you represent and warrant that you meet these requirements.\n\n',
                    ),
                    TextSpan(text: '3. User Account\n', style: bold),
                    TextSpan(
                      text:
                          'You must create an account to access certain features, including ticket booking and loyalty rewards.\n\n',
                    ),
                    TextSpan(
                      text:
                          'You are responsible for maintaining the confidentiality of your login credentials.\n\n',
                    ),
                    TextSpan(
                      text:
                          'You agree to provide accurate, complete, and current information.\n\n',
                    ),
                    TextSpan(
                      text:
                          'PSC Cinemas reserves the right to suspend or terminate your account if we suspect fraudulent activity or a violation of these Terms.\n\n',
                    ),
                    TextSpan(
                      text: '4. Ticket Booking and Payments\n',
                      style: bold,
                    ),
                    TextSpan(
                      text:
                          'Tickets are subject to availability and are only confirmed upon successful payment.\n\n',
                    ),
                    TextSpan(
                      text:
                          'All sales are final. No refunds or exchanges are allowed unless stated otherwise under our Refund Policy.\n\n',
                    ),
                    TextSpan(
                      text:
                          'PSC Cinemas reserves the right to cancel or reschedule screenings. In such cases, alternative arrangements will be offered.\n\n',
                    ),
                    TextSpan(text: '5. Loyalty Program\n', style: bold),
                    TextSpan(
                      text:
                          'If enrolled, points are earned based on qualifying purchases.\n\n',
                    ),
                    TextSpan(
                      text:
                          'Points and rewards are non-transferable and may expire based on program rules.\n\n',
                    ),
                    TextSpan(
                      text:
                          'PSC Cinemas reserves the right to modify or cancel the loyalty program at any time.\n\n',
                    ),
                    TextSpan(text: '6. Prohibited Activities\n', style: bold),
                    TextSpan(
                      text:
                          'You agree not to:\n\n• Use the App for illegal or unauthorized purposes.\n• Interfere with or disrupt the App’s functionality or servers.\n• Attempt to reverse-engineer, copy, or extract source code from the App.\n• Share or distribute content that is offensive, unlawful, or violates intellectual property rights.\n\n',
                    ),
                    TextSpan(text: '7. Intellectual Property\n', style: bold),
                    TextSpan(
                      text:
                          'All content and materials on the App, including logos, trademarks, graphics, and software, are owned by PSC Cinemas or its licensors and are protected by applicable intellectual property laws.\n\n',
                    ),
                    TextSpan(text: '8. Privacy\n', style: bold),
                    TextSpan(
                      text:
                          'Your use of the App is also governed by our Privacy Policy, which explains how we collect, use, and protect your personal data.\n\n',
                    ),
                    TextSpan(text: '9. Disclaimers\n', style: bold),
                    TextSpan(
                      text:
                          'The App is provided “as is” and “as available,” without warranties of any kind.\n\n',
                    ),
                    TextSpan(
                      text:
                          'PSC Cinemas does not guarantee that the App will be error-free or uninterrupted.\n\n',
                    ),
                    TextSpan(
                      text:
                          'We are not liable for any damages resulting from the use or inability to use the App.\n\n',
                    ),
                    TextSpan(
                      text: '10. Limitation of Liability\n',
                      style: bold,
                    ),
                    TextSpan(
                      text:
                          'To the fullest extent permitted by law, PSC Cinemas shall not be liable for any direct, indirect, incidental, consequential, or punitive damages arising out of your use of the App.\n\n',
                    ),
                    TextSpan(text: '11. Modifications to Terms\n', style: bold),
                    TextSpan(
                      text:
                          'PSC Cinemas reserves the right to modify these Terms at any time. Changes will be effective immediately upon posting. Continued use of the App after changes constitutes acceptance.\n\n',
                    ),
                    TextSpan(text: '12. Governing Law\n', style: bold),
                    TextSpan(
                      text:
                          'These Terms shall be governed by and construed in accordance with the laws of Malaysia. Any disputes arising out of these Terms shall be subject to the exclusive jurisdiction of the courts of Malaysia.\n\n',
                    ),
                    TextSpan(text: '13. Contact Us\n', style: bold),
                    TextSpan(
                      text:
                          'If you have any questions about these Terms, please contact us at:\n\nPSC Cinemas Sdn Bhd\nfeedback@psc.com.my\n+60 12-345 6789\nLot 15,\nLevel 3, Pavilion Elite\n168 Jalan Bukit Bintang\n55100 Kuala Lumpur\nWilayah Persekutuan, Malaysia',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
