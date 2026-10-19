import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class CreateStudent extends StatefulWidget {
  const CreateStudent({super.key});

  @override
  State<CreateStudent> createState() => _StudentPageState();
}

class _StudentPageState extends State<CreateStudent> {
  Future<void> saveTestData() async {
    await FirebaseFirestore.instance.collection('students').add({
      'name': 'Christian John G. Arnidoval',
      'course': 'BS Information Technology',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Page")),
      body: Column(
        children: [
          FilledButton(
            onPressed: saveTestData,
            child: const Text("Save test Student"),
          ),
        ],
      ),
    );
  }
}
