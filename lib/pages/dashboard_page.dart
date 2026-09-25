import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// Mentee - Dashboard page
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Launcher functions and open online meeting links
  Future<void> _launchMeetingURL(BuildContext context, String urlString) async {
    String formattedUrl = urlString.trim();
    if (formattedUrl.isEmpty) return;

    if (!formattedUrl.startsWith('http://') &&
        !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }

    final Uri url = Uri.parse(formattedUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $formattedUrl';
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cannot open link: Invalid or broken meeting URL format",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "DASHBOARD",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('menteeId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, bookingSnapshot) {
          if (bookingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBookings = bookingSnapshot.data?.docs ?? [];

          // Active mentorships view
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _sectionCard(
                  "Active Mentorships",
                  _mentorshipList(allBookings),
                ),
                const SizedBox(height: 20),

                // Mentee progress - updated by mentor
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('cocurriculum_progress')
                      .where('menteeId', isEqualTo: currentUserId)
                      .snapshots(),
                  builder: (context, progressSnapshot) {
                    if (progressSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.purple),
                      );
                    }

                    double progressValue = 0.0;
                    String statusText = "In Progress";
                    String mentorComment = "No comments added yet.";

                    if (progressSnapshot.hasData &&
                        progressSnapshot.data!.docs.isNotEmpty) {
                      var progData =
                          progressSnapshot.data!.docs.first.data()
                              as Map<String, dynamic>;
                      progressValue = (progData['progressPercentage'] ?? 0.0)
                          .toDouble();
                      statusText = progData['statusText'] ?? "In Progress";
                      mentorComment =
                          progData['mentorComment'] ?? "No comments added yet.";
                    }

                    return _sectionCard(
                      "Your Progress",
                      _progressDetailedWidget(
                        progressValue,
                        statusText,
                        mentorComment,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
                _sectionCard(
                  "Upcoming & Active Sessions",
                  _sessionList(context, allBookings),
                ),
                const SizedBox(height: 20),
                _sectionCard(
                  "Transaction History",
                  _transactionList(allBookings),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionCard(String title, Widget content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _mentorshipList(List<QueryDocumentSnapshot> docs) {
    final activeDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('status') && data['status'] == 'Accepted';
    }).toList();

    if (activeDocs.isEmpty) return const Text("No active mentorships yet.");

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: activeDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _mentorAvatar(data['mentorName'] ?? "Mentor");
        }).toList(),
      ),
    );
  }

  Widget _mentorAvatar(String name) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.purple,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _progressDetailedWidget(double value, String status, String comment) {
    int percentage = (value * 100).toInt();
    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: value.clamp(0.0, 1.0),
                  strokeWidth: 12,
                  backgroundColor: Colors.purple.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.purple,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$percentage%",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Complete",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Current Assessment: $status",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Latest Mentor Evaluation Notes:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sessionList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    final upcoming = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('status') &&
          (data['status'] == 'Accepted' || data['status'] == 'Completed') &&
          data.containsKey('sessionDateTime');
    }).toList();

    if (upcoming.isEmpty) return const Text("No upcoming sessions.");

    return Column(
      children: upcoming.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'Accepted';
        String meetingType = data['meetingType'] ?? "Physical";
        String meetingLink = data['meetingLink'] ?? "";
        bool isOnline = meetingType.trim().toLowerCase() == "online";
        bool isCompleted = status == 'Completed';

        DateTime date = (data['sessionDateTime'] as Timestamp).toDate();
        String formattedDate = DateFormat('MMM dd, h:mm a').format(date);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Icon(
              isCompleted
                  ? Icons.check_circle
                  : (isOnline
                        ? Icons.video_camera_front
                        : Icons.calendar_today),
              color: isCompleted ? Colors.green : Colors.purple,
            ),
            title: Text(
              "$formattedDate with ${data['mentorName'] ?? 'Mentor'}",
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: $status (${meetingType.toUpperCase()})",
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                if (isOnline && !isCompleted && meetingLink.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Link Available! Tap to view details to join.",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: isOnline && !isCompleted && meetingLink.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.videocam, color: Colors.blue),
                    tooltip: 'Join Meeting Link',
                    onPressed: () => _launchMeetingURL(context, meetingLink),
                  )
                : const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
            onTap: () =>
                _showSessionDetailsBottomSheet(context, doc.id, data, status),
          ),
        );
      }).toList(),
    );
  }

  void _showSessionDetailsBottomSheet(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
    String status,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final reviewId = "${docId}_${data['menteeId']}";
        String meetingType = data['meetingType'] ?? "Physical";
        String meetingLink = data['meetingLink'] ?? "";
        bool isOnline = meetingType.trim().toLowerCase() == "online";
        bool isCompleted = status == 'Completed';

        return Padding(
          padding: EdgeInsets.only(
            top: 24.0,
            left: 24.0,
            right: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Session Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(status),
                      backgroundColor: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isCompleted ? Colors.green : Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 25),
                Text(
                  "Mentor: ${data['mentorName'] ?? 'N/A'}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Subject Topic: ${data['subject'] ?? 'General Module'}",
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "Learning Format: ${meetingType.toUpperCase()}",
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),

                if (isOnline && !isCompleted) ...[
                  const Divider(height: 25),
                  const Text(
                    "Meeting Endpoint:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (meetingLink.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.videocam),
                        label: const Text(
                          "Join Call / Meeting Session",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            _launchMeetingURL(context, meetingLink),
                      ),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.link_off, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text(
                          "Meeting link hasn't been set by your mentor yet.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                ],

                const Divider(height: 30),

                if (isCompleted) ...[
                  SessionReviewWidget(
                    reviewId: reviewId,
                    docId: docId,
                    bookingData: data,
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline
                            ? "Live session active. Join when ready!"
                            : "Awaiting execution and mentor sign-off.",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Transaction history
  Widget _transactionList(List<QueryDocumentSnapshot> docs) {
    final paid = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data.containsKey('isPaid') && data['isPaid'] == true;
    }).toList();

    if (paid.isEmpty) return const Text("No transactions found.");

    return Column(
      children: paid.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        DateTime date = data.containsKey('createdAt')
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now();
        String formattedDate = DateFormat('MMM dd, yyyy').format(date);
        return Column(
          children: [
            _transactionItem(
              data['mentorName'] ?? "Mentor",
              data['amount'] ?? "RM 0",
              formattedDate,
            ),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _transactionItem(String mentor, String amount, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Session with $mentor",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                date,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionReviewWidget extends StatefulWidget {
  final String reviewId;
  final String docId;
  final Map<String, dynamic> bookingData;

  const SessionReviewWidget({
    super.key,
    required this.reviewId,
    required this.docId,
    required this.bookingData,
  });

  @override
  State<SessionReviewWidget> createState() => _SessionReviewWidgetState();
}

class _SessionReviewWidgetState extends State<SessionReviewWidget> {
  int _currentRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = true;
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _fetchExistingReviewData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _fetchExistingReviewData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .doc(widget.reviewId)
          .get();
      if (snapshot.exists && mounted) {
        var reviewData = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _currentRating = reviewData['rating'] ?? 0;
          _reviewController.text = reviewData['reviewText'] ?? "";
          _hasExistingReview = true;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: CircularProgressIndicator(color: Colors.purple),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Rate & Review Your Mentor",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                index < _currentRating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 36,
              ),
              onPressed: () => setState(() => _currentRating = index + 1),
            );
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _reviewController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                "Write your session review evaluation text details here...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.purple, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  if (_currentRating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please choose a star rating status level.",
                        ),
                      ),
                    );
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection('reviews')
                      .doc(widget.reviewId)
                      .set({
                        'reviewId': widget.reviewId,
                        'bookingId': widget.docId,
                        'menteeId': widget.bookingData['menteeId'],
                        'menteeName':
                            widget.bookingData['menteeName'] ??
                            'Anonymous Student',
                        'mentorId': widget.bookingData['mentorId'],
                        'rating': _currentRating,
                        'reviewText': _reviewController.text.trim(),
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Review submitted successfully!"),
                      ),
                    );
                  }
                },
                child: Text(
                  _hasExistingReview ? "Update Review" : "Submit Review",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            if (_hasExistingReview) ...[
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 28,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('reviews')
                      .doc(widget.reviewId)
                      .delete();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Review deleted completely."),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
