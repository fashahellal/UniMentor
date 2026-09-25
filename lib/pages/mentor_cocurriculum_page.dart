import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Mentor - Cocurriculum page
class MentorCocurriculumPage extends StatefulWidget {
  const MentorCocurriculumPage({super.key});

  @override
  State<MentorCocurriculumPage> createState() => _MentorCocurriculumPageState();
}

class _MentorCocurriculumPageState extends State<MentorCocurriculumPage> {
  final String currentMentorId = FirebaseAuth.instance.currentUser?.uid ?? "";
  String _mentorName = "Mentor";

  @override
  void initState() {
    super.initState();
    _fetchMentorProfile();
  }

  void _fetchMentorProfile() async {
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentMentorId)
        .get();
    if (userDoc.exists && mounted) {
      setState(() {
        _mentorName = userDoc.data()?['username'] ?? "Mentor";
      });
    }
  }

  // Print certificate
  Future<void> _generateAndPrintCertificate(
    int totalSessions,
    int totalPoints,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#9C27B0'),
                width: 8,
              ),
            ),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#E0E0E0'),
                  width: 2,
                ),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    "UNIMENTOR",
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#9C27B0'),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "CERTIFICATE OF APPRECIATION",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    "This certificate is proudly awarded to:",
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    _mentorName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 50),
                    child: pw.Text(
                      "In recognition of outstanding dedication and exceptional service as an academic peer mentor. "
                      "By successfully conducting a total of $totalSessions sessions of guiding mentees, validating $totalPoints Co-Curricular Excellence points.",
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 13),
                    ),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            height: 1,
                            color: PdfColors.grey,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            "UniMentor Platform Team",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Container(
                            width: 120,
                            height: 1,
                            color: PdfColors.grey,
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            "Integrated Co-Curricular Center",
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Co-Curricular Performance",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('mentorId', isEqualTo: currentMentorId)
            .where('status', isEqualTo: 'Completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          int completedSessions = snapshot.hasData
              ? snapshot.data!.docs.length
              : 0;
          int totalCoCurricularPoints = completedSessions * 10;

          double progressPercent = (totalCoCurricularPoints / 200).clamp(
            0.0,
            1.0,
          );
          bool isEligibleForCertificate = totalCoCurricularPoints >= 30;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Integrated Reward Framework",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Your active mentoring sessions are recorded and directly synced with the Integrated Co-Curricular System to grant extra performance marks.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: "Mentoring Sessions",
                        value: "$completedSessions sessions",
                        icon: Icons.history_edu,
                        color: Colors.blue.withOpacity(0.05),
                        iconColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _metricCard(
                        title: "Extra Marks Earned",
                        value: "+$totalCoCurricularPoints pts",
                        icon: Icons.stars,
                        color: Colors.amber.withOpacity(0.08),
                        iconColor: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Milestone Tier Progress",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${(progressPercent * 100).toInt()}% toward limit",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          color: Colors.purple,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 15),
                        _milestoneIndicatorItem(
                          title: "Bronze Tier (+10 Extra Marks - 1 Session)",
                          achieved:
                              totalCoCurricularPoints >=
                              10, // Completed 1 session achieved 1 certificate
                        ),
                        _milestoneIndicatorItem(
                          title:
                              "Silver Tier (Certificate Unlock - 3 Sessions / 30 pts)",
                          achieved:
                              totalCoCurricularPoints >=
                              30, // Completed 3 session achieved second certificate
                        ),
                        _milestoneIndicatorItem(
                          title:
                              "Gold Tier Maximum Allowance (20 Sessions / 200 pts)",
                          achieved:
                              totalCoCurricularPoints >=
                              200, // Completed 20 session achieved third certificate
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEligibleForCertificate
                              ? Colors.purple
                              : Colors.grey.shade300,
                          foregroundColor: isEligibleForCertificate
                              ? Colors.white
                              : Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.workspace_premium),
                        label: const Text(
                          "Download Latest Certificate",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: isEligibleForCertificate
                            ? () => _generateAndPrintCertificate(
                                completedSessions,
                                totalCoCurricularPoints,
                              )
                            : null,
                      ),
                      const SizedBox(height: 10),
                      if (!isEligibleForCertificate)
                        Text(
                          "Locked: Help students across 3 sessions (30 pts) to unlock your certificate.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.redAccent.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Certificate Milestone History",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _historyCertificateRow(
                        tierName: "Bronze Tier Certificate",
                        requirementText: "Achieved at 1 completed session",
                        isUnlocked: completedSessions >= 1,
                        onDownload: () => _generateAndPrintCertificate(1, 10),
                      ),
                      const Divider(height: 1),
                      _historyCertificateRow(
                        tierName: "Silver Tier Certificate",
                        requirementText: "Achieved at 3 completed sessions",
                        isUnlocked: completedSessions >= 3,
                        onDownload: () => _generateAndPrintCertificate(3, 30),
                      ),
                      const Divider(height: 1),
                      _historyCertificateRow(
                        tierName: "Gold Tier Certificate",
                        requirementText: "Achieved at 20 completed sessions",
                        isUnlocked: completedSessions >= 20,
                        onDownload: () => _generateAndPrintCertificate(20, 200),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.1),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneIndicatorItem({
    required String title,
    required bool achieved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.radio_button_unchecked,
            color: achieved ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: achieved ? Colors.black : Colors.grey,
                fontWeight: achieved ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Certificate history
  Widget _historyCertificateRow({
    required String tierName,
    required String requirementText,
    required bool isUnlocked,
    required VoidCallback onDownload,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUnlocked
            ? Colors.purple.withOpacity(0.1)
            : Colors.grey.shade100,
        child: Icon(
          isUnlocked ? Icons.workspace_premium : Icons.lock_outline,
          color: isUnlocked ? Colors.purple : Colors.grey,
        ),
      ),
      title: Text(
        tierName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: isUnlocked ? Colors.black : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        requirementText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Container(
        constraints: const BoxConstraints(maxWidth: 80),
        child: isUnlocked
            ? IconButton(
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: Colors.purple,
                ),
                onPressed: onDownload,
              )
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Locked",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }
}
