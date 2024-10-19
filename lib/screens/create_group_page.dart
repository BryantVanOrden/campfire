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
      String fileName = 'group_images/${Uuid().v4()}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(_groupImage!);
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
      String groupId = Uuid().v4();

      // Create the group in Firestore
      final newGroup = Group(
        groupId: groupId,
        name: _groupName,
        members: [],
        moderators: [],
        publicMembers: [],
        bannedUids: [],
        imageUrl: imageUrl, // Add the image URL to the group structure
      );

      // Add group to the Firestore collection
      await _firestore.collection('groups').doc(groupId).set({
        'groupId': groupId,
        'name': _groupName,
        'members': [], // Optionally, add the user as a member here
        'moderators': [], // Optionally, add the user as a moderator here
        'publicMembers': [],
        'bannedUids': [],
        'imageUrl': imageUrl,
      });

      // Add the groupId to the user's groupIds
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentReference userDoc = _firestore.collection('users').doc(user.uid);
        userDoc.update({
          'groupIds': FieldValue.arrayUnion([groupId])
        });
      }

      // Add group to the provider (if necessary for local state)
      Provider.of<GroupProvider>(context, listen: false).addGroup(newGroup);

      // Navigate back to home
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create a New Group'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name Input
                TextFormField(
                  decoration: InputDecoration(labelText: 'Group Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                  onSaved: (value) => _groupName = value!,
                ),

                SizedBox(height: 20),

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
                    child: Icon(Icons.image, size: 100),
                  ),

                SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _pickGroupImage,
                  icon: Icon(Icons.photo_library),
                  label: Text('Pick Group Image'),
                ),

                SizedBox(height: 20),

                // Create Group Button
                ElevatedButton(
                  onPressed: _submit,
                  child: Text('Create Group'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
