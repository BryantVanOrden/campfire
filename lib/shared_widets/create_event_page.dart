import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateEventPage extends StatefulWidget {
  @override
  _CreateEventPageState createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  String? selectedGroup;
  String? selectedGroupId;
  File? eventImage;
  DateTime? eventDateTime;
  bool isPublicEvent = false;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<Map<String, String>> userGroups = [];

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      List<String> groupIds = List<String>.from(userDoc['groupIds'] ?? []);
      
      for (String groupId in groupIds) {
        DocumentSnapshot groupDoc = await _firestore.collection('groups').doc(groupId).get();
        if (groupDoc.exists) {
          String groupName = groupDoc['name'];
          userGroups.add({'id': groupId, 'name': groupName});
        }
      }

      setState(() {}); // Update the dropdown with the groups
    }
  }

  Future<void> _pickEventImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        eventImage = File(image.path);
      });
    }
  }

  Future<void> _selectDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          eventDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<String?> _uploadEventImage() async {
    if (eventImage == null) return null;

    try {
      String fileName = 'event_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(eventImage!);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _createEvent() async {
    if (_eventNameController.text.isEmpty || selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    String? imageUrl = await _uploadEventImage();

    await _firestore.collection('events').add({
      'name': _eventNameController.text,
      'description': _eventDescriptionController.text,
      'imageLink': imageUrl,
      'groupId': selectedGroupId,
      'location': _locationController.text,
      'dateTime': eventDateTime != null ? Timestamp.fromDate(eventDateTime!) : null,
      'isPublic': isPublicEvent,
    });

    Navigator.pop(context); // Go back to the previous page after creating the event
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Dropdown
            if (userGroups.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Group'),
                items: userGroups.map((group) {
                  return DropdownMenuItem(
                    value: group['id'],
                    child: Text(group['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedGroupId = value;
                    selectedGroup = userGroups
                        .firstWhere((group) => group['id'] == value)['name'];
                  });
                },
                value: selectedGroupId,
              )
            else
              Text('No groups available for this user'),

            // Event Name
            TextFormField(
              controller: _eventNameController,
              decoration: InputDecoration(labelText: 'Event Name'),
            ),

            // Event Description
            TextFormField(
              controller: _eventDescriptionController,
              decoration: InputDecoration(labelText: 'Event Description'),
              maxLines: 3,
            ),

            // Event Image Picker
            SizedBox(height: 16),
            if (eventImage != null)
              Image.file(
                eventImage!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 100),
              ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickEventImage,
              icon: Icon(Icons.photo_library),
              label: Text('Pick Event Image'),
            ),

            // Date Time Picker
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _selectDateTime,
              icon: Icon(Icons.calendar_today),
              label: Text(eventDateTime == null
                  ? 'Pick Date & Time'
                  : 'Date: ${eventDateTime?.toLocal()}'),
            ),

            // Location
            TextFormField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Event Location'),
            ),

            // Public or Group Event Toggle
            SwitchListTile(
              title: Text('Is this a public event?'),
              value: isPublicEvent,
              onChanged: (value) {
                setState(() {
                  isPublicEvent = value;
                });
              },
            ),

            // Create Event Button
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createEvent,
              child: Text('Create Event'),
            ),
          ],
        ),
      ),
    );
  }
}
