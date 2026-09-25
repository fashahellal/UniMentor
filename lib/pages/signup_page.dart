import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unimentor/pages/mentor_homepage.dart';
import 'package:unimentor/pages/preference_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Controller for URL
  final documentUrlController = TextEditingController();

  String _selectedRole = "Mentee";
  String? _selectedSubject;
  bool _isLoading = false;

  final List<String> subjects = [
    'Coding (java/python)',
    'Mobile Development',
    'Mathematics / Calculation',
    'Networking',
    'UI / UX Design',
    'Animation',
  ];

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    documentUrlController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == "Mentor") {
        if (_selectedSubject == null) {
          _showError("Please select your subject of expertise");
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        String uid = userCredential.user!.uid;

        // URL saved to document URL storage
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'role': _selectedRole,
          'subject': _selectedRole == "Mentor" ? _selectedSubject : null,
          'createdAt': DateTime.now(),
          'status': _selectedRole == "Mentor" ? "Pending" : "Approved",
          'documentName': _selectedRole == "Mentor"
              ? "Cloud Drive Link"
              : "N/A",
          'documentUrl': _selectedRole == "Mentor"
              ? documentUrlController.text.trim()
              : "",
        });

        if (!mounted) return;

        if (_selectedRole == "Mentee") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PreferencePage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MentorHomePage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        _showError(e.message ?? "Error occurred");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 80),
                const Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                _field("Username", Icons.person, usernameController),
                const SizedBox(height: 15),
                _field("Email", Icons.email, emailController, email: true),
                const SizedBox(height: 15),
                _roleDropdown(),
                if (_selectedRole == "Mentor") ...[
                  const SizedBox(height: 15),
                  _subjectDropdown(),
                  const SizedBox(height: 15),
                  _documentUrlField(),
                ],
                const SizedBox(height: 15),
                _field(
                  "Password",
                  Icons.password,
                  passwordController,
                  obscure: true,
                ),
                const SizedBox(height: 15),
                _field(
                  "Confirm Password",
                  Icons.password,
                  confirmPasswordController,
                  obscure: true,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.purple)
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.purple,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 20),
                _loginRedirect(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedRole,
      decoration: _decoration("Register as", Icons.assignment_ind),
      items: ["Mentee", "Mentor"]
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      onChanged: (value) => setState(() {
        _selectedRole = value!;
        if (_selectedRole == "Mentee") _selectedSubject = null;
      }),
    );
  }

  Widget _subjectDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSubject,
      hint: const Text("Select your Expertise"),
      decoration: _decoration("Expertise", Icons.book),
      items: subjects
          .map(
            (subject) => DropdownMenuItem(value: subject, child: Text(subject)),
          )
          .toList(),
      onChanged: (value) => setState(() => _selectedSubject = value),
    );
  }

  Widget _documentUrlField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // for mentor only
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Instruction: Please paste a cloud link (e.g., Google Drive, OneDrive, or Dropbox) containing your cumulative GPA transcripts, certificate, or any academic proof to verify you are a qualified mentor.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange[900],
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        TextFormField(
          controller: documentUrlController,
          keyboardType: TextInputType.url,
          decoration: _decoration(
            "Support Docs URL (Google Drive / Cloud)",
            Icons.link,
          ),
          validator: (value) {
            if (_selectedRole == "Mentor") {
              if (value == null || value.trim().isEmpty) {
                return "Please supply a cloud link to verification documents";
              }
              if (!value.toLowerCase().startsWith("http://") &&
                  !value.toLowerCase().startsWith("https://")) {
                return "Enter a valid URL starting with http:// or https://";
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _field(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
    bool email = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: _decoration(hint, icon),
      validator: (value) {
        if (value == null || value.isEmpty) return "$hint is required";
        if (email && !value.toLowerCase().endsWith("@s.unikl.edu.my")) {
          return "Use UniKL student email";
        }
        if (hint == "Confirm Password" && value != passwordController.text) {
          return "Passwords do not match";
        }
        if (hint == "Password" && value.length < 6) return "Min 6 characters";
        return null;
      },
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      fillColor: Colors.purple.withOpacity(0.1),
      filled: true,
      prefixIcon: Icon(icon, color: Colors.purple),
    );
  }

  Widget _loginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account?"),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Login", style: TextStyle(color: Colors.purple)),
        ),
      ],
    );
  }
}
