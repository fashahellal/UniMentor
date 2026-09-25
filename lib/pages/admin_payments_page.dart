import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminPaymentPage extends StatelessWidget {
  const AdminPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "TRANSACTION MANAGEMENT",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: "Student Bookings"),
              Tab(icon: Icon(Icons.account_balance), text: "Payout Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildStudentBookingsTab(), _buildPayoutRequestsTab()],
        ),
      ),
    );
  }

  // Mentee bookings view
  Widget _buildStudentBookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('isPaid', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "Error loading transaction logs: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        final paymentLogs = snapshot.data?.docs ?? [];
        if (paymentLogs.isEmpty) {
          return _buildEmptyState("No payments recorded yet.");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: paymentLogs.length,
          itemBuilder: (context, index) {
            var doc = paymentLogs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String mentee = data['menteeName'] ?? "Unknown Student";
            String mentor = data['mentorName'] ?? "Unknown Mentor";
            String subject = data['subject'] ?? "General Module";
            String amount = data['amount'] ?? "RM 0.00";
            String status = data['status'] ?? "Pending";

            String formattedDate = "N/A";
            if (data['createdAt'] != null) {
              DateTime date = (data['createdAt'] as Timestamp).toDate();
              formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
            }

            Color statusColor = status == 'Accepted'
                ? Colors.green
                : (status == 'Rejected' ? Colors.red : Colors.orange);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRowItem(
                      Icons.person_outline,
                      "Mentee (Payer):",
                      mentee,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(
                      Icons.school_outlined,
                      "Mentor (Receiver):",
                      mentor,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(
                      Icons.book_outlined,
                      "Subject Topic:",
                      subject,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(
                      Icons.calendar_today_outlined,
                      "Payment Date:",
                      formattedDate,
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

  // Real time payout
  Widget _buildPayoutRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payout_requests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error fetching payouts: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        final requests = snapshot.data?.docs ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState("No cashout extraction logs found.");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            var doc = requests[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            String requestId = data['requestId'] ?? "";
            String mentorId = data['mentorId'] ?? "";
            double amount = (data['amount'] ?? 0.0).toDouble();
            String bankName = data['bankName'] ?? "Unknown Bank";
            String accountNumber = data['accountNumber'] ?? "N/A";
            String status = data['status'] ?? "Pending";

            String formattedDate = "N/A";
            if (data['timestamp'] != null) {
              DateTime date = (data['timestamp'] as Timestamp).toDate();
              formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
            }

            Color statusColor = status == 'Approved'
                ? Colors.green
                : (status == 'Rejected' ? Colors.red : Colors.orange);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "RM ${amount.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRowItem(
                      Icons.badge_outlined,
                      "Mentor UID:",
                      mentorId,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(
                      Icons.account_balance_rounded,
                      "Target Bank:",
                      bankName,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(
                      Icons.credit_card_rounded,
                      "Account No:",
                      accountNumber,
                    ),
                    const SizedBox(height: 6),
                    _buildRowItem(Icons.schedule, "Requested:", formattedDate),

                    // If the request is Pending, show actionable management triggers
                    if (status == 'Pending') ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _processPayout(
                              context,
                              requestId,
                              mentorId,
                              amount,
                              false,
                            ),
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 16,
                            ),
                            label: const Text(
                              "REJECT",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _processPayout(
                              context,
                              requestId,
                              mentorId,
                              amount,
                              true,
                            ),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text(
                              "APPROVE & SETTLE",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Admin transaction process (approval for mentor payout request)
  Future<void> _processPayout(
    BuildContext context,
    String requestId,
    String mentorId,
    double amount,
    bool isApproved,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final batch = FirebaseFirestore.instance.batch();

    var globalRequestRef = FirebaseFirestore.instance
        .collection('payout_requests')
        .doc(requestId);
    var mentorRequestRef = FirebaseFirestore.instance
        .collection('mentors_wallets')
        .doc(mentorId)
        .collection('withdrawals')
        .doc(requestId);
    var walletRef = FirebaseFirestore.instance
        .collection('mentors_wallets')
        .doc(mentorId);

    if (isApproved) {
      // Request approved
      // Update status to approve
      batch.update(globalRequestRef, {'status': 'Approved'});
      batch.update(mentorRequestRef, {'status': 'Approved'});
      // Update total withdrawn amount (Mentor Page)
      batch.update(walletRef, {'totalWithdrawn': FieldValue.increment(amount)});
    } else {
      // Request rejected
      // Update status to rejected
      batch.update(globalRequestRef, {'status': 'Rejected'});
      batch.update(mentorRequestRef, {'status': 'Rejected'});
      // Amount refunded into mentor's wallet
      batch.update(walletRef, {
        'availableBalance': FieldValue.increment(amount),
      });
    }

    try {
      await batch.commit();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: isApproved
              ? Colors.green.shade700
              : Colors.red.shade700,
          content: Text(
            isApproved
                ? "FPX clearing finalized. Settlement disbursed successfully."
                : "Settlement rejected. Retracted tokens returned to mentor wallet profile.",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Transactional execution error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRowItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 65,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
