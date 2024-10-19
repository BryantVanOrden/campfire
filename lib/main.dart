import 'package:campfire/providers/feed_provider.dart';
import 'package:campfire/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campfire/firebase_options.dart';
import 'package:campfire/home/home.dart';
import 'package:campfire/signup_signin/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/group_provider.dart';
import 'theme/app_theme.dart';
import 'package:campfire/providers/interest_provider.dart'; // Import InterestProvider
import 'package:campfire/signup_signin/interests_page.dart'; // Import InterestsPage



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Ensure SharedPreferences is initialized
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;

  const MyApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<GroupProvider>(
          create: (_) => GroupProvider(),
        ),
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<InterestProvider>(
          create: (_) => InterestProvider(),
        ),
      ],
      child: AuthenticationWrapper(isDarkMode: isDarkMode),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  final bool isDarkMode;

  const AuthenticationWrapper({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final interestProvider = Provider.of<InterestProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Build MaterialApp here
        return MaterialApp(
          title: 'Campfire App',
          theme: themeProvider.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: _buildHome(snapshot, interestProvider),
        );
      },
    );
  }

  Widget _buildHome(
    AsyncSnapshot<User?> snapshot,
    InterestProvider interestProvider,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting || interestProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else if (snapshot.hasData) {
      return FutureBuilder<bool>(
        future: interestProvider.checkInterest(),
        builder: (context, interestSnapshot) {
          if (interestSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (interestSnapshot.hasData) {
            if (interestSnapshot.data == true) {
              return const HomePage();
            } else {
              return const InterestsPage();
            }
          } else {
            return const Scaffold(
              body: Center(child: Text('Error loading interests')),
            );
          }
        },
      );
    } else {
      return const LoginPage();
    }
  }
}