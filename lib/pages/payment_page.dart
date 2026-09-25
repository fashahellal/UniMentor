import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_webview_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mentee - Payment page
class PaymentPage extends StatelessWidget {
  final Map<String, dynamic> bookingData;

  const PaymentPage({super.key, required this.bookingData});

  Future<void> _processMockPayment(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.purple)),
    );

    String studentName = 'UniMentor Student';
    String studentEmail = 'student@unimentor.edu.my';
    String studentPhone = '0123456789';

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          studentName =
              data['username'] ??
              currentUser.displayName ??
              'UniMentor Student';
          studentEmail =
              data['Email'] ?? currentUser.email ?? 'student@s.unikl.edu.my';
          studentPhone = data['Phone'] ?? '0123456789';
        }
      }
    } catch (e) {
      debugPrint("Pre-fetch user data profile error: $e");
    }

    const String userSecretKey = "wfamrb9k-oj1t-gm8j-8aqz-8guivmvshm1l";
    const String categoryCode = "jjgc4viv";

    String rawAmount = bookingData['amount'] ?? "50.00";
    double cleanAmount = double.parse(
      rawAmount.replaceAll(RegExp(r'[^\d.]'), ''),
    );
    int amountInCents = (cleanAmount * 100).round();

    String calculatedBillName = (() {
      String subject = bookingData['subject'] ?? "Tutoring";
      String fullName = "UM: $subject";
      return fullName.length > 30 ? fullName.substring(0, 30) : fullName;
    })();

    try {
      final response = await http.post(
        Uri.parse('https://dev.toyyibpay.com/index.php/api/createBill'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'userSecretKey': userSecretKey,
          'categoryCode': categoryCode,
          'billName': calculatedBillName,
          'billDescription': 'Tutoring session description',
          'billPriceSetting': '1',
          'billPayorInfo': '1',
          'billAmount': amountInCents.toString(),
          'billReturnUrl': 'https://unimentor.edu.my/paymentsuccess',
          'billCallbackUrl': 'https://toyyibpay.com/index.php',
          'billExternalReferenceNo':
              'REF${DateTime.now().millisecondsSinceEpoch}',
          'billTo': studentName,
          'billEmail': studentEmail,
          'billPhone': studentPhone,
        },
      );

      if (context.mounted) Navigator.pop(context);

      final decodedResponse = json.decode(response.body);
      String? billCode;

      if (decodedResponse is List && decodedResponse.isNotEmpty) {
        billCode = decodedResponse[0]['BillCode'];
      } else if (decodedResponse is Map<String, dynamic>) {
        billCode = decodedResponse['BillCode'];
      }

      if (billCode != null) {
        String paymentUrl = "https://dev.toyyibpay.com/$billCode";

        if (context.mounted) {
          final bool? paymentSuccessful = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewPage(
                paymentUrl: paymentUrl,
                bookingData: {
                  ...bookingData,
                  'menteeId': FirebaseAuth.instance.currentUser?.uid ?? '',
                  'menteeName': studentName,
                  'menteeEmail': studentEmail,
                  'menteePhone': studentPhone,
                },
              ),
            ),
          );

          if (!context.mounted) return;

          if (paymentSuccessful == true) {
            // SUCCESS ACTIONS
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                content: const Text(
                  "Payment Successful!\nYour booking request has been sent to the mentor.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Failure actions
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Icon(Icons.cancel, color: Colors.red, size: 60),
                content: const Text(
                  "Payment Failed or Cancelled.\nYour transaction could not be processed at this time.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                actions: [
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Try Again",
                        style: TextStyle(
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        throw Exception("Failed to extract valid reference token.");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gateway Connection Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    dynamic rawDate = bookingData['sessionDateTime'];
    DateTime date = (rawDate is Timestamp)
        ? rawDate.toDate()
        : (rawDate is DateTime ? rawDate : DateTime.now());

    String formattedDate = "${date.day}/${date.month}/${date.year}";
    String formattedTime =
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Checkout Summary"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Booking Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _summaryCard("Mentor", bookingData['mentorName'] ?? "N/A"),
            _summaryCard("Subject", bookingData['subject'] ?? "N/A"),
            _summaryCard("Date", formattedDate),
            _summaryCard("Time", formattedTime),
            _summaryCard(
              "Learning Mode",
              bookingData['meetingType'] ?? "Not Chosen",
            ),
            _summaryCard(
              "Amount",
              bookingData['amount'] ?? "RM 50.00",
              isBold: true,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _processMockPayment(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text(
                  "Confirm & Pay with ToyyibPay",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, {bool isBold = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
