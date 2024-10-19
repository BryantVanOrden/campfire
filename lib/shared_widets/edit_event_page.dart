import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      'dateTime': eventDateTime != null ? Timestamp.fromDate(eventDateTime!) : null,
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
    await _sendEventToGroupChat(groupId, eventName, location, dateTime, chatType: 'members');

    // If public, send to public chat as well
    if (isPublicEvent) {
      await _sendEventToGroupChat(groupId, eventName, location, dateTime, chatType: 'public');
    }
  }

  Future<void> _sendEventToGroupChat(String groupId, String eventName,
      String? location, DateTime? dateTime, {required String chatType}) async {
    await _firestore.collection('groups').doc(groupId).collection(chatType == 'public' ? 'publicMessages' : 'messages').add({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Event Name
            TextFormField(
              controller: _eventNameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            // Event Description
            TextFormField(
              controller: _eventDescriptionController,
              decoration: const InputDecoration(labelText: 'Event Description'),
              maxLines: 3,
            ),
            // Location
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            // Public or Group Event Toggle
            SwitchListTile(
              title: const Text('Is this a public event?'),
              value: isPublicEvent,
              onChanged: (value) {
                setState(() {
                  isPublicEvent = value;
                });
              },
            ),
            // Date and Time Picker
            ElevatedButton.icon(
              onPressed: _selectDateTime,
              icon: const Icon(Icons.calendar_today),
              label: Text(eventDateTime == null
                  ? 'Pick Date & Time'
                  : 'Date: ${eventDateTime?.toLocal().toString().split(' ')[0]}'),
            ),
            // Update Button
            ElevatedButton(
              onPressed: _updateEvent,
              child: const Text('Update Event'),
            ),
            // Delete Button
            ElevatedButton(
              onPressed: _deleteEvent,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Event'),
            ),
          ],
        ),
      ),
    );
  }
}
