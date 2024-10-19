import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:campfire/theme/app_theme.dart';
import 'package:latlong2/latlong.dart';

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
  String? _pickedLocation;
  DateTime? _dateOfBirth;

  bool _isLogin = true; // Toggle between login and sign-up
  bool _passwordVisible = false; // Password visibility toggle

  // Form validation key
  final _formKey = GlobalKey<FormState>();

  // Sign-Up Logic
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedLocation == null) {
        print("Location not picked.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please pick a location.')),
        );
        return;
      }

      try {
        // Create user in Firebase Authentication
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Check if the location and other data are set correctly
        print(
            "Saving user data: Email: ${_emailController.text}, Location: $_pickedLocation, DOB: $_dateOfBirth");

        // Save user data to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': _emailController.text,
          'location': _pickedLocation, // Save the formatted location string
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'interests': [],
          'groupIds': [],
          'profileImageLink': null,
        });

        print(
            "User registered and saved to Firestore: ${userCredential.user?.uid}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Successful')),
        );
        // After successful sign-up, send the user to the home page
        // After successful sign-up, navigate to home page
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        print("Sign Up Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.message}')),
        );
      }
    }
  }

  // Set picked location string when a location is picked

  // Login Logic
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        print("Login successful");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful')),
        );

        // Navigate to the next screen or home page after successful login

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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.darkGreen, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.darkGreen, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
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
      appBar: AppBar(
        title: Text('Sign Up/Login'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Toggle between Login and Sign Up
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white, // Use scaffold background color
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkGreen),
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
                          color: _isLogin
                              ? AppColors.darkGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              color:
                                  _isLogin ? Colors.white : AppColors.darkGreen,
                              fontWeight: FontWeight.bold,
                            ),
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
                          color: !_isLogin
                              ? AppColors.darkGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: !_isLogin
                                  ? Colors.white
                                  : AppColors.darkGreen,
                              fontWeight: FontWeight.bold,
                            ),
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
                  color: Colors.white, // Use a consistent background color
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.darkGreen.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon:
                            Icon(Icons.email, color: AppColors.darkGreen),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        // Basic email format validation
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon:
                            Icon(Icons.lock, color: AppColors.darkGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.darkGreen,
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
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    if (!_isLogin) ...[
                      // Location Field

                      
                      SizedBox(height: 16),
                      // Date of Birth Picker
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: AbsorbPointer(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.calendar_today,
                                  color: AppColors.darkGreen),
                              hintText: _dateOfBirth == null
                                  ? 'Select Date of Birth'
                                  : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                            ),
                            validator: (value) {
                              if (_dateOfBirth == null) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLogin ? _login : _signUp,
                        child: Text(_isLogin ? 'Login' : 'Sign Up'),
                      ),
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
