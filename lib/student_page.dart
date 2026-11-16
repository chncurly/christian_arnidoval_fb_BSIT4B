
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
  static const Color primaryColor = Color(0xFF21D9A0);
  static const Color backgroundColor = Color(0xFFF5F7FC);

  final CollectionReference<Map<String, dynamic>> students =
      FirebaseFirestore.instance.collection('students');

  late final Stream<QuerySnapshot<Map<String, dynamic>>> studentStream;

  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    studentStream = students.snapshots();
  }

  String getYearLevel(Map<String, dynamic> data) {
    final year = (
      data['year_level'] ?? data['yearLevel'] ?? ''
    ).toString().trim();

    return year.isEmpty ? 'Unspecified Year Level' : year;
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================
  // DELETE STUDENT
  // =========================

  Future<void> deleteStudent(String documentId) async {
    try {
      await students.doc(documentId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student deleted successfully!'),
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

  void confirmDeleteStudent(String documentId, String studentName) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Student'),
          content: Text(
            'Are you sure you want to delete $studentName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                deleteStudent(documentId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // SEARCH BAR
  // =========================

  Widget buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE5EAF2),
        ),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search student name, number or year...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: primaryColor,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // =========================
  // STATISTICS CARD
  // =========================

  Widget buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // COURSE STATISTICS
  // =========================

  Widget buildCourseStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final Map<String, int> courseCounts = {};

    for (final document in documents) {
      final data = document.data();

      final course = (data['course'] ?? '').toString().trim();

      final courseName =
          course.isEmpty ? 'Unspecified Course' : course;

      courseCounts[courseName] =
          (courseCounts[courseName] ?? 0) + 1;
    }

    if (courseCounts.isEmpty) {
      return const Text(
        'No course records available.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: courseCounts.entries.map((entry) {
        final percentage = entry.value / documents.length;

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
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} Students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8EDF4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // YEAR LEVEL STATISTICS
  // =========================

  Widget buildYearLevelStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final Map<String, int> yearCounts = {};

    for (final document in documents) {
      final year = getYearLevel(document.data());

      yearCounts[year] = (yearCounts[year] ?? 0) + 1;
    }

    const yearOrder = [
      '1st Year',
      '2nd Year',
      '3rd Year',
      '4th Year',
      '5th Year',
    ];

    final sortedYears = <String, int>{};

    for (final year in yearOrder) {
      if (yearCounts.containsKey(year)) {
        sortedYears[year] = yearCounts[year]!;
      }
    }

    // Include other year-level labels and unspecified records.
    for (final entry in yearCounts.entries) {
      if (!sortedYears.containsKey(entry.key)) {
        sortedYears[entry.key] = entry.value;
      }
    }

    const yearColors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    if (sortedYears.isEmpty) {
      return const Text(
        'No year level records available.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: sortedYears.entries.toList().asMap().entries.map((item) {
        final index = item.key;
        final entry = item.value;

        final percentage = entry.value / documents.length;

        final color = yearColors[index % yearColors.length];

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
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value} Students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE8EDF4),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================
  // STUDENT CARD
  // =========================

  Widget buildStudentCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final name = (data['name'] ?? 'Unknown Student').toString();

    final studentNo =
        (data['student_no'] ?? 'No Student Number').toString();

    final course = (data['course'] ?? 'No Course').toString();

    final yearLevel = getYearLevel(data);

    final initials = name.trim().isEmpty
        ? '?'
        : name.trim().split(RegExp(r'\s+')).take(2).map(
              (part) => part[0].toUpperCase(),
            ).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEFF2F7),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: primaryColor.withOpacity(0.13),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF0EAD7D),
                fontWeight: FontWeight.bold,
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  studentNo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  course,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),

                const SizedBox(height: 7),

                // YEAR LEVEL LABEL
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    yearLevel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              confirmDeleteStudent(document.id, name);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 23,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // MAIN DASHBOARD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: studentStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              );
            }

            final documents = snapshot.data?.docs ?? [];

            // SEARCH BY NAME, STUDENT NUMBER, OR YEAR LEVEL
            final query = searchQuery.trim().toLowerCase();

            final filteredDocuments = documents.where((document) {
              final data = document.data();

              final name =
                  (data['name'] ?? '').toString().toLowerCase();

              final studentNo =
                  (data['student_no'] ?? '').toString().toLowerCase();

              final yearLevel =
                  getYearLevel(data).toLowerCase();

              return name.contains(query) ||
                  studentNo.contains(query) ||
                  yearLevel.contains(query);
            }).toList();

            // COUNT UNIQUE COURSES
            final courses = documents.map((document) {
              final course = (document.data()['course'] ?? '')
                  .toString()
                  .trim();

              return course.isEmpty
                  ? 'Unspecified Course'
                  : course;
            }).toSet();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // DASHBOARD HEADER WITH LOGOUT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage your student records',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      ElevatedButton.icon(
                        onPressed: logout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 18,
                        ),
                        label: const Text('Logout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // DASHBOARD STATISTICS
                  Row(
                    children: [
                      buildStatCard(
                        'Total Enrolled',
                        documents.length.toString(),
                        Icons.people_alt_rounded,
                        primaryColor,
                      ),
                      const SizedBox(width: 12),
                      buildStatCard(
                        'Total Courses',
                        courses.length.toString(),
                        Icons.menu_book_rounded,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      buildStatCard(
                        'Year Level',
                        courses.length.toString(),
                        Icons.calendar_month_outlined,
                        Colors.blue,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // STUDENT LIST HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Student List',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateStudent(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                        ),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // SEARCH BAR
                  buildSearchBar(),

                  const SizedBox(height: 18),

                  // STUDENT RECORDS
                  if (documents.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text(
                          'No student records yet.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else if (filteredDocuments.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: Text(
                          'No student found.',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredDocuments.map(
                      (document) => buildStudentCard(document),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
