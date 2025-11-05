import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_constants.dart';
import 'components/qr_code_display.dart';

/// Page for coaches/owners to view classes and display QR codes for check-in
class ViewClassQRCodesPage extends StatefulWidget {
  const ViewClassQRCodesPage({super.key});

  @override
  State<ViewClassQRCodesPage> createState() => _ViewClassQRCodesPageState();
}

class _ViewClassQRCodesPageState extends State<ViewClassQRCodesPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  /// Load classes - filters by role (coaches see only their assigned classes)
  Future<void> _loadClasses() async {
    try {
      setState(() => _isLoading = true);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view classes')),
        );
        return;
      }

      final profileResp = await _supabase
          .from('profiles')
          .select('Role, username')
          .eq('id', user.id)
          .maybeSingle();

      final role = profileResp?['Role']?.toString().toLowerCase();
      final username = profileResp?['username']?.toString() ?? '';

      List<Map<String, dynamic>> list;

      if (role == 'coach' && username.isNotEmpty) {
        // Coach: only show classes where coach_assigned matches their username
        final response = await _supabase
            .from('classes')
            .select('*, join_token')
            .order('class_name', ascending: true);
        final allClasses = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);

        // Filter to only classes where coach_assigned matches username
        list = allClasses.where((classItem) {
          final coachAssigned = classItem['coach_assigned']?.toString().trim() ?? '';
          return coachAssigned.toLowerCase() == username.toLowerCase().trim();
        }).toList();
      } else {
        // Owner or other roles: show all classes
        final response = await _supabase
            .from('classes')
            .select('*, join_token')
            .order('class_name', ascending: true);
        list = List<Map<String, dynamic>>.from(response as List<dynamic>? ?? []);
      }

      setState(() {
        _classes = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading classes: $e')),
      );
    }
  }

  /// Show QR code dialog for a specific class
  void _showQRCodeDialog(Map<String, dynamic> classItem) {
    final joinToken = classItem['join_token']?.toString();
    final className = classItem['class_name']?.toString() ?? 'Unknown Class';

    if (joinToken == null || joinToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This class does not have a QR code available')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Display this QR code for students to scan',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // QR Code Display
                QRCodeDisplay(
                  joinToken: joinToken,
                  className: className,
                  size: 280,
                ),
                const SizedBox(height: 24),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Class QR Codes'),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _classes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No classes found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a class to generate QR codes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClasses,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final classItem = _classes[index];
                      final className = classItem['class_name']?.toString() ?? 'Unknown Class';
                      final date = classItem['date']?.toString() ?? '';
                      final time = classItem['time']?.toString() ?? '';
                      final coachAssigned = classItem['coach_assigned']?.toString() ?? '';
                      final hasQRCode = classItem['join_token'] != null &&
                          classItem['join_token'].toString().isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              color: AppConstants.accentColor,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            className,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (date.isNotEmpty || time.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [date, time].where((s) => s.isNotEmpty).join(' • '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                              if (coachAssigned.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Coach: $coachAssigned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                          onTap: hasQRCode
                              ? () => _showQRCodeDialog(classItem)
                              : null,
                          enabled: hasQRCode,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
