import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:flutter_application_1/forgot_password_page.dart';
import 'package:flutter_application_1/main_page.dart';
import 'package:flutter_application_1/data/repositories/profile_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _companyIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');
  ProfileRepository profileRepository = ProfileRepository();

  var logger = Logger();
  Icon icon = const Icon(Icons.visibility_off);
  bool obscure = true;
  String userPosition = '';

  @override
  void initState() {
    super.initState();
    // Clear controllers when the widget is initialized
    // _companyIdController.clear();
    // _passwordController.clear();
  }

  Future<bool> signIn(String email, String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0, // Set elevation to 0 to remove the shadow
        content: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(229, 63, 248, 1)),
              ),
              SizedBox(height: 10), // Adjust the height as needed
              Text('Loading...'),
            ],
          ),
        ),
      ),
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      Navigator.of(context).pop();
      logger.i('success sign In');
      return true;
    } on FirebaseAuthException catch (e) {
      logger.i('Error: $e');
      Navigator.of(context).pop();
      return false;
    }
  }

  Future<bool> checkCredentials(String companyId, String password) async {
    try {
      final querySnapshot = await _users.get();

      for (final doc in querySnapshot.docs) {
        final userData = doc.data() as Map<String, dynamic>;

        if (userData['companyId'] == companyId &&
            await signIn(userData['email'], password) &&
            userData['status'] == true) {
          userPosition = userData['position'];
          return true; // Credentials match a user document
        }
      }

      return false; // Credentials do not match any user document
    } catch (e) {
      logger.e('Error retrieving data from Firestore: $e');
      return false; // An error occurred
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false,
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromRGBO(229, 63, 248, 1)),
                  ),
                  SizedBox(height: 10), // Adjust the height as needed
                  Text('Loading...'),
                ],
              ),
            );
          } else {
            final bool isUserSignedIn = snapshot.hasData;

            if (isUserSignedIn) {
              final user = snapshot.data;
              final email = user?.email;

              return FutureBuilder<Map<String, dynamic>?>(
                future: fetchData(email),
                builder: (context, dataSnapshot) {
                  if (dataSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(229, 63, 248, 1)),
                          ),
                          SizedBox(height: 10), // Adjust the height as needed
                          Text('Loading...'),
                        ],
                      ),
                    );
                  } else {
                    if (dataSnapshot.hasData &&
                        dataSnapshot.data?['status'] == true) {
                      final companyId = dataSnapshot.data?['companyId'];
                      final userPosition = dataSnapshot.data?['userPosition'];

                      return MainPage(
                        companyId: companyId,
                        userPosition: userPosition,
                      );
                    } else if (dataSnapshot.hasData &&
                        dataSnapshot.data?['status'] != true) {
                      FirebaseAuth.instance.signOut();
                      return buildLoginPage();
                    } else {
                      return buildLoginPage();
                    }
                  }
                },
              );
            } else {
              return buildLoginPage();
            }
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> fetchData(String? email) async {
    if (email != null) {
      final querySnapshot = await _users.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData =
            querySnapshot.docs.first.data() as Map<String, dynamic>?;

        if (userData != null) {
          final companyId = userData['companyId'] as String?;
          final userPosition = userData['position'] as String?;

          return {
            'companyId': companyId,
            'userPosition': userPosition,
          };
        }
      }
    }
    return null;
  }

  Widget buildLoginPage() {
    // _companyIdController.clear();
    // _passwordController.clear();
    // Your existing login page UI code...
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.0, 50.0, 20.0, 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Logo
              Image.asset('assets/images/logo.png', width: 240, height: 240),
              const SizedBox(height: 10),
              // Text Inform user
              const Text(
                'Please fill up the form to login',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              // Company ID Text Field
              Container(
                // margin: EdgeInsets.symmetric(horizontal: 50),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.purple[300]!, width: 2.5),
                ),
                child: TextFormField(
                  controller: _companyIdController,
                  style: const TextStyle(color: Colors.black),
                  obscureText: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none, //Remove default line
                    hintText: "Enter Company ID",
                    labelText: "Company ID",
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.purple[300]!, width: 2.5),
                ),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.black),
                      obscureText: obscure,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Password",
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obscure = !obscure;
                              icon = obscure
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility);
                            });
                          },
                          icon: icon,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Container(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ForgotPasswordPage()));
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Colors.purple[200],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Confirm Button
              ElevatedButton(
                onPressed: () async {
                  final String companyId = _companyIdController.text;
                  final String password = _passwordController.text;

                  final isValidCredentials =
                      await checkCredentials(companyId, password);
                  if (isValidCredentials) {
                    await profileRepository.updatePassword(companyId, password);
                    // User authentication successful
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainPage(
                            companyId: companyId, userPosition: userPosition),
                      ),
                    );
                  } else {
                    logger.w('Invalid Company ID or Password');
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid Company ID or Password'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[300],
                  elevation: 4.0,
                  shadowColor: Colors.purple,
                  minimumSize: const Size(200, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text('Login',
                    style: TextStyle(color: Colors.white, fontSize: 15.0)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
