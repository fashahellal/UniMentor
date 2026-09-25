import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mentee - Chat page
class ChatRoomPage extends StatefulWidget {
  final String mentorId;
  final String mentorName;
  final String menteeId;

  const ChatRoomPage({
    super.key,
    required this.mentorId,
    required this.mentorName,
    required this.menteeId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _msgController = TextEditingController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool isMentor = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _setupChatRoom();
  }

  void _checkUserRole() {
    setState(() {
      isMentor = currentUserId == widget.mentorId;
    });
  }

  String getRoomId() {
    return (widget.menteeId.hashCode <= widget.mentorId.hashCode)
        ? "${widget.menteeId}_${widget.mentorId}"
        : "${widget.mentorId}_${widget.menteeId}";
  }

  Future<void> _setupChatRoom() async {
    final roomRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(getRoomId());

    await roomRef
        .update({
          'unreadBy': FieldValue.arrayRemove([currentUserId]),
        })
        .catchError((_) {});

    if (isMentor) return;

    final doc = await roomRef.get();
    if (!doc.exists) {
      String dynamicStudentName = "Student";

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;
          dynamicStudentName = userData['username'] ?? "Student";
        }
      } catch (e) {
        debugPrint("Error fetching dynamic mentee username: $e");
      }

      await roomRef.set({
        'mentorId': widget.mentorId,
        'mentorName': widget.mentorName,
        'menteeId': widget.menteeId,
        'menteeName': dynamicStudentName,
        'lastMessage': "",
        'lastMessageTime': FieldValue.serverTimestamp(),
        'participants': [widget.menteeId, widget.mentorId],
        'unreadBy': [],
      });
    }
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;

    String messageText = _msgController.text.trim();
    _msgController.clear();

    final roomRef = FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(getRoomId());

    await roomRef.collection('messages').add({
      'senderId': currentUserId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Unread notification
    String counterPartyId = isMentor ? widget.menteeId : widget.mentorId;

    await roomRef.update({
      'lastMessage': messageText,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadBy': FieldValue.arrayUnion([counterPartyId]),
    });
  }

  @override
  Widget build(BuildContext context) {
    String targetPartnerUid = isMentor ? widget.menteeId : widget.mentorId;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(getRoomId())
          .snapshots(),
      builder: (context, roomSnapshot) {
        String chatPartnerName = widget.mentorName;

        if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
          var data = roomSnapshot.data!.data() as Map<String, dynamic>;
          if (isMentor) {
            chatPartnerName = data['menteeName'] ?? "Student";
          } else {
            chatPartnerName = data['mentorName'] ?? "Mentor";
          }
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chatPartnerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(targetPartnerUid)
                            .snapshots(),
                        builder: (context, partnerUserSnapshot) {
                          bool availableStatus = false;
                          if (partnerUserSnapshot.hasData &&
                              partnerUserSnapshot.data!.exists) {
                            var parsedData =
                                partnerUserSnapshot.data!.data()
                                    as Map<String, dynamic>;
                            availableStatus =
                                parsedData['isAvailable'] ?? false;
                          }
                          return Text(
                            availableStatus ? "Available" : "Offline",
                            style: TextStyle(
                              fontSize: 12,
                              color: availableStatus
                                  ? Colors.greenAccent.shade400
                                  : Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chat_rooms')
                      .doc(getRoomId())
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, msgSnapshot) {
                    if (!msgSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = msgSnapshot.data!.docs;
                    return ListView.builder(
                      reverse: true,
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var msg = docs[index];
                        return _buildMessageBubble(
                          msg['text'] ?? "",
                          msg['senderId'] == currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.purple : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Type text message...",
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.purple,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
