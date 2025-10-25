import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Automatically select the correct URL based on platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    
    // For physical devices, replace with your Mac's IP (e.g., '192.168.1.45')
    // Uncomment and set your IP when testing on a real device:
    // return 'http://192.168.1.XXX:3000/api';
    
    if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 to reach host machine
      return 'http://10.0.2.2:3000/api';
    }
    
    // iOS simulator and macOS can use localhost
    return 'http://localhost:3000/api';
  }
  
  // Helper method for GET requests
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for GET requests that return lists
  static Future<List<dynamic>> getList(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for POST requests
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to complete request');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for PUT requests
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to update: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method for DELETE requests
  static Future<void> delete(String endpoint) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return post('/auth/login', {'email': email, 'password': password});
  }

  static Future<Map<String, dynamic>> signup(
    String email,
    String password,
    String username,
  ) async {
    return post('/auth/signup', {
      'email': email,
      'password': password,
      'username': username,
    });
  }

  // Class endpoints
  static Future<List<dynamic>> getClasses() async {
    return getList('/classes');
  }

  static Future<Map<String, dynamic>> getClass(String id) async {
    return get('/classes/$id');
  }

  static Future<Map<String, dynamic>> createClass(Map<String, dynamic> classData) async {
    return post('/classes', classData);
  }

  static Future<Map<String, dynamic>> updateClass(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return put('/classes/$id', updates);
  }

  static Future<void> deleteClass(String id) async {
    return delete('/classes/$id');
  }

  // Student class endpoints
  static Future<List<dynamic>> getStudentClasses(String userId) async {
    return getList('/student-classes?user_id=$userId');
  }

  static Future<Map<String, dynamic>> registerForClass(
    String userId,
    int classId,
  ) async {
    return post('/student-classes', {
      'profile_id': userId,
      'class_id': classId,
    });
  }

  // Goal endpoints
  static Future<List<dynamic>> getGoals() async {
    return getList('/goals');
  }

  static Future<List<dynamic>> getClassGoalLinks(String classId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/class-goal-links/$classId'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load class goal links: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Profile endpoints
  static Future<Map<String, dynamic>> getProfile(String id) async {
    return get('/profiles/$id');
  }

  static Future<Map<String, dynamic>> updateProfile(
    String id,
    Map<String, dynamic> updates,
  ) async {
    return put('/profiles/$id', updates);
  }

  // User progress endpoints
  static Future<Map<String, dynamic>> getUserProgress(String userId) async {
    return get('/user-progress/$userId');
  }

  static Future<Map<String, dynamic>> toggleMark(
    String userId,
    int goalId,
    int classId,
    bool mark,
  ) async {
    return post('/toggle-mark', {
      'userId': userId,
      'goalId': goalId,
      'classId': classId,
      'mark': mark,
    });
  }

  // Coach endpoints
  static Future<List<dynamic>> getCoaches() async {
    return getList('/coaches');
  }
}
