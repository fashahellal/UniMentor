import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room_page.dart';
import 'booking_page.dart';

// Mentor - Profile page
class MentorProfilePage extends StatefulWidget {
  final Map<String, dynamic> mentorData;
  const MentorProfilePage({super.key, required this.mentorData});

  @override
  State<MentorProfilePage> createState() => _MentorProfilePageState();
}

// Update rate price
class _MentorProfilePageState extends State<MentorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late TextEditingController _flatRateController;
  late TextEditingController _onlineRateController;
  late TextEditingController _physicalRateController;

  @override
  void initState() {
    super.initState();
    _flatRateController = TextEditingController();
    _onlineRateController = TextEditingController();
    _physicalRateController = TextEditingController();
  }

  @override
  void dispose() {
    _flatRateController.dispose();
    _onlineRateController.dispose();
    _physicalRateController.dispose();
    super.dispose();
  }

  Future<void> _updateInlineRates(String currentRateType) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        double flatVal =
            double.tryParse(_flatRateController.text.trim()) ?? 50.0;
        double onlineVal =
            double.tryParse(_onlineRateController.text.trim()) ?? 40.0;
        double physicalVal =
            double.tryParse(_physicalRateController.text.trim()) ?? 60.0;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'RateType': currentRateType,
              'Rate': flatVal.toStringAsFixed(2),
              'OnlineRate': onlineVal.toStringAsFixed(2),
              'PhysicalRate': physicalVal.toStringAsFixed(2),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Session rates updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update rates: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changeRateType(String newType) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'RateType': newType});
      }
    } catch (e) {
      debugPrint("Error changing pricing mode: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String mentorId =
        (widget.mentorData['uid'] != null &&
            widget.mentorData['uid'].toString().isNotEmpty)
        ? widget.mentorData['uid']
        : (currentUser?.uid ?? "");
    final bool isOwnProfile =
        currentUser != null && currentUser.uid == mentorId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Details"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(mentorId)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.purple),
            );
          }

          Map<String, dynamic> activeData = widget.mentorData;
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            activeData = userSnapshot.data!.data() as Map<String, dynamic>;
          }

          final String rateType =
              activeData['RateType'] ?? activeData['rateType'] ?? 'flat';
          final String flatRate =
              (activeData['Rate'] ?? activeData['rate'] ?? "50.00")
                  .toString()
                  .replaceAll("RM ", "");
          final String onlineRate =
              (activeData['OnlineRate'] ?? activeData['onlineRate'] ?? "40.00")
                  .toString();
          final String physicalRate =
              (activeData['PhysicalRate'] ??
                      activeData['physicalRate'] ??
                      "60.00")
                  .toString();

          if (isOwnProfile) {
            if (_flatRateController.text != flatRate && !_isSaving) {
              _flatRateController.text = flatRate;
            }
            if (_onlineRateController.text != onlineRate && !_isSaving) {
              _onlineRateController.text = onlineRate;
            }
            if (_physicalRateController.text != physicalRate && !_isSaving) {
              _physicalRateController.text = physicalRate;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('mentorId', isEqualTo: mentorId)
                .snapshots(),
            builder: (context, reviewSnapshot) {
              double averageStars = 0.0;
              List<QueryDocumentSnapshot> reviewDocs = [];

              if (reviewSnapshot.hasData &&
                  reviewSnapshot.data!.docs.isNotEmpty) {
                reviewDocs = reviewSnapshot.data!.docs;
                double totalStars = 0;
                for (var doc in reviewDocs) {
                  totalStars +=
                      ((doc.data() as Map<String, dynamic>)['rating'] ?? 0)
                          .toDouble();
                }
                averageStars = totalStars / reviewDocs.length;
              } else {
                averageStars = (activeData['rating'] ?? 0.0).toDouble();
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(activeData, averageStars, reviewDocs.length),
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "About Mentor",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activeData['bio'] ?? "Professional mentor.",
                              style: const TextStyle(
                                color: Colors.grey,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 25),

                            Text(
                              isOwnProfile
                                  ? "Manage Session Rates"
                                  : "Session Rate",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),

                            if (isOwnProfile) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(
                                        child: Text("Flat Rate"),
                                      ),
                                      selected: rateType == 'flat',
                                      selectedColor: Colors.purple.withOpacity(
                                        0.2,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) _changeRateType('flat');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ChoiceChip(
                                      label: const Center(
                                        child: Text("Split Learning Mode"),
                                      ),
                                      selected: rateType == 'split',
                                      selectedColor: Colors.purple.withOpacity(
                                        0.2,
                                      ),
                                      onSelected: (selected) {
                                        if (selected) _changeRateType('split');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              if (rateType == 'flat') ...[
                                _buildCurrencyInputField(
                                  controller: _flatRateController,
                                  label: "Standard Session Rate",
                                  icon: Icons.payments_outlined,
                                ),
                              ] else ...[
                                _buildCurrencyInputField(
                                  controller: _onlineRateController,
                                  label: "Online Session Rate",
                                  icon: Icons.video_camera_front_outlined,
                                ),
                                const SizedBox(height: 12),
                                _buildCurrencyInputField(
                                  controller: _physicalRateController,
                                  label: "Physical Meetup Rate",
                                  icon: Icons.location_on_outlined,
                                ),
                              ],
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _updateInlineRates(rateType),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.save_outlined,
                                          size: 20,
                                        ),
                                  label: const Text(
                                    "Save New Rates",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              if (rateType == 'split') ...[
                                Row(
                                  children: [
                                    _buildRateBadge(
                                      "ONLINE",
                                      "RM ${double.tryParse(onlineRate)?.toStringAsFixed(2) ?? onlineRate}",
                                      Icons.video_camera_front,
                                    ),
                                    const SizedBox(width: 16),
                                    _buildRateBadge(
                                      "PHYSICAL",
                                      "RM ${double.tryParse(physicalRate)?.toStringAsFixed(2) ?? physicalRate}",
                                      Icons.location_on,
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text(
                                  "RM ${double.tryParse(flatRate)?.toStringAsFixed(2) ?? flatRate}",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],

                            const Divider(height: 40),
                            const Text(
                              "Mentee Evaluation Reviews",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (reviewDocs.isEmpty)
                              const Text(
                                "No evaluation metrics or feedback submitted yet.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviewDocs.length,
                                itemBuilder: (context, index) {
                                  var rData =
                                      reviewDocs[index].data()
                                          as Map<String, dynamic>;
                                  int stars = rData['rating'] ?? 0;
                                  String textReview = rData['reviewText'] ?? "";
                                  String authorName =
                                      rData['menteeName'] ??
                                      "Anonymous Student";

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                authorName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                children: List.generate(5, (
                                                  sIdx,
                                                ) {
                                                  return Icon(
                                                    sIdx < stars
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 16,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          if (textReview.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              textReview,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: isOwnProfile ? null : _buildBottomButtons(context),
    );
  }

  Widget _buildCurrencyInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: "RM ",
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon, color: Colors.purple, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return "Field cannot be empty";
        if (double.tryParse(value.trim()) == null) return "Enter a valid price";
        return null;
      },
    );
  }

  Widget _buildRateBadge(String label, String cost, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.purple.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.purple),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              cost,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> activeData,
    double averageRating,
    int reviewCount,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 30, top: 10),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 65, color: Colors.purple),
          ),
          const SizedBox(height: 15),
          Text(
            activeData['username'] ?? "Mentor Name",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              activeData['subject'] ?? "Expert",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                averageRating > 0
                    ? "${averageRating.toStringAsFixed(1)} / 5.0"
                    : "0.0 / 5.0",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (reviewCount > 0)
                Text(
                  " ($reviewCount reviews)",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatRoomPage(
                      mentorId: widget.mentorData['uid'] ?? "",
                      mentorName: widget.mentorData['username'] ?? "Mentor",
                      menteeId: FirebaseAuth.instance.currentUser!.uid,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_outlined, color: Colors.purple),
              label: const Text("Live Chat"),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.purple),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BookingPage(mentorData: widget.mentorData),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Book Session",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
