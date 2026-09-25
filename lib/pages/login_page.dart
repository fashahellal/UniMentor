import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_page.dart';
import 'homepage.dart';
import 'mentor_homepage.dart';
import 'admin_dashboard.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  // Login logic
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // log in with firebase authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );

        // fetch user profile from firebase
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception("User profile not found in database.");
        }

        String role = userDoc['role'];

        if (!mounted) return;

        // role navigation logic
        if (role == "Admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
        } else if (role == "Mentor") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MentorHomePage()),
          );
        } else {
          // mentee role
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Login failed"),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            // used constraint instead of height size prevent overflow oh small screen
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _header(),
                  _inputFields(),
                  Column(children: [_forgotPassword(), _signUp()]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        // Unimentor Logo
        Image.asset(
          'assets/UniMentor_Logo.png',
          height: 100,
          width: 100,
          alignment: Alignment.center,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.school, size: 80, color: Colors.purple);
          },
        ),
        const SizedBox(height: 15),
        const Text(
          "UNIMENTOR",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 10),
        const Text("Enter your credentials to log in"),
      ],
    );
  }

  Widget _inputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration("Email", Icons.email),
          validator: (value) {
            if (value == null || value.isEmpty) return "Email is required";

            bool isAdmin = value.trim() == "admin@gmail.com";
            bool isUniKL = value.toLowerCase().endsWith("@s.unikl.edu.my");

            if (!isAdmin && !isUniKL) {
              return "Please use your UniKL students email";
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: _inputDecoration("Password", Icons.lock),
          validator: (value) {
            if (value == null || value.isEmpty) return "Password is required";
            return null;
          },
        ),
        const SizedBox(height: 25),
        _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              )
            : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Login", style: TextStyle(fontSize: 20)),
              ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
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

  Widget _forgotPassword() {
    return TextButton(
      onPressed: () {
        // navigate to forgot password page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
        );
      },
      child: const Text(
        "Forgot Password?",
        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _signUp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account?"),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignupPage()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
