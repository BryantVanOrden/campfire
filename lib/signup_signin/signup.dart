import 'package:campfire/shared_widets/location_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';



class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  LatLng? _selectedLocation;
  DateTime? _dateOfBirth;
  bool _passwordVisible = false;
  final _formKey = GlobalKey<FormState>();

  String _errorMessage = '';

  Future<void> _signUp() async {
    setState(() {
      _errorMessage = ''; // Clear error message before login attempt
    });

    if (_displayNameController.text.trim().isEmpty) {
      _errorMessage = "Display Name is required.";
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _errorMessage = "Email is required.";
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
        .hasMatch(_emailController.text.trim())) {
      _errorMessage = 'Please enter a valid email';
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _errorMessage = "Password is required.";
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _errorMessage = 'Password must be at least 6 characters';
      return;
    }

    if (_selectedLocation == null) {
      _errorMessage = "Location is required.";
      return;
    }

    if (_dateOfBirth == null) {
      _errorMessage = "Date of Birth is required.";
      return;
    }

    if (_formKey.currentState!.validate() && _selectedLocation != null) {
      try {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'uid': userCredential.user?.uid,
          'email': _emailController.text,
          'displayName': _displayNameController.text,
          'location': {
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
          },
          // 'location': _selectedLocation,
          'dateOfBirth': _dateOfBirth?.toIso8601String(),
          'groupIds': [],
          'interests': [],
          'photoURL': "",
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign Up Successful')),
        );
        Navigator.pop(context);
        // Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: ${e.message}')),
        );
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
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

  Future<void> _pickLocation() async {
    LatLng initialLocation = const LatLng(
        43.8145766, -111.7842279); // Example: New York City coordinates
    final LatLng? selectedLocation = await showDialog<LatLng>(
      context: context,
      builder: (BuildContext context) {
        return LocationSelector(initialLocation: initialLocation);
      },
    );

    if (selectedLocation != null) {
      setState(() {
        _selectedLocation = selectedLocation;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Sign Up'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // SVG Icon
            SvgPicture.asset(
              'assets/images/campfire-text.svg',
              width: 200.0,
              height: 200.0,
            ),
            const SizedBox(height: 16),
            // Display Name Field
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                  prefixIcon: Icon(Icons.person, color: AppColors.darkGreen),
                ),
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 16),
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: AppColors.darkGreen),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:
                      const Icon(Icons.lock, color: AppColors.darkGreen),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.darkGreen,
                    ),
                    onPressed: () =>
                        setState(() => _passwordVisible = !_passwordVisible),
                  ),
                ),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 16),
              // Date of Birth Picker
              GestureDetector(
                onTap: _selectDateOfBirth,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.darkGreen),
                      hintText: _dateOfBirth == null
                          ? 'Select Date of Birth'
                          : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickLocation,
                child: const Text("Select location"),
              ),
              if (_selectedLocation != null)
                Text(
                    ("${_selectedLocation!.latitude}, ${_selectedLocation!.longitude}")),
              const SizedBox(height: 16),
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('Sign Up'),
                ),
              ),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              TextButton(
                child: const Text("Back to Login screen"),
                onPressed: () => {Navigator.pop(context)},
              )
            ],
          ),
        ),
      ),
    );
  }
}
