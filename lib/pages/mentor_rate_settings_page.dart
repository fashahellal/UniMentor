import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mentor - Rate setting
class MentorRateSettingsPage extends StatefulWidget {
  const MentorRateSettingsPage({super.key});

  @override
  State<MentorRateSettingsPage> createState() => _MentorRateSettingsPageState();
}

class _MentorRateSettingsPageState extends State<MentorRateSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  String _rateType = 'flat';
  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _flatRateController = TextEditingController();
  final TextEditingController _onlineRateController = TextEditingController();
  final TextEditingController _physicalRateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentRates();
  }

  @override
  void dispose() {
    _flatRateController.dispose();
    _onlineRateController.dispose();
    _physicalRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentRates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot mentorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mentorDoc.exists && mentorDoc.data() != null) {
        final data = mentorDoc.data() as Map<String, dynamic>;
        setState(() {
          _rateType = data['RateType'] ?? data['rateType'] ?? 'flat';
          _flatRateController.text = (data['Rate'] ?? data['rate'] ?? "50.00")
              .toString()
              .replaceAll("RM ", "");
          _onlineRateController.text =
              (data['OnlineRate'] ?? data['onlineRate'] ?? "40.00").toString();
          _physicalRateController.text =
              (data['PhysicalRate'] ?? data['physicalRate'] ?? "60.00")
                  .toString();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading rates: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRates() async {
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
              'RateType': _rateType,
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
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save rates: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Manage Session Rates",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choose Pricing Strategy",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select how you want to charge mentees for your academic sessions.",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        "Flat Rate Per Session",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        "Same fixed price regardless of whether it's online or physical.",
                      ),
                      activeColor: Colors.purple,
                      value: 'flat',
                      groupValue: _rateType,
                      onChanged: (val) => setState(() => _rateType = val!),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: const Text(
                        "Split Rate by Learning Mode",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: const Text(
                        "Charge different prices for virtual calls vs in-person interactions.",
                      ),
                      activeColor: Colors.purple,
                      value: 'split',
                      groupValue: _rateType,
                      onChanged: (val) => setState(() => _rateType = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Rate Configuration (RM)",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const Divider(height: 20),
              if (_rateType == 'flat') ...[
                _buildCurrencyField(
                  controller: _flatRateController,
                  label: "Standard Session Rate",
                  hint: "50.00",
                  icon: Icons.payments_outlined,
                ),
              ] else ...[
                _buildCurrencyField(
                  controller: _onlineRateController,
                  label: "Online Session Rate",
                  hint: "40.00",
                  icon: Icons.video_camera_front_outlined,
                ),
                const SizedBox(height: 16),
                _buildCurrencyField(
                  controller: _physicalRateController,
                  label: "Physical Meetup Rate",
                  hint: "60.00",
                  icon: Icons.location_on_outlined,
                ),
              ],
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRates,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save Settings",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: "RM ",
        prefixStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: Colors.purple),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return "Please enter an amount";
        if (double.tryParse(value.trim()) == null)
          return "Please enter a valid number";
        return null;
      },
    );
  }
}
