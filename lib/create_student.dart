import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateStudent extends StatefulWidget {
  const CreateStudent({super.key});

  @override
  State<CreateStudent> createState() => _CreateStudentState();
}

class _CreateStudentState extends State<CreateStudent> {
  final _nameController = TextEditingController();
  final _courseController = TextEditingController();
  final _studentNoController = TextEditingController();
  final _yearNoController = TextEditingController();

  Future<void> _saveStudent() async {
    if (_nameController.text.isEmpty || _courseController.text.isEmpty) return;
    
    await FirebaseFirestore.instance.collection('students').add({
      'student_no': _studentNoController.text.trim(),
      'name': _nameController.text.trim(),
      'course': _courseController.text.trim(),
      'year': _yearNoController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Clean light grey-blue background
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 33, 150, 243),
        foregroundColor: Colors.white,
        title: const Text(
          'Create Student',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: Colors.white, // Explicitly white to prevent theme tinting
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _studentNoController,
                      decoration: InputDecoration(
                        labelText: 'Student Number',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color.fromARGB(255, 33, 150, 243)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline, color: Color.fromARGB(255, 33, 150, 243)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _courseController,
                      decoration: InputDecoration(
                        labelText: 'Course',
                        prefixIcon: const Icon(Icons.school_outlined, color: Color.fromARGB(255, 33, 150, 243)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _yearNoController,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        prefixIcon: const Icon(Icons.school_outlined, color: Color.fromARGB(255, 33, 150, 243)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Save Student',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}