import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_student.dart';
import 'login_page.dart';
import 'student_list_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final CollectionReference<Map<String, dynamic>> students = FirebaseFirestore
      .instance
      .collection('students');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> studentStream;

  static const Color primaryColor = Color(0xFF21DDA5);
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color textColor = Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    studentStream = students.snapshots();
  }

  String getYearLevel(Map<String, dynamic> data) {
    return (data['year_level'] ?? data['yearLevel'] ?? 'Not specified')
        .toString();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _openStudentList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentListPage()),
    );
  }

  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),
                if (onTap != null)
                  const Text(
                    'Tap to view students',
                    style: TextStyle(fontSize: 10, color: primaryColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCourseStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    Map<String, int> courseCounts = {};

    for (var doc in docs) {
      String course = (doc.data()['course'] ?? 'Unknown').toString();

      if (course.trim().isNotEmpty) {
        courseCounts[course] = (courseCounts[course] ?? 0) + 1;
      }
    }

    if (courseCounts.isEmpty) {
      return const Text('No course data available.');
    }

    return Column(
      children: courseCounts.entries.map((entry) {
        double percentage = docs.isEmpty ? 0 : entry.value / docs.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} Students',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(primaryColor),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildYearLevelStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    const yearLevels = ['1st Year', '2nd Year', '3rd Year', '4th Year'];

    Map<String, int> yearCounts = {for (var year in yearLevels) year: 0};

    for (var doc in docs) {
      String year = getYearLevel(doc.data());

      if (yearCounts.containsKey(year)) {
        yearCounts[year] = yearCounts[year]! + 1;
      }
    }

    return Column(
      children: yearLevels.map((year) {
        int count = yearCounts[year] ?? 0;
        double percentage = docs.isEmpty ? 0 : count / docs.length;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    year,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$count Students',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: studentStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Something went wrong: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          final courses = docs
              .map((doc) => (doc.data()['course'] ?? '').toString())
              .where((course) => course.trim().isNotEmpty)
              .toSet();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 15),

                Row(
                  children: [
                    buildStatCard(
                      title: 'Total Students',
                      value: '${docs.length}',
                      icon: Icons.people_alt_outlined,
                      color: primaryColor,
                      onTap: _openStudentList,
                    ),

                    const SizedBox(width: 12),

                    buildStatCard(
                      title: 'Total Courses',
                      value: '${courses.length}',
                      icon: Icons.menu_book_outlined,
                      color: Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                const Text(
                  'Course Enrollment Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: buildCourseStatistics(docs),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Year Level Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: buildYearLevelStatistics(docs),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateStudent()),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }
}
