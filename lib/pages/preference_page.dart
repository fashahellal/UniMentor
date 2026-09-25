import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unimentor/pages/homepage.dart';

// Mentee - Preference page (Showed upon sign up)
class PreferencePage extends StatefulWidget {
  const PreferencePage({super.key});

  @override
  State<PreferencePage> createState() => _PreferencePageState();
}

class _PreferencePageState extends State<PreferencePage> {
  String? selectedCourse;
  String? selectedInterest;
  bool _isLoading = false;

  final List<String> courses = [
    'Foundation in Computer Technology',
    'Foundation in Science',
    'Diploma in Networking Technology',
    'Diploma in Information Technology',
    'Diploma in Multimedia',
    'Bachelor of Information Technology in Software Engineering',
    'Bachelor of Information Technology in Computer System Security',
    'Bachelor of Computer Engineering Technology (Computer Systems)',
    'Bachelor of Multimedia Technology in Interactive Multimedia Design',
    'Bachelor of Multimedia Technology in Computer Animation',
  ];

  final List<String> interests = [
    'Coding (java/python)',
    'Mobile Development',
    'Mathematics / Calculation',
    'Networking',
    'UI / UX Design',
    'Animation',
  ];

  // save preferences to the database
  void _savePreferences() async {
    if (selectedCourse == null || selectedInterest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both course and interest")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // update user document in firebase
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'course': selectedCourse,
              // save as lists
              'interests': [selectedInterest],
              'setupComplete': true,
            });

        if (!mounted) return;

        // navigate to mentee homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving preferences: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Preferences:")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tell us more about you:",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "This help us recommend the best mentors based on your needs.",
              ),
              const SizedBox(height: 30),
              const Text(
                "Current Course",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                menuMaxHeight: 300,
                hint: const Text("Select your Course"),
                initialValue: selectedCourse,
                items: courses.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCourse = val),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 20),
              const Text(
                "Preferred Interest",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                menuMaxHeight: 300,
                hint: const Text("What do you need help with?"),
                initialValue: selectedInterest,
                items: interests.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedInterest = val),
                decoration: _inputDecoration(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _savePreferences,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Finish Setup",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.purple.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
