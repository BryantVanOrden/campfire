import 'package:campfire/shared_widets/custom_text_form_field.dart';
import 'package:campfire/shared_widets/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_structure/group_struct.dart'; // Corrected import
import '../providers/group_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _groupName = '';
  File? _groupImage;
  String? _groupImageUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickGroupImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _groupImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadGroupImage() async {
    if (_groupImage == null) return null;

    try {
      String fileName = 'group_images/${const Uuid().v4()}.jpg';
      UploadTask uploadTask =
          _storage.ref().child(fileName).putFile(_groupImage!);
      TaskSnapshot taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading group image: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Upload the group image if one is selected
      String? imageUrl = await _uploadGroupImage();

      // Generate a new group ID
      String groupId = const Uuid().v4();

      // Get the current user UID
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      String userId = user.uid;

      // Create the group in Firestore with the current user as a member and a moderator
      await _firestore.collection('groups').doc(groupId).set({
        'groupId': groupId,
        'name': _groupName,
        'members': [userId], // Add the current user as a member
        'moderators': [userId], // Add the current user as a moderator
        'publicMembers': [],
        'bannedUids': [],
        'imageUrl': imageUrl,
      });

      // Add the groupId to the user's groupIds
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'groupIds': FieldValue.arrayUnion([groupId])
      });

      // Add group to the provider (if necessary for local state)
      final newGroup = Group(
        groupId: groupId,
        name: _groupName,
        members: [userId],
        moderators: [userId],
        publicMembers: [],
        bannedUids: [],
        imageUrl: imageUrl, // Add the image URL to the group structure
      );
      Provider.of<GroupProvider>(context, listen: false).addGroup(newGroup);

      // Navigate back to home
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name Input
                CustomTextFormField(
                  labelText: 'Group Name', // Using your custom labelText
                  hintText: 'Enter group name', // Using your custom hintText
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                  onSaved: (value) =>
                      _groupName = value!, // Save the group name
                ),

                const SizedBox(height: 20),

                // Group Image Picker
                if (_groupImage != null)
                  Image.file(
                    _groupImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 100),
                  ),

                const SizedBox(height: 10),

                SecondaryButton(
                  onPressed: () {
                    // Implement image picking logic if needed
                  },
                  text: 'Pick Group Image',
                  icon: Icons.photo_library,
                ),

                const SizedBox(height: 20),

                // Create Group Button
                SecondaryButton(
                  onPressed: _submit,
                  text: 'Create Group',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
