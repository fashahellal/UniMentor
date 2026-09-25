import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final Map<String, dynamic> bookingData;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.bookingData,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isProcessingDB = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (url.contains('paymentsuccess')) {
              setState(() {
                _isProcessingDB = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Redirect link
            if (request.url.startsWith(
              'https://unimentor.edu.my/paymentsuccess',
            )) {
              final Uri uri = Uri.parse(request.url);
              final String statusId = uri.queryParameters['status_id'] ?? '';

              // status_id == '1' - successful payment
              if (statusId == '1') {
                if (mounted) {
                  setState(() {
                    _isProcessingDB = true;
                  });
                }
                _saveBookingToFirestore();
              } else {
                // If status_id is '3' or others - means mentee press failed button
                if (mounted) {
                  Navigator.pop(
                    context,
                    false,
                  ); // Sends back false to Try Again message
                }
              }
              return NavigationDecision.prevent;
            }

            if (request.url.contains('status=failed') ||
                request.url.contains('status=cancel')) {
              if (mounted) {
                Navigator.pop(context, false);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _saveBookingToFirestore() async {
    try {
      String rawAmount = widget.bookingData['amount']?.toString() ?? "0";
      String formattedAmount = rawAmount.startsWith('RM')
          ? rawAmount
          : "RM $rawAmount";

      await FirebaseFirestore.instance.collection('bookings').add({
        ...widget.bookingData,
        'amount': formattedAmount,
        'isPaid': true,
        'status': 'Pending',
        'isCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true); // Returns true for success
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingDB = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error saving booking: $e")));
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ToyyibPay Sandbox Gateway"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isProcessingDB)
            Container(
              color: Colors.white.withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      "Securing your payment data...",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Please don't close the app or press back.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
