
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_student.dart';
import 'login_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final CollectionReference<Map<String, dynamic>> students =
      FirebaseFirestore.instance.collection('students');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> studentStream;

  String searchQuery = '';

  static const Color primaryColor = Color(0xFF21DDA5);
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color textColor = Color(0xFF263238);

  @override
  void initState() {
    super.initState();
    studentStream = students.snapshots();
  }

  // GET YEAR LEVEL
  String getYearLevel(Map<String, dynamic> data) {
    final year = data['year_level'] ?? data['yearLevel'] ?? '';

    if (year.toString().trim().isEmpty) {
      return 'Unspecified Year Level';
    }

    return year.toString();
  }

  // STUDENT INITIALS
  String getInitials(String name) {
    final parts = name.trim().split(' ');

    if (parts.isEmpty || parts.first.isEmpty) {
      return 'S';
    }

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // LOGOUT CONFIRMATION
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    }
  }

  // DELETE STUDENT
  Future<void> deleteStudent(String documentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await students.doc(documentId).delete();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student successfully deleted!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete student: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // STAT CARD
  Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(
              icon,
              color: color,
              size: 28,
            ),
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
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // COURSE ENROLLMENT STATISTICS
  Widget buildCourseStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> studentDocs,
  ) {
    Map<String, int> courseCounts = {};

    for (var doc in studentDocs) {
      final data = doc.data();

      String course = (data['course'] ?? 'Unspecified').toString().trim();

      if (course.isEmpty) {
        course = 'Unspecified';
      }

      courseCounts[course] = (courseCounts[course] ?? 0) + 1;
    }

    final sortedCourses = courseCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int totalStudents = studentDocs.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: primaryColor,
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Course Enrollment Statistics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Student distribution by course',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 22),

          if (sortedCourses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No course enrollment data available.'),
              ),
            )
          else
            ...sortedCourses.map((entry) {
              double percentage = totalStudents == 0
                  ? 0
                  : entry.value / totalStudents;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} students',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8EDF0),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          primaryColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% of total enrollment',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),     
        ],
      ),
    );
  }

  // YEAR LEVEL STATISTICS
  Widget buildYearLevelStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> studentDocs,
  ) {
    Map<String, int> yearCounts = {};

    for (var doc in studentDocs) {
      final data = doc.data();
      String year = getYearLevel(data);

      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    final yearOrder = [
      '1st Year',
      '2nd Year',
      '3rd Year',
      '4th Year',
      '5th Year',
    ];

    final sortedYears = yearCounts.entries.toList()
      ..sort((a, b) {
        int indexA = yearOrder.indexOf(a.key);
        int indexB = yearOrder.indexOf(b.key);

        if (indexA == -1) indexA = 999;
        if (indexB == -1) indexB = 999;

        return indexA.compareTo(indexB);
      });

    int totalStudents = studentDocs.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: Colors.blue,
                size: 26,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Year Level Statistics',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Student distribution by year level',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 22),

          if (sortedYears.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No year level data available.'),
              ),
            )
          else
            ...sortedYears.map((entry) {
              double percentage = totalStudents == 0
                  ? 0
                  : entry.value / totalStudents;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} students',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 9),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8EDF0),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% of total enrollment',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // SEARCH BAR
  Widget buildSearchBar() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value.trim().toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search student...',
        prefixIcon: const Icon(
          Icons.search,
          color: primaryColor,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // STUDENT CARD
  Widget buildStudentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    String name = (data['name'] ?? 'Unknown Student').toString();
    String studentNo = (data['student_no'] ?? 'No Student Number').toString();
    String course = (data['course'] ?? 'No Course').toString();
    String yearLevel = getYearLevel(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: primaryColor.withOpacity(0.15),
            child: Text(
              getInitials(name),
              style: const TextStyle(
                color: Color(0xFF159B76),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  studentNo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 7),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildInfoChip(
                      course,
                      primaryColor,
                    ),
                    _buildInfoChip(
                      yearLevel,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Delete Student',
            onPressed: () => deleteStudent(doc.id),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // INFORMATION CHIP
  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color == primaryColor
              ? const Color(0xFF159B76)
              : color,
        ),
      ),
    );
  }

  // MAIN DASHBOARD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add Student',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateStudent(),
                ),
              );
            },
            icon: const Icon(
              Icons.person_add_alt_1,
              color: primaryColor,
            ),
          ),

          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: studentStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Something went wrong.'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          // TOTAL COURSES
          final courses = docs
              .map((doc) => doc.data()['course']?.toString().trim() ?? '')
              .where((course) => course.isNotEmpty)
              .toSet();

          // SEARCH FILTER
          final filteredStudents = docs.where((doc) {
            final data = doc.data();

            final name = (data['name'] ?? '')
                .toString()
                .toLowerCase();

            final studentNo = (data['student_no'] ?? '')
                .toString()
                .toLowerCase();

            final yearLevel = getYearLevel(data).toLowerCase();

            return name.contains(searchQuery) ||
                studentNo.contains(searchQuery) ||
                yearLevel.contains(searchQuery);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    buildStatCard(
                      title: 'Total Students',
                      value: '${docs.length}',
                      icon: Icons.people_alt_outlined,
                      color: primaryColor,
                    ),

                    const SizedBox(width: 12),

                    buildStatCard(
                      title: 'Total Courses',
                      value: '${courses.length}',
                      icon: Icons.school_outlined,
                      color: Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // COURSE ENROLLMENT STATISTICS
                buildCourseStatistics(docs),

                const SizedBox(height: 20),

                // YEAR LEVEL STATISTICS
                buildYearLevelStatistics(docs),

                const SizedBox(height: 25),

                // STUDENT LIST HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Student List',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    
                  ],
                ),

                const SizedBox(height: 14),

                // SEARCH STUDENT
                buildSearchBar(),

                const SizedBox(height: 18),

                // STUDENT RECORDS
                if (filteredStudents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 55,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isEmpty
                                ? 'No students available.'
                                : 'No matching students found.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredStudents.map(
                    (doc) => buildStudentCard(doc),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
