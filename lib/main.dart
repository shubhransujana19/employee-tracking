import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track/back_services.dart';
import 'package:track/firebase_options.dart';
import 'package:track/forgot_password.dart';
import 'package:track/homePage.dart';
import 'package:track/profile_page.dart';
import 'package:track/signUp_page.dart';

// void main() async => runApp(MyApp());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.isDenied.then(
    (value) {
      if(value){
        Permission.notification.request();
      }

  });
  await initializeService();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SignInPage(),
      routes: {
        '/signup': (context) => const SignUpPage(),
        '/signin': (context) => const SignInPage(),
        '/forgotpassword': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/profile' : (context) => const ProfilePage(),
      },
    );
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      if (googleAccount != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleAccount.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _saveUserLoggedIn(true);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Handle the error (e.g., show an error message)
    }
  }

Future<void> signInWithEmailAndPassword(
  BuildContext context, String email, String password) async {
try {
    // Sign in with email and password
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Check if the user exists
    if (userCredential.user != null) {
      // User successfully signed in
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // User not found, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please check your email or sign up.')),
      );
    }
  } on FirebaseAuthException catch (e) {
    // Handle different error cases
    if (e.code == 'user-not-found') {
      // User not found, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please check your email or sign up.')),
      );
    } else if (e.code == 'wrong-password') {
      // Incorrect password, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password. Please try again.')),
      );
    } else {
      // Other errors, print to console for debugging
      print('Error signing in: ${e.message}');
    }
  }
}


  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    await _saveUserLoggedIn(false);
    Navigator.pushReplacementNamed(context, '/signin');
  }

  Future<bool> isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> _saveUserLoggedIn(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }

   void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
//  final TextEditingController _phoneNumberController = TextEditingController();
  final AuthService _authService = AuthService();

@override
  void initState() {
    super.initState();
    _checkUserLoggedIn();
  }

  Future<void> _checkUserLoggedIn() async {
    final bool isLoggedIn = await _authService.isUserLoggedIn();
    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }


  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn googleSignIn = GoogleSignIn();

  // String verificationId = '';

// Future<void> _signInWithGoogle() async {
//   try {
//     final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
//     if (googleAccount != null) {
//       final GoogleSignInAuthentication googleAuth =
//           await googleAccount.authentication;
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//       await _auth.signInWithCredential(credential);
//       // ignore: use_build_context_synchronously
//       Navigator.pushReplacementNamed(context, '/home');
//     }
//   } catch (e) {
//     print('Error signing in with Google: $e');
//     // Handle the error (e.g., show an error message)
//   }
// }


// Future<void> _signInWithEmailAndPassword() async {
//   try {
//     // Sign in with email and password
//     final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//       email: _emailController.text,
//       password: _passwordController.text,
//     );

//     // Check if the user exists
//     if (userCredential.user != null) {
//       // User successfully signed in
//       Navigator.pushReplacementNamed(context, '/home');
//     } else {
//       // User not found, show a message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User not found. Please check your email or sign up.')),
//       );
//     }
//   } on FirebaseAuthException catch (e) {
//     // Handle different error cases
//     if (e.code == 'user-not-found') {
//       // User not found, show a message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('User not found. Please check your email or sign up.')),
//       );
//     } else if (e.code == 'wrong-password') {
//       // Incorrect password, show a message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Incorrect password. Please try again.')),
//       );
//     } else {
//       // Other errors, print to console for debugging
//       print('Error signing in: ${e.message}');
//     }
//   }
// }

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
                  'Sign In',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed:()=> _authService.signInWithGoogle(context), //_signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.indigo, backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: const EdgeInsets.all(10.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_logo.png',
                        height: 30.0,
                      ),
                      const SizedBox(width: 10.0),
                      const Text('Sign in with Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgotpassword'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.indigo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                      String email = _emailController.text.trim();
                      String password = _passwordController.text.trim();

                      print("Email: $email");
                      print("Password: $password");

                      await _authService.signInWithEmailAndPassword(context, email, password);
                    },  
                    
                    style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    padding: const EdgeInsets.all(15.0),
                  ),
                  child: const Text('Sign In',
                  style: TextStyle(color: Colors.green, fontSize: 18),
                  ),
                ),
                const SizedBox(height:10),
                TextButton(onPressed: (){
                  Navigator.pushNamed(context, '/signup' );
                },
                 child: const Row(
                   children: [
                      Text(" Don't have an account? "),
                     Text("Sign Up", 
                     style: TextStyle(fontSize: 16,color: Colors.green),
                     )
                   ],
                 ),                
                )
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
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        contentPadding: const EdgeInsets.all(10.0),
      ),
    );
  }
}



