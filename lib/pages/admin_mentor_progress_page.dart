import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Admin Page - Mentor Progress
class AdminMentorProgressPage extends StatelessWidget {
  const AdminMentorProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "MENTOR TRACKERS OVERVIEW",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('cocurriculum_progress')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No active mentor checklist logs found.",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          final progressDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: progressDocs.length,
            itemBuilder: (context, index) {
              var data = progressDocs[index].data() as Map<String, dynamic>;

              String mentorName = data['mentorName'] ?? "Assigned Mentor";
              String menteeName =
                  data['studentName'] ?? data['menteeName'] ?? "Student";

              // Safely handle potentially null or missing list structures
              List<dynamic> milestones = data['milestonesList'] is List
                  ? data['milestonesList']
                  : [];
              List<dynamic> checkedStates = data['milestonesChecked'] is List
                  ? data['milestonesChecked']
                  : [];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ExpansionTile(
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(
                      Icons.assignment_ind_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    "Mentor: $mentorName",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Tracking Student: $menteeName",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  children: [
                    const Divider(height: 1),
                    if (milestones.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "This tracker contains no customized checklist targets yet.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: milestones.length,
                        itemBuilder: (ctx, idx) {
                          bool isChecked = false;
                          if (idx < checkedStates.length) {
                            isChecked = checkedStates[idx] == true;
                          }

                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 2,
                            ),
                            leading: Icon(
                              isChecked
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: isChecked ? Colors.green : Colors.grey,
                            ),
                            title: Text(
                              milestones[idx].toString(),
                              style: TextStyle(
                                decoration: isChecked
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isChecked ? Colors.grey : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
