import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'firebase_options.dart'; // මේ විදියට තියෙන්න ඕනේ

// මචං මේක ඔයාගේ Main App එක
void main() async {
  // Firebase Initialize කරන්න මේ පේළි ටික අනිවාර්යයි
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF09090B),
    ),
    home: StudyDashboard(),
  ));
}

class StudyDashboard extends StatefulWidget {
  @override
  _StudyDashboardState createState() => _StudyDashboardState();
}

class _StudyDashboardState extends State<StudyDashboard> {
  final TextEditingController _taskController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Realtime එකේ Task එකක් සේව් කරන ෆන්ක්ෂන් එක
  Future<void> _addTask() async {
    if (_taskController.text.isNotEmpty) {
      await _firestore.collection('study_tasks').add({
        'title': _taskController.text,
        'isDone': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _taskController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Dashboard Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("MY STUDY HUB",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child:
                      Icon(Icons.auto_stories, size: 80, color: Colors.white24),
                ),
              ),
            ),
          ),

          // Planner Input Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Quick Add Task",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: "What's the next goal?",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send_rounded,
                            color: Color(0xFFA855F7)),
                        onPressed: _addTask,
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Realtime Task List (Firebase Stream)
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('study_tasks')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()));

              var docs = snapshot.data!.docs;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        leading: Checkbox(
                          value: data['isDone'],
                          activeColor: const Color(0xFF6366F1),
                          onChanged: (val) {
                            _firestore
                                .collection('study_tasks')
                                .doc(docs[index].id)
                                .update({'isDone': val});
                          },
                        ),
                        title: Text(data['title'],
                            style: TextStyle(
                              decoration: data['isDone']
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: data['isDone']
                                  ? Colors.white38
                                  : Colors.white,
                            )),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () => _firestore
                              .collection('study_tasks')
                              .doc(docs[index].id)
                              .delete(),
                        ),
                      ),
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),
        ],
      ),

      // Floating Timer Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // මෙතනට ඔයාගේ අර කලින් හදපු Timer Page එකට Navigate කරන්න පුළුවන්
        },
        label: const Text("FOCUS TIMER"),
        icon: const Icon(Icons.timer),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }
}
