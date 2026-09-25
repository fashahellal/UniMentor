import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimentor/pages/login_page.dart';
import 'package:unimentor/pages/forum_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_reports_page.dart';
import 'admin_mentor_progress_page.dart';
import 'admin_payments_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Admin - Delete User
  void _deleteUser(String userId) async {
    bool confirm = await _showConfirmDialog(
      "Delete User",
      "Are you sure? This action will permanently remove their profile.",
    );

    if (confirm) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "User profile removed. Note: Remove Auth account manually in Console if needed.",
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Admin - User approval (mentor qpplication)
  void _approveUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'status': 'Approved',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application Approved"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _rejectApplication(String userId) async {
    bool confirm = await _showConfirmDialog(
      "Reject Application",
      "This will mark the application as rejected.",
    );
    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'status': 'Rejected',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Application Rejected"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _viewDocument(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty || urlString == "N/A") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No cloud link found for this applicant."),
        ),
      );
      return;
    }

    String formattedUrl = urlString.trim();
    if (!formattedUrl.startsWith("http://") &&
        !formattedUrl.startsWith("https://")) {
      formattedUrl = "https://$formattedUrl";
    }

    final Uri url = Uri.parse(formattedUrl);

    try {
      bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        launched = await launchUrl(url, mode: LaunchMode.platformDefault);
      }

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not open the link directly. Checking alternative launcher ...",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error while opening document URL: $e");
      try {
        await launchUrl(url);
      } catch (forcedError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Error while opening the link. Copy to clipboard instead: $formattedUrl",
              ),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: "OK",
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Confirm"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "ADMIN DASHBOARD",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (c) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildQuickStats(),
            const SizedBox(height: 25),
            const Text(
              "User Management",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _actionTile(
              Icons.people_alt,
              "Registered Users",
              "View all Mentors & Mentees",
              Colors.blue,
              () => _showUserManagementSheet(),
            ),
            const SizedBox(height: 15),
            _actionTile(
              Icons.analytics_outlined,
              "Learning Progress Reports",
              "View individual mentee completions & percentages",
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AdminReportsPage()),
              ),
            ),
            const SizedBox(height: 15),
            _actionTile(
              Icons.assignment_ind_outlined,
              "Mentor Trackers Overview",
              "Check active milestone task allocations",
              Colors.orange,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => const AdminMentorProgressPage(),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _actionTile(
              Icons.receipt_long_outlined,
              "Payment History",
              "Audits processing rates & booking collections",
              Colors.green,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const AdminPaymentPage()),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Community Moderation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _actionTile(
              Icons.forum,
              "Forum Control",
              "Moderate posts and handle reports",
              Colors.purple,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ForumPage()),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Pending Applications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildPendingList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        int mentees = snapshot.data!.docs
            .where((d) => d['role'] == 'Mentee')
            .length;
        int mentors = snapshot.data!.docs
            .where((d) => d['role'] == 'Mentor')
            .length;
        return Row(
          children: [
            _statBox(
              "$mentees",
              "Total Mentees",
              Icons.face,
              () => _showUserManagementSheet(filterRole: "Mentee"),
            ),
            const SizedBox(width: 15),
            _statBox(
              "$mentors",
              "Total Mentors",
              Icons.school,
              () => _showUserManagementSheet(filterRole: "Mentor"),
            ),
          ],
        );
      },
    );
  }

  Widget _statBox(
    String value,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserManagementSheet({String? filterRole}) {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 15, 20, 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      filterRole == null
                          ? "Registered Users"
                          : "$filterRole List",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setModalState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search by name...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var filteredDocs = snapshot.data!.docs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      bool matchesRole =
                          (filterRole == null || data['role'] == filterRole);
                      bool matchesSearch = (data['username'] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery);
                      return matchesRole && matchesSearch;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(child: Text("No users found."));
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        var doc = filteredDocs[index];
                        var data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              data['username'] != null &&
                                      data['username'].toString().isNotEmpty
                                  ? data['username'][0].toUpperCase()
                                  : "U",
                            ),
                          ),
                          title: Text(
                            data['username'] ?? "Anonymous",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${data['role']} • ${data['email']}"),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteUser(doc.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text("No pending applications."),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String specialty = data['subject'] ?? "General Academic Support";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        data['username'] ?? "New Applicant",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Expertise: $specialty\nEmail: ${data['email']}",
                          style: const TextStyle(height: 1.3),
                        ),
                      ),
                      trailing: InkWell(
                        onTap: () => _viewDocument(data['documentUrl']),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.purple),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.purple.withOpacity(0.05),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new,
                                size: 16,
                                color: Colors.purple,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Open Cloud Link",
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _rejectApplication(doc.id),
                          child: const Text(
                            "Reject",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => _approveUser(doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Approve"),
                        ),
                      ],
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
