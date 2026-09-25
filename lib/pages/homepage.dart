import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimentor/pages/forum_page.dart';
import 'package:unimentor/pages/login_page.dart';
import 'package:unimentor/pages/mentor_profile_page.dart';
import 'package:unimentor/pages/search_result_page.dart';
import 'package:unimentor/pages/mentee_materials_page.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'chat_room_page.dart';

// Mentee - Homepage
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Widget _getSelectedPage() {
    switch (_currentIndex) {
      case 0:
        return const MenteeHomeContent();
      case 1:
        return const ForumPage();
      case 2:
        return const MessagesListContent();
      case 3:
        return const MenteeMaterialsPage();
      default:
        return const MenteeHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "UNIMENTOR",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              } else if (value == 'dashboard') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
              } else if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            },
            icon: const Icon(Icons.account_circle, size: 32),
            itemBuilder: (context) => [
              _menuItem('profile', Icons.person_outline, "Manage Profile"),
              _menuItem('dashboard', Icons.dashboard_customize, "Dashboard"),
              _menuItem('logout', Icons.logout, "Logout", isDelete: true),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _getSelectedPage(),
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
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.forum_outlined),
                label: "Open Forum",
              ),
              BottomNavigationBarItem(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text(unreadCount.toString()),
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.message),
                      )
                    : const Icon(Icons.message),
                label: "Messages",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                label: "Materials",
              ),
            ],
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
    String value,
    IconData icon,
    String text, {
    bool isDelete = false,
  }) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isDelete ? Colors.red : Colors.purple),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }
}

class MessagesListContent extends StatelessWidget {
  const MessagesListContent({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text("Please Login"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: currentUser.uid)
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Error: ${snapshot.error.toString()}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No messages yet. Start a chat from a mentor's profile!",
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var chatRoom = snapshot.data!.docs[index];
            var chatData = chatRoom.data() as Map<String, dynamic>;

            bool isUserMentee = currentUser.uid == chatData['menteeId'];
            String otherUserName = isUserMentee
                ? (chatData['mentorName'] ?? "Mentor")
                : (chatData['menteeName'] ?? "Student");

            List unreadList = chatData['unreadBy'] ?? [];
            bool isUnread = unreadList.contains(currentUser.uid);

            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                otherUserName,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                chatData['lastMessage'] != ""
                    ? chatData['lastMessage']
                    : "New Conversation",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnread ? Colors.black87 : Colors.grey,
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
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
                    .doc(chatRoom.id)
                    .update({
                      'unreadBy': FieldValue.arrayRemove([currentUser.uid]),
                    });

                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        mentorId: chatData['mentorId'] ?? "",
                        mentorName: chatData['mentorName'] ?? "Mentor",
                        menteeId: chatData['menteeId'] ?? "",
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

class MenteeHomeContent extends StatefulWidget {
  const MenteeHomeContent({super.key});

  @override
  State<MenteeHomeContent> createState() => _MenteeHomeContentState();
}

class _MenteeHomeContentState extends State<MenteeHomeContent> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _userInterests = [];
  bool _loadingInterests = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInterests();
  }

  // Recommended mentors based on mentee's interest
  void _fetchUserInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userInterests = data['interests'] ?? [];
            _loadingInterests = false;
          });
        }
      } catch (e) {
        setState(() => _loadingInterests = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _searchBar(),
          const SizedBox(height: 25),
          const Text(
            "Recommended Mentors",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Based on your interests",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: _loadingInterests
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'Mentor')
                        .where('status', isEqualTo: 'Approved')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError)
                        return const Center(
                          child: Text("Error loading mentors"),
                        );
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());

                      var mentors = snapshot.data!.docs.where((doc) {
                        var mentorData = doc.data() as Map<String, dynamic>;
                        return _userInterests.contains(
                          mentorData['subject'] ?? "",
                        );
                      }).toList();

                      if (mentors.isEmpty) return _emptyState();

                      return ListView.builder(
                        itemCount: mentors.length,
                        itemBuilder: (context, index) {
                          var mentorDoc = mentors[index];
                          var data = mentorDoc.data() as Map<String, dynamic>;
                          Map<String, dynamic> mentorDataWithId = {
                            ...data,
                            'uid': mentorDoc.id,
                          };

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MentorProfilePage(
                                    mentorData: mentorDataWithId,
                                  ),
                                ),
                              );
                            },
                            child: _mentorCard(data, mentorDoc.id),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Search function
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) {
          if (val.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => SearchResultPage(query: val, filterType: 'All'),
              ),
            );
          }
        },
        decoration: const InputDecoration(
          hintText: "Search mentors or interests ...",
          prefixIcon: Icon(Icons.search, color: Colors.purple),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _mentorCard(Map<String, dynamic> data, String mentorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(mentorId)
          .snapshots(),
      builder: (context, userSnapshot) {
        bool isAvailable = true;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          var d = userSnapshot.data!.data() as Map<String, dynamic>;
          isAvailable = d['isAvailable'] ?? true;
        }

        return Card(
          elevation: 0,
          color: Colors.purple.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Stack(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              data['username'] ?? "Unknown",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${data['subject'] ?? 'General'} • ${isAvailable ? 'Online' : 'Offline'}",
              style: TextStyle(
                color: isAvailable ? Colors.purple : Colors.grey,
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.purple,
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          const Text("No mentors found matching your interests."),
        ],
      ),
    );
  }
}
