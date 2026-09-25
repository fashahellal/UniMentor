import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Mentor - Materials page
class MentorMaterialsPage extends StatefulWidget {
  const MentorMaterialsPage({super.key});

  @override
  State<MentorMaterialsPage> createState() => _MentorMaterialsPageState();
}

class _MentorMaterialsPageState extends State<MentorMaterialsPage> {
  Future<void> _launchURL(BuildContext context, String urlString) async {
    String formattedUrl = urlString.trim();
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
          content: Text("Cannot open link: Invalid or broken URL format"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () => _showAddMaterialDialog(context, uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('materials')
            .where('mentorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No materials uploaded yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              String title = data['title'] ?? "Untitled";
              String description = data['description'] ?? "";
              String materialUrl = data['materialUrl'] ?? "";
              bool hasLink = materialUrl.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade100),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: Icon(
                      hasLink ? Icons.link : Icons.description_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasLink ? Colors.purple : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text("Test Link"),
                    onPressed: !hasLink
                        ? null
                        : () => _launchURL(context, materialUrl),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddMaterialDialog(BuildContext context, String uid) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Upload Material Link",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                onChanged: (text) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: "Title",
                  hintText: "E.g. Week 3 Slides",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                onChanged: (text) => setDialogState(() {}),
                decoration: const InputDecoration(
                  labelText: "Description",
                  hintText: "Brief summary of material",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                onChanged: (text) => setDialogState(() {}),
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: "Material Link (URL)",
                  hintText: "E.g. google drive link",
                  prefixIcon: Icon(Icons.link, color: Colors.purple, size: 20),
                ),
              ),
              if (isSaving) ...[
                const SizedBox(height: 20),
                const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(width: 15),
                    Text(
                      "Saving material details...",
                      style: TextStyle(fontSize: 13, color: Colors.purple),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
                  (isSaving ||
                      titleController.text.trim().isEmpty ||
                      urlController.text.trim().isEmpty)
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        DocumentSnapshot mentorDoc = await FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(uid)
                            .get();
                        String mentorName = "Unknown Mentor";
                        if (mentorDoc.exists && mentorDoc.data() != null) {
                          var mentorData =
                              mentorDoc.data() as Map<String, dynamic>;
                          mentorName =
                              mentorData['username'] ?? "Unknown Mentor";
                        }

                        QuerySnapshot acceptedBookings = await FirebaseFirestore
                            .instance
                            .collection('bookings')
                            .where('mentorId', isEqualTo: uid)
                            .where('status', isEqualTo: 'Accepted')
                            .get();

                        List<String> accessibleStudents = acceptedBookings.docs
                            .map(
                              (doc) =>
                                  (doc.data()
                                          as Map<String, dynamic>)['menteeId']
                                      ?.toString() ??
                                  "",
                            )
                            .where((id) => id.isNotEmpty)
                            .toList();

                        await FirebaseFirestore.instance
                            .collection('materials')
                            .add({
                              'mentorId': uid,
                              'mentorName': mentorName,
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'materialUrl': urlController.text.trim(),
                              'studentAccessList': accessibleStudents,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Failed to save: ${e.toString()}"),
                            ),
                          );
                        }
                      }
                    },
              child: const Text(
                "Upload",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
