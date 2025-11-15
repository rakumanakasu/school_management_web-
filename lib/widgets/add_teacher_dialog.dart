import 'package:flutter/material.dart';
import '../models/teacher.dart';

class AddTeacherDialog extends StatefulWidget {
  final Function(Teacher) onAdd;

  const AddTeacherDialog({super.key, required this.onAdd});

  @override
  State<AddTeacherDialog> createState() => _AddTeacherDialogState();
}

class _AddTeacherDialogState extends State<AddTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String email = '';
  String subject = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Teacher'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              onSaved: (v) => name = v!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
              onSaved: (v) => email = v!,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (v) => v == null || v.isEmpty ? 'Enter subject' : null,
              onSaved: (v) => subject = v!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onAdd(Teacher(id: DateTime.now().millisecondsSinceEpoch, name: name, email: email, subject: subject));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
