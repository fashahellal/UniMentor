import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unimentor/pages/login_page.dart';
import 'package:unimentor/pages/profile_page.dart';
import 'package:unimentor/pages/forum_page.dart';
import 'package:unimentor/pages/chat_room_page.dart';
import 'package:unimentor/pages/mentor_dashboard.dart';
import 'package:unimentor/pages/mentor_materials_page.dart';
import 'package:unimentor/pages/mentor_cocurriculum_page.dart';

// Mentor - Homepage
class MentorHomePage extends StatefulWidget {
  const MentorHomePage({super.key});

  @override
  State<MentorHomePage> createState() => _MentorHomePageState();
}

class _MentorHomePageState extends State<MentorHomePage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _pages = [
      MentorHomeContent(
        onNavigateToMaterials: () => setState(() => _currentIndex = 3),
        onNavigateToCoCurriculum: () => setState(() => _currentIndex = 4),
      ),
      const ForumPage(),
      const MentorChatListPage(),
      const MentorMaterialsPage(),
      const MentorCocurriculumPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "UNIMENTOR",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            icon: const Icon(Icons.account_circle, size: 30),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.purple),
                    SizedBox(width: 10),
                    Text("Manage Profile"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('unreadBy', arrayContains: currentUserId)
            .snapshots(),
        builder: (context, unreadSnapshot) {
          int unreadCount = unreadSnapshot.hasData
              ? unreadSnapshot.data!.docs.length
              : 0;

          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                label: 'Forum',
              ),
              BottomNavigationBarItem(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text(unreadCount.toString()),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.message_outlined),
                      )
                    : const Icon(Icons.message_outlined),
                label: 'Messages',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                label: 'Materials',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.workspace_premium),
                label: 'Co-Cu',
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class MentorChatListPage extends StatelessWidget {
  const MentorChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUserId)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text("Error: ${snapshot.error}"));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Center(child: Text("No messages yet."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var room = snapshot.data!.docs[index];
            Map<String, dynamic> data = room.data() as Map<String, dynamic>;

            String displayedStudentName = data['menteeName'] ?? "Student";
            List unreadList = data['unreadBy'] ?? [];
            bool isUnread = unreadList.contains(currentUserId);

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                displayedStudentName,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                data['lastMessage'] ?? "No messages yet",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnread ? Colors.black87 : Colors.grey,
                  fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              trailing: isUnread
                  ? const CircleAvatar(
                      radius: 5,
                      backgroundColor: Colors.purple,
                    )
                  : const Icon(Icons.chevron_right, color: Colors.purple),
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('chat_rooms')
                    .doc(room.id)
                    .update({
                      'unreadBy': FieldValue.arrayRemove([currentUserId]),
                    });

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        mentorId: data['mentorId'] ?? "",
                        mentorName: data['mentorName'] ?? "Mentor",
                        menteeId: data['menteeId'] ?? "",
                      ),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class MentorHomeContent extends StatefulWidget {
  final VoidCallback onNavigateToMaterials;
  final VoidCallback onNavigateToCoCurriculum;

  const MentorHomeContent({
    super.key,
    required this.onNavigateToMaterials,
    required this.onNavigateToCoCurriculum,
  });

  @override
  State<MentorHomeContent> createState() => _MentorHomeContentState();
}

// Upcoming session
class _MentorHomeContentState extends State<MentorHomeContent> {
  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? "";

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot launch meeting URL: Invalid schema"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _availabilityToggle(),
          const SizedBox(height: 25),
          _buildNewBookingRequests(),
          const Text(
            "Your Booking Schedule",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Manage your complete upcoming  and initialize meeting endpoints below.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          _buildTodaySchedule(),
          const SizedBox(height: 25),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _actionCard(
                "Post Materials",
                Icons.upload_file,
                onTap: widget.onNavigateToMaterials,
              ),
              const SizedBox(width: 12),
              _actionCard(
                "Dashboard",
                Icons.bar_chart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MentorDashboardPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _actionCard(
                "Co-Curriculum Center",
                Icons.stars,
                onTap: widget.onNavigateToCoCurriculum,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Session booking request
  Widget _buildNewBookingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('mentorId', isEqualTo: currentUid)
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  "New Booking Requests",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...snapshot.data!.docs
                .map((doc) => _pendingBookingCard(doc))
                .toList(),
            const SizedBox(height: 20),
            const Divider(),
          ],
        );
      },
    );
  }

  // Sessions schedule
  Widget _buildTodaySchedule() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('mentorId', isEqualTo: currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "No sessions scheduled yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final filteredDocs = snapshot.data!.docs.where((doc) {
          var d = doc.data() as Map<String, dynamic>;
          String s = d['status'] ?? '';
          return s == 'Accepted' || s == 'Completed';
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                "No active sessions scheduled yet.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: filteredDocs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String docId = doc.id;
            String studentName = data['menteeName'] ?? "Student";
            String subjectName = data['subject'] ?? "General Session";
            String currentStatus = data['status'] ?? 'Accepted';
            bool isCompleted = currentStatus == 'Completed';
            String meetingType = data['meetingType'] ?? "Physical";
            String currentMeetingLink = data['meetingLink'] ?? "";
            String timeString = "00:00";
            String dateString = "Today";

            if (data['sessionDateTime'] != null) {
              DateTime dateTime = (data['sessionDateTime'] as Timestamp)
                  .toDate();
              timeString = DateFormat('hh:mm a').format(dateTime);
              dateString = DateFormat('dd MMM yyyy').format(dateTime);
            }
            return _advancedScheduleCard(
              docId: docId,
              student: studentName,
              subject: subjectName,
              time: timeString,
              date: dateString,
              isCompleted: isCompleted,
              meetingType: meetingType,
              meetingLink: currentMeetingLink,
              bookingData: data,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _advancedScheduleCard({
    required String docId,
    required String student,
    required String subject,
    required String time,
    required String date,
    required bool isCompleted,
    required String meetingType,
    required String meetingLink,
    required Map<String, dynamic> bookingData,
  }) {
    bool isOnline = meetingType.trim().toLowerCase() == "online";
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : (isOnline ? Icons.video_camera_front : Icons.location_on),
                color: isCompleted ? Colors.green : Colors.purple,
                size: 26,
              ),
            ),
            title: Text(
              student,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                color: isCompleted ? Colors.grey : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meetingType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOnline
                          ? Colors.blue.shade700
                          : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isOnline && !isCompleted)
                  TextButton.icon(
                    icon: Icon(
                      meetingLink.isEmpty ? Icons.add_link : Icons.videocam,
                      size: 18,
                      color: Colors.blue,
                    ),
                    label: Text(
                      meetingLink.isEmpty ? "Set Meet Link" : "Join Call",
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () => _showMeetingLinkDialog(docId, meetingLink),
                  )
                else if (isOnline && isCompleted)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Session Concluded",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Physical Meetup Location",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompleted
                        ? Colors.grey.shade200
                        : Colors.green,
                    foregroundColor: isCompleted
                        ? Colors.grey.shade700
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  icon: Icon(
                    isCompleted ? Icons.restart_alt : Icons.done_all,
                    size: 16,
                  ),
                  label: Text(
                    isCompleted ? "Undo Complete" : "Mark as Done",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    String nextStatus = isCompleted ? 'Accepted' : 'Completed';

                    if (nextStatus == 'Completed') {
                      var rawAmount = bookingData['amount'] ?? "RM 50.00";
                      String cleanAmountString = rawAmount
                          .toString()
                          .replaceAll('RM', '')
                          .trim();
                      double earned =
                          double.tryParse(cleanAmountString) ?? 50.0;

                      final batch = FirebaseFirestore.instance.batch();
                      batch.update(
                        FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(docId),
                        {'status': 'Completed'},
                      );
                      batch.set(
                        FirebaseFirestore.instance
                            .collection('mentors_wallets')
                            .doc(currentUid),
                        {
                          'availableBalance': FieldValue.increment(earned),
                          'lastUpdated': FieldValue.serverTimestamp(),
                        },
                        SetOptions(merge: true),
                      );
                      await batch.commit();
                    } else {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(docId)
                          .update({'status': 'Accepted'});
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMeetingLinkDialog(String docId, String existingLink) {
    final textController = TextEditingController(text: existingLink);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Configure Online Session Link",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Provide the meeting URL (Google Meet, Zoom, Jitsi) for your mentee:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: "https://meet.google.com/abc-defg-hij",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link, color: Colors.purple),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          if (existingLink.isNotEmpty)
            TextButton(
              onPressed: () => _launchMeetingURL(context, existingLink),
              child: const Text(
                "Test Launch",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(docId)
                  .update({'meetingLink': textController.text.trim()});
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save Link"),
          ),
        ],
      ),
    );
  }

  Widget _pendingBookingCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          data['menteeName'] ?? "Student",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${data['subject'] ?? 'General'}\nRate: RM ${data['amount'] ?? data['price'] ?? '50'}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _updateBookingStatus(doc.id, 'Rejected', data),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _updateBookingStatus(doc.id, 'Accepted', data),
            ),
          ],
        ),
      ),
    );
  }

  void _updateBookingStatus(
    String docId,
    String status,
    Map<String, dynamic> bookingData,
  ) async {
    await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
      'status': status,
    });

    if (status == 'Accepted') {
      final String menteeId = bookingData['menteeId'] ?? "";
      final String subject = bookingData['subject'] ?? "Co-Curriculum Module";
      if (menteeId.isNotEmpty) {
        String dynamicStudentName = "Registered Student";
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(menteeId)
              .get();
          if (userDoc.exists && userDoc.data() != null) {
            var userData = userDoc.data() as Map<String, dynamic>;
            dynamicStudentName = userData['username'] ?? "Registered Student";
          }
        } catch (e) {
          debugPrint("Error fetching student username: $e");
        }

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .update({'menteeName': dynamicStudentName});

        QuerySnapshot existingProgress = await FirebaseFirestore.instance
            .collection('cocurriculum_progress')
            .where('mentorId', isEqualTo: currentUid)
            .where('menteeId', isEqualTo: menteeId)
            .where('activityName', isEqualTo: subject)
            .get();

        if (existingProgress.docs.isEmpty) {
          await FirebaseFirestore.instance
              .collection('cocurriculum_progress')
              .add({
                'mentorId': currentUid,
                'menteeId': menteeId,
                'studentName': dynamicStudentName,
                'activityName': subject,
                'progressPercentage': 0.0,
                'statusText': "Milestone 0/4 verified",
                'mentorComment': "No comments added yet.",
                'timestamp': FieldValue.serverTimestamp(),
              });
        }
      }
    }
  }

  // Availability toggle
  Widget _availabilityToggle() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .snapshots(),
      builder: (context, snapshot) {
        bool userAvailable = true;
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          userAvailable = data['isAvailable'] ?? true;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: userAvailable
                ? Colors.green.withOpacity(0.05)
                : Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: userAvailable
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userAvailable ? "You are Available" : "You are Offline",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: userAvailable ? Colors.green : Colors.red,
                ),
              ),
              Switch(
                value: userAvailable,
                onChanged: (val) async {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUid)
                      .update({'isAvailable': val});
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionCard(
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 130,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.purple, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
