import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _verificationId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Sign Up',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _phoneNumberController,
                  label: 'Phone Number',
                  icon: Icons.phone,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  isPassword: true,
                  icon: Icons.lock,
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  isPassword: true,
                  icon: Icons.lock,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: const EdgeInsets.all(15.0),
                  ),
                  child: const Text('Sign Up',
                  style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/signin'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.green, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        contentPadding: const EdgeInsets.all(10.0),
      ),
    );
  }

Future<void> _signUp() async {
  try {
    if (_passwordController.text != _confirmPasswordController.text) {
      throw FirebaseAuthException(
        code: 'password-mismatch',
        message: 'Passwords do not match.',
      );
    }

    // Initiate phone number verification
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91${_phoneNumberController.text}',
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);

        // Save user details to the database
        await _saveUserDetailsToDatabase();

        // Navigate to the home page
        Navigator.pushReplacementNamed(context, '/home');
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Phone number verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
        });

        // Navigate to the OTP verification page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              verificationId: _verificationId,
              onVerificationSuccess: () async {
                // Save user details to the database
                await _saveUserDetailsToDatabase();

                // Navigate to the home page
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle auto-retrieval timeout
      },
    );
  } on FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sign up failed: ${e.message}')),
    );
  }
}

Future<void> _saveUserDetailsToDatabase() async {
  try {
    final User? user = _auth.currentUser;
    if (user != null) {
      // Access Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Check if 'users' collection exists, create if not
      final CollectionReference usersCollection = firestore.collection('users');

      // Save user details to Firestore
      await usersCollection.doc(user.uid).set({
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      });

      print('User details saved to database');
    }
  } catch (e) {
    print('Error saving user details to database: $e');
  }
}
}

class OtpVerificationPage extends StatefulWidget {
  final String verificationId;
  final VoidCallback onVerificationSuccess;

  const OtpVerificationPage({
    super.key,
    required this.verificationId,
    required this.onVerificationSuccess,
  });

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _verifyOtp() async {
  try {
    final AuthCredential credential = PhoneAuthProvider.credential(
      verificationId: widget.verificationId,
      smsCode: _otpController.text,
    );

    // Check if the widget is still mounted before updating the state
    if (mounted) {
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Call the callback for successful verification if the widget is still mounted
      if (mounted) {
        widget.onVerificationSuccess();
      }
    }
  } on FirebaseAuthException catch (e) {
    // Check if the widget is still mounted before updating the state
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: ${e.message}')),
      );
    }
  }
}
}

void main() {
  runApp(
    MaterialApp(
      home: const SignUpPage(),
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
    ),
  );
}
