// interests_page.dart
import 'package:campfire/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:campfire/providers/interest_provider.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({Key? key}) : super(key: key);

  @override
  _InterestsPageState createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  // Hard-coded list of interests
  final List<String> allInterests = [
    'Sports',
    'Music',
    'Gaming',
    'Technology',
    'Travel',
    'Food',
    'Movies',
    'Fitness',
    'Books',
    'Art',
    'Science',
    'History',
    'Photography',
    'Outdoors',
    'Cars',
    'Fashion',
    'Politics',
    'Business',
    'Education',
    'Health',
  ];

  List<String> selectedInterests = [];

  @override
  Widget build(BuildContext context) {
    final interestProvider = Provider.of<InterestProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Interests'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: allInterests.length,
              itemBuilder: (context, index) {
                String interest = allInterests[index];
                bool isSelected = selectedInterests.contains(interest);

                return CheckboxListTile(
                  title: Text(interest),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value != null && value) {
                        selectedInterests.add(interest);
                      } else {
                        selectedInterests.remove(interest);
                      }
                    });
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              // Post the selected interests
              await interestProvider.postInterests(selectedInterests);

              // Navigate to HomePage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Text('Save Interests'),
          ),
        ],
      ),
    );
  }
}
