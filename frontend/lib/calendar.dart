import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'components/class_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late Future<List<Map<String, dynamic>>> _classesFuture;
  bool _showRegisteredOnly = false;

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return _dateOnly(value);
    if (value is String) return _dateOnly(DateTime.parse(value));
    throw Exception('Unsupported date format: $value');
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(DateTime.now());
    _classesFuture = fetchClasses();
  }

  Future<List<Map<String, dynamic>>> fetchClasses() async {
    final response = await Supabase.instance.client.from('classes').select();
    final classList = List<Map<String, dynamic>>.from(response);
    
    // Deduplicate by class ID to prevent showing duplicate cards
    final Map<int, Map<String, dynamic>> uniqueClasses = {};
    for (var classItem in classList) {
      final classId = classItem['id'] as int;
      if (!uniqueClasses.containsKey(classId)) {
        uniqueClasses[classId] = classItem;
      }
    }
    
    return uniqueClasses.values.toList();
  }

  Future<List<Map<String, dynamic>>> fetchRegisteredClasses() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      print('❌ No logged-in user found.');
      return [];
    }

    print('🔍 Fetching registered classes for user: ${user.id}');

    try {
      // First, let's see ALL records in the table (debug)
      final allRecords = await supabase
          .from('student_classes')
          .select('*');
      print('📊 ALL records in student_classes (${allRecords.length} total): $allRecords');
      
      // Test with a simple query first
      final testResponse = await supabase
          .from('student_classes')
          .select('*')
          .eq('profile_id', user.id);
      
      print('🔎 Raw student_classes for user ${user.id}: $testResponse');
      
      if (testResponse.isEmpty) {
        print('📭 No registered classes found for ${user.id}');
        return [];
      }

      // Then do the join query
      final response = await supabase
          .from('student_classes')
          .select('classes(id, class_name, date, time)')
          .eq('profile_id', user.id);

      print('🔗 Join query response: $response');

      final classList = List<Map<String, dynamic>>.from(
        (response as List)
            .where((row) => row['classes'] != null)
            .map((row) => row['classes'] as Map<String, dynamic>)
            .toList(),
      );
      
      print('📋 Classes list after mapping: $classList');
      
      // Deduplicate by class ID to prevent showing duplicate cards
      final Map<int, Map<String, dynamic>> uniqueClasses = {};
      for (var classItem in classList) {
        final classId = classItem['id'] as int;
        if (!uniqueClasses.containsKey(classId)) {
          uniqueClasses[classId] = classItem;
        }
      }
      
      print('✅ Final unique classes (${uniqueClasses.length}): ${uniqueClasses.values.toList()}');
      
      return uniqueClasses.values.toList();
    } catch (e) {
      print('❌ Error in fetchRegisteredClasses: $e');
      return [];
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
    return Column(
      children: [
        // Switch toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Registered Only'),
              Switch(
                value: _showRegisteredOnly,
                onChanged: (value) {
                  setState(() {
                    _showRegisteredOnly = value;
                    _refreshClassList();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _classesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          // Group classes by date for TableCalendar's eventLoader
          final Map<DateTime, List<Map<String, dynamic>>> events = {};
          for (final item in items) {
            final dynamic rawDate = item['date'];
            try {
              final dayKey = _parseDate(rawDate);
              events.putIfAbsent(dayKey, () => []).add(item);
            } catch (_) {
              // Skip items with unparsable date
            }
          }

          List<Map<String, dynamic>> getEventsForDay(DateTime day) {
            final key = _dateOnly(day);
            return events[key] ?? [];
          }

          final selectedDay = _selectedDay ?? _dateOnly(DateTime.now());
          final selectedDayItems = getEventsForDay(selectedDay);

          return Column(
            children: [
              TableCalendar<Map<String, dynamic>>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: const {
                  CalendarFormat.week: 'Week',
                  CalendarFormat.twoWeeks: '2 Weeks',
                  CalendarFormat.month: 'Month',
                },
                headerStyle: const HeaderStyle(formatButtonVisible: true),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = _dateOnly(selected);
                    _focusedDay = focused;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
                eventLoader: (day) => getEventsForDay(day),
              ),
              const Divider(height: 1),
              Expanded(
                child: selectedDayItems.isEmpty
                    ? Center(
                        child: Text(
                          _showRegisteredOnly 
                              ? 'No registered classes on this day.'
                              : 'No classes on this day.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedDayItems.length,
                        itemBuilder: (context, index) {
                          final item = selectedDayItems[index];
                          return ClassCard( // made a component here to make it cleaner 
                            classData: item,
                            onRegistered: _refreshClassList,
                            isAlreadyRegistered: _showRegisteredOnly, // If showing registered only, user is definitely registered
                          );
                        },
                      ),
              ),
            ],
          );
        },
          ),
        ),
      ],
    );
  }
}
