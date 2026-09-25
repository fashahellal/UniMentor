import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mentor_profile_page.dart';

class SearchResultPage extends StatelessWidget {
  final String query;
  final String filterType; // 'All', 'Top Rated', 'Subject', 'Interest'

  const SearchResultPage({
    super.key,
    required this.query,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search: $query"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'Mentor')
            .where('status', isEqualTo: 'Approved')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter documents locally based on search rules and query strings
          var mentors = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String name = (data['username'] ?? "").toString().toLowerCase();
            String subject = (data['subject'] ?? "").toString().toLowerCase();
            List interests = data['interests'] ?? [];
            double rating = (data['rating'] ?? 0.0).toDouble();

            bool matchesQuery =
                name.contains(query.toLowerCase()) ||
                subject.contains(query.toLowerCase()) ||
                interests.any(
                  (i) =>
                      i.toString().toLowerCase().contains(query.toLowerCase()),
                );

            if (filterType == 'Top Rated') return matchesQuery && rating >= 4.5;
            return matchesQuery;
          }).toList();

          if (mentors.isEmpty) {
            return const Center(
              child: Text("No mentors found matching your search."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mentors.length,
            itemBuilder: (context, index) {
              var doc = mentors[index];
              var data = doc.data() as Map<String, dynamic>;

              if (!data.containsKey('uid')) {
                data['uid'] = doc.id;
              }

              return _mentorResultCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _mentorResultCard(BuildContext context, Map<String, dynamic> data) {
    final String mentorId = data['uid'] ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.purple,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          data['username'] ?? "Mentor",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(data['subject'] ?? "General mentorship"),
        trailing: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('mentorId', isEqualTo: mentorId)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            double calculatedAverage = 0.0;

            if (reviewSnapshot.hasData &&
                reviewSnapshot.data!.docs.isNotEmpty) {
              double totalStars = 0.0;
              var reviewDocs = reviewSnapshot.data!.docs;
              for (var doc in reviewDocs) {
                totalStars +=
                    ((doc.data() as Map<String, dynamic>)['rating'] ?? 0)
                        .toDouble();
              }
              calculatedAverage = totalStars / reviewDocs.length;
            } else {
              calculatedAverage = (data['rating'] ?? 0.0).toDouble();
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  calculatedAverage > 0
                      ? calculatedAverage.toStringAsFixed(1)
                      : "0.0",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MentorProfilePage(mentorData: data),
          ),
        ),
      ),
    );
  }
}
