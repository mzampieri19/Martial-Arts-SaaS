import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

Future<List<Map<String, dynamic>>> fetchItems() async {
      final response = await Supabase.instance.client
          .from('classes')
          .select();
      return response;
    }

class _CalendarPageState extends State<CalendarPage> {

  late Future<List<Map<String, dynamic>>> _itemsFuture;

      @override
      void initState() {
        super.initState();
        _itemsFuture = fetchItems(); // Call the function to fetch data
      }


  @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: const Text('Classes')),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No items found.'));
              } else {
                final items = snapshot.data!;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item['class_name']), 
                      subtitle: Text(item['date']),
                      trailing: Text(item['time']),
                    );
                  },
                );
              }
            },
          ),
        );
      }
}
