import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SignUpLoginPage extends StatefulWidget {
  @override
  _SignUpLoginPageState createState() => _SignUpLoginPageState();
}

class _SignUpLoginPageState extends State<SignUpLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for Sign Up and Login
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _dateOfBirth;

  bool _isLogin = true; // Toggle between login and sign-up
  bool _passwordVisible = false; // Password visibility toggle

  // Form validation key
  final _formKey = GlobalKey<FormState>();

  // Sign-Up Logic
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // Create user in Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': _emailController.text,
          'location': _locationController.text,
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'interests': [],
          'groupIds': [],
          'profileImageLink': null,
        });

        // After successful sign-up, send the user to the home page
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        print("Sign Up Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.message}')),
        );
      }
    }
  }

  // Login Logic
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        
        // After successful login, navigate to the home page
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        print("Login Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Failed: ${e.message}')),
        );
      }
    }
  }

  // Date Picker for Date of Birth
  void _selectDateOfBirth() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _dateOfBirth = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up/Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between Login and Sign Up
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = true;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isLogin ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                                color: _isLogin ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isLogin = false;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isLogin ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12)),
                        ),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                                color: !_isLogin ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Form(
              key: _formKey,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_passwordVisible,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    if (!_isLogin) ...[
                      // Additional fields for Sign-Up
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(labelText: 'Location'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your location';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: _selectDateOfBirth,
                        child: Text(_dateOfBirth == null
                            ? 'Select Date of Birth'
                            : 'DOB: ${_dateOfBirth!.toLocal()}'),
                      ),
                    ],
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLogin ? _login : _signUp,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
