import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final TextEditingController _flatRateController = TextEditingController();
  final TextEditingController _onlineRateController = TextEditingController();
  final TextEditingController _physicalRateController = TextEditingController();

  String _selectedRateType = 'flat';
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _flatRateController.dispose();
    _onlineRateController.dispose();
    _physicalRateController.dispose();
    super.dispose();
  }

  void _showEditProfileDialog(Map<String, dynamic> userData) {
    _nameController.text = userData['fullName'] ?? "";
    _phoneController.text = userData['phone'] ?? "";
    _bioController.text = userData['bio'] ?? "";

    _selectedRateType = userData['RateType'] ?? userData['rateType'] ?? 'flat';
    _flatRateController.text = (userData['Rate'] ?? '50.00')
        .toString()
        .replaceAll("RM ", "");
    _onlineRateController.text = (userData['OnlineRate'] ?? '40.00').toString();
    _physicalRateController.text = (userData['PhysicalRate'] ?? '60.00')
        .toString();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          bool isMentor = userData['role'] == "Mentor";

          return AlertDialog(
            title: const Text("Edit Profile Details"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Full Name",
                        hintText: "Enter your legal name",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Phone Number",
                        hintText: "+60123456789",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Bio / About Me",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    if (isMentor) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      const Text(
                        "Manage Session Rates",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Flat Rate")),
                              selected: _selectedRateType == 'flat',
                              selectedColor: Colors.purple.withOpacity(0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(
                                    () => _selectedRateType = 'flat',
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text("Split Mode")),
                              selected: _selectedRateType == 'split',
                              selectedColor: Colors.purple.withOpacity(0.2),
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(
                                    () => _selectedRateType = 'split',
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedRateType == 'flat') ...[
                        TextFormField(
                          controller: _flatRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Standard Session Rate",
                            prefixText: "RM ",
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? "Required"
                              : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _onlineRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Online Session Rate",
                            prefixText: "RM ",
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? "Required"
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _physicalRateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: "Physical Meetup Rate",
                            prefixText: "RM ",
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty)
                              ? "Required"
                              : null,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (isMentor && !_formKey.currentState!.validate()) return;

                  Map<String, dynamic> updateData = {
                    'fullName': _nameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'bio': _bioController.text.trim(),
                  };

                  if (isMentor) {
                    double flatVal =
                        double.tryParse(_flatRateController.text.trim()) ??
                        50.0;
                    double onlineVal =
                        double.tryParse(_onlineRateController.text.trim()) ??
                        40.0;
                    double physicalVal =
                        double.tryParse(_physicalRateController.text.trim()) ??
                        60.0;

                    updateData['RateType'] = _selectedRateType;
                    updateData['Rate'] = flatVal.toStringAsFixed(2);
                    updateData['OnlineRate'] = onlineVal.toStringAsFixed(2);
                    updateData['PhysicalRate'] = physicalVal.toStringAsFixed(2);
                  }

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user!.uid)
                      .update(updateData);

                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "MANAGE PROFILE",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User data not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String role = userData['role'] ?? "Mentee";
          bool isMentor = role == "Mentor";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.person, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  userData['username'] ?? "N/A",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "UniKL MIIT $role",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                _profileInfoTile(
                  "Email",
                  userData['email'] ?? "N/A",
                  Icons.email,
                ),
                _profileInfoTile(
                  "Course",
                  userData['course'] ?? "Not Specified",
                  Icons.school,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Private Information",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _profileInfoTile(
                  "Full Name",
                  userData['fullName'] ?? "Not set",
                  Icons.badge,
                ),
                _profileInfoTile(
                  "Phone",
                  userData['phone'] ?? "Not set",
                  Icons.phone,
                ),

                if (isMentor) ...[
                  const SizedBox(height: 15),
                  _buildPricingDisplayTile(userData),
                ],

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "About Me",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditProfileDialog(userData),
                      icon: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userData['bio'] ?? "No bio added yet.",
                    style: const TextStyle(height: 1.5),
                  ),
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(userData),
                  icon: const Icon(Icons.settings),
                  label: const Text("Edit All Details"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text("Sign Out"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildPricingDisplayTile(Map<String, dynamic> data) {
    String type = data['RateType'] ?? 'flat';
    String flatPrice = data['Rate'] ?? '50.00';
    String onlinePrice = data['OnlineRate'] ?? '40.00';
    String physicalPrice = data['PhysicalRate'] ?? '60.00';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                "Active Rates (${type == 'flat' ? 'Flat Strategy' : 'Split Learning Mode'})",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (type == 'flat')
            Text(
              "Standard Session: RM $flatPrice",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          else ...[
            Text(
              "Online Session: RM $onlinePrice",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              "Physical Session: RM $physicalPrice",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
