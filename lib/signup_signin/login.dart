import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
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
          email: _emailController.text,
          password: _passwordController.text,
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
  void _onLocationPicked(LatLong latLng) {
    setState(() {
      _pickedLocation = "${latLng.latitude}, ${latLng.longitude}";
      print(
          "Picked location: $_pickedLocation"); // Debugging output to check if location is picked correctly
    });
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
                      Text(
                        _pickedLocation == null
                            ? 'Please pick a location'
                            : 'Location: $_pickedLocation',
                      ),
                      SizedBox(
                        height: 300, // Set a fixed height for the map picker
                        child: FlutterLocationPicker(
                          initZoom: 11,
                          minZoomLevel: 5,
                          maxZoomLevel: 16,
                          trackMyPosition: true,
                          onPicked: (pickedData) {
                            _onLocationPicked(pickedData.latLong as LatLong);
                          },
                        ),
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
