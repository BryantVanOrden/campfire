import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campfire/firebase_options.dart';
import 'package:campfire/home/home.dart';
import 'package:campfire/signup_signin/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'providers/group_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupProvider>(
          create: (_) => GroupProvider(),
        ),
        // You can add more providers here if needed
      ],
      child: MaterialApp(
        title: 'Campfire App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AuthenticationWrapper(),
      ),
    );
  }
}


class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasData) {
          return HomePage(); // If the user is logged in, show home page
        } else {
          return LoginPage(); // Otherwise, show login page
        }
      },
    );
  }
}
