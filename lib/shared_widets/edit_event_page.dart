import 'package:campfire/shared_widets/custom_text_form_field.dart';
import 'package:campfire/shared_widets/primary_button.dart';
import 'package:campfire/shared_widets/secondary_button.dart';
import 'package:campfire/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class EditEventPage extends StatefulWidget {
  final DocumentSnapshot event;

  const EditEventPage({super.key, required this.event});

  @override
  _EditEventPageState createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? eventDateTime;
  bool isPublicEvent = false;
  File? eventImage; // Placeholder for an image if needed

  @override
  void initState() {
    super.initState();
    // Initialize the form fields with the event data
    _eventNameController.text = widget.event['name'];
    _eventDescriptionController.text = widget.event['description'];
    _locationController.text = widget.event['location'] ?? '';
    isPublicEvent = widget.event['isPublic'] ?? false;
    eventDateTime = widget.event['dateTime'] != null
        ? (widget.event['dateTime'] as Timestamp).toDate()
        : null;
  }

  Future<void> _updateEvent() async {
    if (_eventNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event name cannot be empty')),
      );
      return;
    }

    // Update the event in Firestore
    await _firestore.collection('events').doc(widget.event.id).update({
      'name': _eventNameController.text,
      'description': _eventDescriptionController.text,
      'location': _locationController.text,
      'isPublic': isPublicEvent,
      'dateTime':
          eventDateTime != null ? Timestamp.fromDate(eventDateTime!) : null,
    });

    // Send updated event to group chats
    await _sendUpdatedEventToGroupChats();

    Navigator.pop(context);
  }

  Future<void> _sendUpdatedEventToGroupChats() async {
    String groupId = widget.event['groupId'];
    String eventName = _eventNameController.text;
    String? location = _locationController.text;
    DateTime? dateTime = eventDateTime;

    // Send the updated event to members' chat
    await _sendEventToGroupChat(groupId, eventName, location, dateTime,
        chatType: 'members');

    // If public, send to public chat as well
    if (isPublicEvent) {
      await _sendEventToGroupChat(groupId, eventName, location, dateTime,
          chatType: 'public');
    }
  }

  Future<void> _sendEventToGroupChat(String groupId, String eventName,
      String? location, DateTime? dateTime,
      {required String chatType}) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection(chatType == 'public' ? 'publicMessages' : 'messages')
        .add({
      'text': 'Event Updated: $eventName',
      'location': location,
      'dateTime': dateTime != null ? Timestamp.fromDate(dateTime) : null,
      'type': 'event',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteEvent() async {
    // Delete the event from Firestore
    await _firestore.collection('events').doc(widget.event.id).delete();
    Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Event Image Placeholder (optional)
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
            // Optional: Add a button to change the event image
            SecondaryButton(
              onPressed: () {
                // Implement image picking logic if needed
              },
              text: 'Change Event Image',
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

            // Location Input
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

            // Update Event Button
            const SizedBox(height: 16),
            PrimaryButton(
              onPressed: _updateEvent,
              text: 'Update Event',
            ),

            // Delete Event Button
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _deleteEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
              ),
              child: const Text('Delete Event'),
            ),
          ],
        ),
      ),
    );
  }
}
