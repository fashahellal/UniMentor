import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Mentor - Finance page
class MentorFinancePage extends StatefulWidget {
  const MentorFinancePage({super.key});

  @override
  State<MentorFinancePage> createState() => _MentorFinancePageState();
}

class _MentorFinancePageState extends State<MentorFinancePage> {
  final _withdrawFormKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _bankAccountController = TextEditingController();
  String? _selectedBank;

  // List of Malaysian bank options
  final List<String> _malaysianBanks = [
    "Affin Bank",
    "Alliance Bank",
    "AmBank",
    "Bank Islam",
    "Bank Muamalat",
    "Bank Rakyat",
    "BBSB Bank",
    "BSN",
    "CIMB Bank",
    "Hong Leong Bank",
    "HSBC Bank",
    "KFH",
    "Maybank2u / Maybank",
    "OCBC Bank",
    "Public Bank",
    "RHB Bank",
    "Standard Chartered",
    "UOB Bank",
  ];

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void dispose() {
    _amountController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Finance & Payouts",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mentors_wallets')
            .doc(currentUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          double availableBalance = 0.0;
          double totalWithdrawn = 0.0;

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            availableBalance = (data['availableBalance'] ?? 0.0).toDouble();
            totalWithdrawn = (data['totalWithdrawn'] ?? 0.0).toDouble();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildBalanceCard(
                        "Available Balance",
                        "RM ${availableBalance.toStringAsFixed(2)}",
                        Colors.green,
                        Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildBalanceCard(
                        "Total Cashed Out",
                        "RM ${totalWithdrawn.toStringAsFixed(2)}",
                        Colors.blueGrey,
                        Icons.check_circle_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: availableBalance <= 0
                        ? null
                        : () => _showWithdrawalSheet(availableBalance),
                    icon: const Icon(Icons.account_balance_rounded, size: 20),
                    label: const Text(
                      "Request Revenue Payout Withdrawal",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                const Text(
                  "Withdrawal History Log",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                const Divider(thickness: 1),
                _buildWithdrawalHistoryList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(
    String title,
    String value,
    Color themeColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: themeColor.withOpacity(0.1),
            radius: 18,
            child: Icon(icon, color: themeColor, size: 20),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: themeColor == Colors.green
                  ? Colors.green.shade700
                  : Colors.blueGrey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalHistoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('mentors_wallets')
          .doc(currentUid)
          .collection('withdrawals')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No processing or previous settlement entries logs found.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            double amount = (data['amount'] ?? 0.0).toDouble();
            String status = data['status'] ?? 'Pending';
            String bank =
                "${data['bankName'] ?? 'Unknown Bank'} — ${data['accountNumber'] ?? 'N/A'}";

            DateTime date = DateTime.now();
            if (data['timestamp'] != null && data['timestamp'] is Timestamp) {
              date = (data['timestamp'] as Timestamp).toDate();
            }

            String formattedDate = DateFormat(
              'dd MMM yyyy, hh:mm a',
            ).format(date);
            Color statusColor = Colors.orange;
            if (status == 'Approved') statusColor = Colors.green;
            if (status == 'Rejected') statusColor = Colors.red;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.08),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  "RM ${amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  "To: $bank\n$formattedDate",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showWithdrawalSheet(double maxBalance) {
    _amountController.text = maxBalance.toStringAsFixed(2);
    _selectedBank = null;
    _bankAccountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: _withdrawFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 45,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Toyyib Pay layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "toyyibPay Secure Cashout",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "B2B Payments · FPX Settlement Engine",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "FPX SECURE",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Funds are settled directly into Malayan banking accounts within 3 business working cycles.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Divider(height: 24),

                    // Input amount section
                    const Text(
                      "Withdrawal Target Amount",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.label_important,
                          color: Colors.purple,
                        ),
                        prefixText: "RM ",
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return "Please enter settlement amount";
                        final amt = double.tryParse(value);
                        if (amt == null || amt <= 0)
                          return "Enter a valid positive number";
                        if (amt > maxBalance)
                          return "Amount exceeds available wallet capacity";
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Bank selection ; Toyyib Pay layout
                    const Text(
                      "Receiving Bank Provider",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      hint: const Text(
                        "Select local processing bank Account...",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.account_balance,
                          color: Colors.purple,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 1.5,
                          ),
                        ),
                      ),
                      items: _malaysianBanks.map((String bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(
                            bank,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _selectedBank = value;
                        });
                      },
                      validator: (value) => value == null
                          ? "Please select a destination banking provider"
                          : null,
                    ),

                    const SizedBox(height: 16),

                    // Account Number Input
                    const Text(
                      "Bank Account Identification Number",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _bankAccountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "e.g., 164012345678 (Maybank)",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.credit_card,
                          color: Colors.purple,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Colors.purple,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Bank routing account identifier required"
                          : null,
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _executeWithdrawalTx(maxBalance),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Proceed Secure FPX Cashout Request",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Secured and certified by Bank Negara Malaysia guidelines.",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
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

  Future<void> _executeWithdrawalTx(double maxBalance) async {
    if (!_withdrawFormKey.currentState!.validate() || _selectedBank == null)
      return;

    double withdrawAmount = double.parse(_amountController.text.trim());
    String bank = _selectedBank!;
    String account = _bankAccountController.text.trim();

    Navigator.pop(context);

    final batch = FirebaseFirestore.instance.batch();
    var walletRef = FirebaseFirestore.instance
        .collection('mentors_wallets')
        .doc(currentUid);

    // Deduct from available balance
    batch.update(walletRef, {
      'availableBalance': FieldValue.increment(-withdrawAmount),
    });

    // Withdrawal request sent to admin
    var globalTxRef = FirebaseFirestore.instance
        .collection('payout_requests')
        .doc();

    Map<String, dynamic> requestData = {
      'requestId': globalTxRef.id,
      'mentorId': currentUid,
      'amount': withdrawAmount,
      'bankName': bank,
      'accountNumber': account,
      'status': 'Pending', // Pending waiting for admin
      'timestamp': FieldValue.serverTimestamp(),
    };

    batch.set(globalTxRef, requestData);

    var mentorTxRef = FirebaseFirestore.instance
        .collection('mentors_wallets')
        .doc(currentUid)
        .collection('withdrawals')
        .doc(globalTxRef.id);

    batch.set(mentorTxRef, requestData);

    await batch.commit();

    _amountController.clear();
    _bankAccountController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text(
            "Payout request submitted! Awaiting Admin verification and FPX settlement clearance.",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
  }
}
