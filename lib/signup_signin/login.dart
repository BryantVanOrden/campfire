import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:campfire/theme/app_theme.dart';
import 'package:map_location_picker/map_location_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;
import 'package:latlong2/latlong.dart' as latlong;

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
  latlong.LatLng? _pickedLocation; // User's picked location
  DateTime? _dateOfBirth;

  bool _isLogin = true; // Toggle between login and sign-up
  bool _passwordVisible = false; // Password visibility toggle

  // Form validation key
  final _formKey = GlobalKey<FormState>();

  // Sign-Up Logic
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedLocation == null) {
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

        // Save user data to Firestore
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': _emailController.text.trim(),
          'location':
              "${_pickedLocation!.latitude}, ${_pickedLocation!.longitude}", // Save location
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'interests': [],
          'groupIds': [],
          'profileImageLink': null,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Successful')),
        );

        // Navigate to home page after successful sign-up
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.message}')),
        );
      }
    }
  }

  // Handle location picked from Google Maps
  void _onLocationPicked(Geometry locationData) {
    if (locationData != null) {
      setState(() {
        _pickedLocation = latlong.LatLng(
          locationData.location.lat,
          locationData.location.lng,
        );
        print(
            "Picked location: Latitude: ${_pickedLocation!.latitude}, Longitude: ${_pickedLocation!.longitude}");
      });
    }
  }

  // Login Logic
  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login Successful')),
        );

        // Navigate to home page after successful login
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
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
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Toggle between Login and Sign Up
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                                  color: _isLogin
                                      ? Colors.white
                                      : AppColors.darkGreen,
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
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: AppColors.darkGreen),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
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
                    prefixIcon: Icon(Icons.lock, color: AppColors.darkGreen),
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
                  Text(
                    "Pick Your Location to Connect with Nearby Users",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: SizedBox(
                      height: 400, // Reduced the height of the map
                      child: MapLocationPicker(
                        apiKey: 'AIzaSyB9-_fimhOl_uiOMMjGvf-228Ya1cwfkxM',
                        onNext: (GeocodingResult? result) {
                          if (result != null) {
                            _onLocationPicked(result.geometry);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
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
      ),
    );
  }
}




//AIzaSyB9-_fimhOl_uiOMMjGvf-228Ya1cwfkxM