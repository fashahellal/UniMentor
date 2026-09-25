import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'mentor_finance_page.dart';

// Mentor - Dashboard page
class MentorDashboardPage extends StatefulWidget {
  const MentorDashboardPage({super.key});

  @override
  State<MentorDashboardPage> createState() => _MentorDashboardPageState();
}

class _MentorDashboardPageState extends State<MentorDashboardPage> {
  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Financial Performance",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MentorFinancePage(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.purple,
                    size: 18,
                  ),
                  label: const Text(
                    "Wallet & Payouts",
                    style: TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildFinancialOverview(),
            const SizedBox(height: 30),
            const Text(
              "Active Booked Sessions Manager",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const Text(
              "Click an active scheduled layout item below to flag it as completed for the mentee.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildMentorSessionsTracker(),
            const SizedBox(height: 30),
            const Text(
              "Student Learning Progress Tracker",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const Text(
              "Tap on any student card below to update milestones and provide session feedback comments.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            _buildCoCurriculumTracker(),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('mentorId', isEqualTo: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        double totalEarnings = 0;
        int completedSessions = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? '';

            if (status == 'Completed') {
              completedSessions++;
              var rawAmount = data['amount'] ?? "RM 0.00";
              String cleanAmountString = rawAmount
                  .toString()
                  .replaceAll('RM', '')
                  .trim();
              double parsedPrice = double.tryParse(cleanAmountString) ?? 0.0;
              totalEarnings += parsedPrice;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _financeStat(
                    "RM ${totalEarnings.toStringAsFixed(2)}",
                    "Total Revenue",
                    Icons.monetization_on,
                  ),
                  Container(width: 1, height: 50, color: Colors.grey.shade300),
                  _financeStat(
                    "$completedSessions",
                    "Sessions Hosted",
                    Icons.event_available,
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 15),
                child: Divider(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Wallet Balance Available:",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('mentors_wallets')
                        .doc(currentUid)
                        .snapshots(),
                    builder: (context, walletSnap) {
                      double walletBal = 0.0;
                      if (walletSnap.hasData && walletSnap.data!.exists) {
                        var wData =
                            walletSnap.data!.data() as Map<String, dynamic>;
                        walletBal = (wData['availableBalance'] ?? 0.0)
                            .toDouble();
                      }
                      return Text(
                        "RM ${walletBal.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _financeStat(String value, String title, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.purple, size: 18),
            const SizedBox(width: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMentorSessionsTracker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('mentorId', isEqualTo: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        final sessionDocs = snapshot.data?.docs ?? [];
        final activeSessions = sessionDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          String s = data['status'] ?? '';
          return s == 'Accepted' || s == 'Completed' || s == 'Upcoming';
        }).toList();

        if (activeSessions.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No active booked schedules on file.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: activeSessions.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String status = data['status'] ?? 'Upcoming';

            String rawName =
                data['menteeName'] ?? data['studentName'] ?? "Student";
            String studentName =
                (rawName == "Student" && data['menteeId'] != null)
                ? "Student (${data['menteeId'].toString().substring(0, 5)})"
                : rawName;

            DateTime sessionTime = DateTime.now();
            if (data['sessionDateTime'] != null &&
                data['sessionDateTime'] is Timestamp) {
              sessionTime = (data['sessionDateTime'] as Timestamp).toDate();
            }

            String formatted = DateFormat(
              'MMM dd, yyyy @ h:mm a',
            ).format(sessionTime);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  status == 'Completed'
                      ? Icons.verified
                      : Icons.pending_actions,
                  color: status == 'Completed' ? Colors.green : Colors.orange,
                ),
                title: Text("Student: $studentName"),
                subtitle: Text(
                  "Topic: ${data['subject'] ?? 'General'}\nTime: $formatted\nStatus: $status",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: status == 'Completed'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        onPressed: () {
                          var rawAmount = data['amount'] ?? "RM 50.00";
                          String cleanAmountString = rawAmount
                              .toString()
                              .replaceAll('RM', '')
                              .trim();
                          double earned =
                              double.tryParse(cleanAmountString) ?? 50.0;
                          _updateSessionToCompleted(doc.id, earned);
                        },
                        child: const Text(
                          "Complete",
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _updateSessionToCompleted(
    String docId,
    double amountEarned,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    var bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(docId);
    batch.update(bookingRef, {'status': 'Completed'});

    var walletRef = FirebaseFirestore.instance
        .collection('mentors_wallets')
        .doc(currentUid);
    batch.set(walletRef, {
      'availableBalance': FieldValue.increment(amountEarned),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Session marked as Completed! Revenue sent to wallet balance.",
          ),
        ),
      );
    }
  }

  Widget _buildCoCurriculumTracker() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cocurriculum_progress')
          .where('mentorId', isEqualTo: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "No live student tracking records found.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            List<String> rawMilestones = List<String>.from(
              data['milestonesList'] ?? [],
            );
            Map<String, bool> rawChecks = Map<String, bool>.from(
              data['milestonesChecked'] ?? {},
            );

            String rawName = data['studentName'] ?? "Student";
            String studentName =
                (rawName == "Student" && data['menteeId'] != null)
                ? "Student (${data['menteeId'].toString().substring(0, 5)})"
                : rawName;

            return _studentProgressCard(
              docId: doc.id,
              studentName: studentName,
              activity: data['activityName'] ?? "Co-Curriculum Module",
              percentage: (data['progressPercentage'] ?? 0.0).toDouble(),
              label: data['statusText'] ?? "In Progress",
              currentComment: data['mentorComment'] ?? "No comments added yet.",
              milestonesList: rawMilestones,
              milestonesChecked: rawChecks,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _studentProgressCard({
    required String docId,
    required String studentName,
    required String activity,
    required double percentage,
    required String label,
    required String currentComment,
    required List<String> milestonesList,
    required Map<String, bool> milestonesChecked,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showUpdateProgressDialog(
          docId,
          studentName,
          activity,
          percentage,
          label,
          currentComment,
          milestonesList,
          milestonesChecked,
        ),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "${(percentage * 100).toInt()}% Done",
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                activity,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: Colors.purple,
                minHeight: 8,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Latest Mentor Feedback:",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentComment,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Click card to manage checklists",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.purple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateProgressDialog(
    String docId,
    String studentName,
    String activity,
    double currentProgress,
    String currentLabel,
    String currentComment,
    List<String> initialMilestones,
    Map<String, bool> initialChecks,
  ) {
    List<String> localMilestones = List<String>.from(initialMilestones);
    Map<String, bool> localChecks = Map<String, bool>.from(initialChecks);

    final commentController = TextEditingController(
      text: currentComment == "No comments added yet." ? "" : currentComment,
    );
    final addMilestoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalTasks = localMilestones.length;
            int completedTasks = localMilestones
                .where((m) => localChecks[m] == true)
                .length;
            double calculatedPercentage = totalTasks > 0
                ? (completedTasks / totalTasks)
                : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 25,
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Track & Evaluate: $studentName",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      activity,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.purple,
                      ),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Milestones Checklist",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${(calculatedPercentage * 100).toInt()}% Done",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addMilestoneController,
                            decoration: const InputDecoration(
                              hintText: "Add custom milestone item...",
                              hintStyle: TextStyle(fontSize: 13),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                          ),
                          onPressed: () {
                            String text = addMilestoneController.text.trim();
                            if (text.isNotEmpty &&
                                !localMilestones.contains(text)) {
                              setModalState(() {
                                localMilestones.add(text);
                                localChecks[text] = false;
                              });
                              addMilestoneController.clear();
                            }
                          },
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (localMilestones.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "No milestones listed. Create one above.",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ...localMilestones.map((milestone) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Checkbox(
                          activeColor: Colors.purple,
                          value: localChecks[milestone] ?? false,
                          onChanged: (val) {
                            setModalState(() {
                              localChecks[milestone] = val ?? false;
                            });
                          },
                        ),
                        title: Text(
                          milestone,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () {
                            setModalState(() {
                              localMilestones.remove(milestone);
                              localChecks.remove(milestone);
                            });
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 15),
                    const Text(
                      "Progress Assessment Comments",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText:
                            "Enter constructive feedback on student contribution...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          String finalComment = commentController.text.trim();
                          int finalTotal = localMilestones.length;
                          int finalCompleted = localMilestones
                              .where((m) => localChecks[m] == true)
                              .length;
                          double finalPercentage = finalTotal > 0
                              ? (finalCompleted / finalTotal)
                              : 0.0;

                          await FirebaseFirestore.instance
                              .collection('cocurriculum_progress')
                              .doc(docId)
                              .update({
                                'milestonesList': localMilestones,
                                'milestonesChecked': localChecks,
                                'progressPercentage': finalPercentage,
                                'statusText':
                                    "Milestone $finalCompleted/$finalTotal verified",
                                'mentorComment': finalComment.isEmpty
                                    ? "No comments added yet."
                                    : finalComment,
                                'lastUpdated': FieldValue.serverTimestamp(),
                              });
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text(
                          "Save Evaluation Changes",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
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
}
