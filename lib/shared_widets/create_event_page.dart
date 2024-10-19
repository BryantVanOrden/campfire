import 'package:campfire/shared_widets/custom_dropdown_form_field.dart';
import 'package:campfire/shared_widets/custom_text_form_field.dart';
import 'package:campfire/shared_widets/primary_button.dart';
import 'package:campfire/shared_widets/secondary_button.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

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
  final TextEditingController _eventDescriptionController =
      TextEditingController();
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
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      List<String> groupIds = List<String>.from(userDoc['groupIds'] ?? []);

      for (String groupId in groupIds) {
        DocumentSnapshot groupDoc =
            await _firestore.collection('groups').doc(groupId).get();
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
      initialDate: eventDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: eventDateTime != null
            ? TimeOfDay.fromDateTime(eventDateTime!)
            : TimeOfDay.now(),
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
      String fileName =
          'event_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask =
          _storage.ref().child(fileName).putFile(eventImage!);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _sendEventToGroupChat(String groupId, String eventName,
      String? imageUrl, DateTime? eventDateTime, String? location,
      {required String chatType}) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection(chatType == 'public' ? 'publicMessages' : 'messages')
        .add({
      'text': 'Event Created: $eventName',
      'imageLink': imageUrl,
      'location': location,
      'dateTime':
          eventDateTime != null ? Timestamp.fromDate(eventDateTime) : null,
      'type': 'event', // Specify this is an event
      'timestamp': FieldValue.serverTimestamp(), // Record the time
    });
  }

  void _createEvent() async {
    if (_eventNameController.text.isEmpty || selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    String? imageUrl = await _uploadEventImage();

    // Save event details in Firestore under the "events" collection
    await _firestore.collection('events').add({
      'name': _eventNameController.text,
      'description': _eventDescriptionController.text,
      'imageLink': imageUrl,
      'groupId': selectedGroupId,
      'location': _locationController.text,
      'dateTime':
          eventDateTime != null ? Timestamp.fromDate(eventDateTime!) : null,
      'isPublic': isPublicEvent,
    });

    // After creating the event, send a message to the group's chat
    if (selectedGroupId != null) {
      // Send event to members' chat (always)
      await _sendEventToGroupChat(
        selectedGroupId!,
        _eventNameController.text,
        imageUrl,
        eventDateTime,
        _locationController.text,
        chatType: 'members',
      );

      // If the event is public, also send it to the public chat
      if (isPublicEvent) {
        await _sendEventToGroupChat(
          selectedGroupId!,
          _eventNameController.text,
          imageUrl,
          eventDateTime,
          _locationController.text,
          chatType: 'public',
        );
      }
    }

    Navigator.pop(context); // Go back after event creation
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Dropdown
            if (userGroups.isNotEmpty)
              CustomDropdownFormField<String>(
                labelText: 'Select Group',
                hintText: 'Gym Bros',
                value: selectedGroupId,
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
              )
            else
              const Text('No groups available for this user'),

            // Event Name
            CustomTextFormField(
              controller: _eventNameController,
              labelText: 'Event Name',
              hintText: 'Camping with the boys',
            ),

            // Event Description
            CustomTextFormField(
              controller: _eventDescriptionController,
              labelText: 'Event Description',
              hintText: 'It’s gonna be lit!',
              maxLines: 3,
            ),

            // Event Image Picker
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.lightGrey,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: eventImage != null
                    ? Image.file(
                        eventImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 100),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              onPressed: _pickEventImage,
              text: 'Pick Event Image',
              icon: Icons.photo_library,
            ),

            // Date Time Picker
            const SizedBox(height: 16),
            SecondaryButton(
              onPressed: _selectDateTime,
              text: eventDateTime == null
                  ? 'Pick Date & Time'
                  : 'Date: ${eventDateTime?.toLocal()}',
              icon: Icons.calendar_today,
            ),

            // Location
            CustomTextFormField(
              controller: _locationController,
              labelText: 'Location',
              hintText: 'The TETONS!!!!',
            ),

            // Public Event Toggle
            SwitchListTile(
              title: const Text('Is this a public event?'),
              value: isPublicEvent,
              onChanged: (value) {
                setState(() {
                  isPublicEvent = value;
                });
              },
              tileColor: Colors.grey.shade200,
              inactiveTrackColor: Colors.grey.shade400,
              inactiveThumbColor: Colors.grey.shade600,
              activeColor: AppColors.mediumGreen,
              activeTrackColor: AppColors.lightGreen,
            ),

            // Create Event Button
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _createEvent,
              text: 'Create Event',
            ),
          ],
        ),
      ),
    );
  }
}
