import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data_structure/group_struct.dart'; // Corrected import
import '../providers/group_provider.dart';
import 'package:uuid/uuid.dart';

class CreateGroupPage extends StatefulWidget {
  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  String _groupName = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Create a new group instance
      final newGroup = Group(
        groupId: Uuid().v4(),
        name: _groupName,
        members: [],
        moderators: [],
        publicMembers: [],
        bannedUids: [],
      );
      // Add group to the provider
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
          child: Column(
            children: [
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
              ElevatedButton(
                onPressed: _submit,
                child: Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
