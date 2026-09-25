import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Open forum page
class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final TextEditingController _postController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  String? userRole;
  String? username;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (mounted && doc.exists) {
      setState(() {
        userRole = doc.data()?['role'] ?? 'Mentee';
        username = doc.data()?['username'] ?? 'Anonymous';
      });
    }
  }

  void _uploadPost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user!.uid,
        'username': username ?? 'Anonymous',
        'role': userRole ?? 'Mentee',
        'content': text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      });

      _postController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shared with the UniMentor community!"),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error posting: $e");
    }
  }

  void _reportPost(String postId, String content) async {
    await FirebaseFirestore.instance.collection('reports').add({
      'postId': postId,
      'reportedContent': content,
      'reportedBy': user!.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post reported to Admin for review.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // appbar for admin only
      appBar: userRole == 'Admin'
          ? AppBar(
              title: const Text(
                "FORUM MODERATION",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          if (userRole != 'Admin')
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    maxLength: 280,
                    decoration: InputDecoration(
                      hintText:
                          "Ask a question or share a tip with everyone...",
                      helperText: "Visible to Mentees, Mentors, and Admins",
                      filled: true,
                      fillColor: Colors.purple.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(15),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _uploadPost,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text("Post to Forum"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // public forum feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading posts"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No posts yet. Be the first!"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 10, bottom: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var post = snapshot.data!.docs[index];
                    return _postTile(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _postTile(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    List likes = data['likes'] ?? [];
    bool isLiked = likes.contains(user?.uid);
    DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
    String role = data['role'] ?? 'Mentee';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: role == 'Mentor'
                          ? Colors.blue.shade100
                          : Colors.purple.shade100,
                      child: Text(
                        (data['username'] ?? 'A')[0].toUpperCase(),
                        style: TextStyle(
                          color: role == 'Mentor' ? Colors.blue : Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['username'] ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: role == 'Mentor'
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "$role • ${date != null ? DateFormat('jm').format(date) : 'Just now'}",
                            style: TextStyle(
                              fontSize: 10,
                              color: role == 'Mentor'
                                  ? Colors.blue
                                  : Colors.purple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // delete button - admin only
                if (userRole == 'Admin')
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deletePost(doc.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data['content'] ?? '',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 30),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleLike(doc.id, likes),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 5),
                      Text("${likes.length}"),
                    ],
                  ),
                ),
                const Spacer(),
                // report button hidden from admin
                if (userRole != 'Admin')
                  TextButton.icon(
                    onPressed: () => _reportPost(doc.id, data['content']),
                    icon: const Icon(
                      Icons.report_problem_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    label: const Text(
                      "Report",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(String postId, List likes) async {
    if (user == null) return;
    DocumentReference postRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId);

    if (likes.contains(user!.uid)) {
      await postRef.update({
        'likes': FieldValue.arrayRemove([user!.uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.arrayUnion([user!.uid]),
      });
    }
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text("As an admin, you are removing this content."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
