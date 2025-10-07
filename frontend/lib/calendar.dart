import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<List<Map<String, dynamic>>> _classesFuture;
  bool _showRegisteredOnly = false;

  @override
  void initState() {
    super.initState();
    _classesFuture = fetchClasses();
  }

  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final response = await Supabase.instance.client.from('classes').select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchRegisteredClasses() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('No logged-in user found.');
      return [];
    }

    print('Debug - User ID: ${user.id}');
    print('Debug - User ID type: ${user.id.runtimeType}');

    try {
      // First, let's see ALL records in the table (debug)
      final allRecords = await supabase
          .from('student_classes')
          .select('*');
      print('Debug - ALL records in student_classes: $allRecords');
      
      // Test with a simple query first
      final testResponse = await supabase
          .from('student_classes')
          .select('*')
          .eq('profile_id', user.id);
      
      print('Debug - Raw response for user ${user.id}: $testResponse');
      
      if (testResponse.isEmpty) {
        print('📭 No registered classes found for ${user.id}');
        return [];
      }

      // Then do the join query
      final response = await supabase
          .from('student_classes')
          .select('classes(id, class_name, date, time)')
          .eq('profile_id', user.id);

      return List<Map<String, dynamic>>.from(
        (response as List)
            .map((row) => row['classes'] as Map<String, dynamic>)
            .toList(),
      );
    } catch (e) {
      print('Error in fetchRegisteredClasses: $e');
      return [];
    }
  }

  Future<void> registerForClass(int classId) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    final String userId = user!.id;


    
    try {
      await supabase.from('student_classes').insert({
        'profile_id': userId,
        'class_id': classId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully registered!')),
      );

      if (_showRegisteredOnly) {
        setState(() => _classesFuture = fetchRegisteredClasses());
      }
    } catch (e) {
      final error = e.toString();
      if (error.contains('duplicate key value')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already registered for this class!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering: $error')),
        );
      }
    }
  }

  void _refreshClassList() {
    setState(() {
      _classesFuture = _showRegisteredOnly
          ? fetchRegisteredClasses()
          : fetchClasses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Calendar'),
        actions: [
          Row(
            children: [
              const Text('Registered Only'),
              Checkbox(
                value: _showRegisteredOnly,
                onChanged: (value) {
                  setState(() {
                    _showRegisteredOnly = value ?? false;
                    _refreshClassList();
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No classes found.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final className = item['class_name'] ?? 'Unnamed class';
              final classDate = item['date'] ?? '';
              final classTime = item['time'] ?? '';
              final classId = item['id'];

              return Slidable(
                key: ValueKey(classId),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) async => await registerForClass(classId),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      icon: Icons.check_circle,
                      label: 'Register',
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    className,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Date: $classDate\nTime: $classTime'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
