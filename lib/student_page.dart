import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  Future<void> saveTestData() async {
    await FirebaseFirestore.instance.collection('students').add({
      'name': 'Juan Dela Cruz',
      'course': 'BS Computer Science',
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
