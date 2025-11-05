import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassCard extends StatelessWidget {
  final Map<String, dynamic> classData;
  final VoidCallback onRegistered;
  final bool isAlreadyRegistered;

  const ClassCard({
    super.key,
    required this.classData,
    required this.onRegistered,
    this.isAlreadyRegistered = false, // Default to false if not provided
  });

  Future<Map<String, dynamic>> _fetchClassDetails() async {
    final supabase = Supabase.instance.client;
    final classId = classData['id'];
    final currentUser = supabase.auth.currentUser;

    print('🔍 Fetching details for class $classId, current user: ${currentUser?.id}');

    try {
      // Fetch current user's role
      String? userRole;
      if (currentUser != null) {
        try {
          final userProfile = await supabase
              .from('profiles')
              .select('Role')
              .eq('id', currentUser.id)
              .single();
          userRole = userProfile['Role'] as String?;
          print('👤 Current user role: "$userRole" (type: ${userRole.runtimeType})');
          print('🔍 Role comparison: coach=${userRole == 'coach'}, owner=${userRole == 'owner'}');
        } catch (e) {
          print('⚠️ Could not fetch user role: $e');
        }
      }

      // Only fetch participants if user is coach or owner
      // Check with case-insensitive comparison and trim whitespace
      final canViewParticipants = userRole?.trim().toLowerCase() == 'coach' || 
                                   userRole?.trim().toLowerCase() == 'owner';
      print('🔐 Can view participants: $canViewParticipants (userRole: "$userRole")');

      // Always check if current user is registered (for all roles)
      // If isAlreadyRegistered is true (from registered-only filter), skip the query
      bool isRegistered = isAlreadyRegistered;
      
      if (!isAlreadyRegistered && currentUser != null) {
        try {
          final userRegistration = await supabase
              .from('student_classes')
              .select('id')
              .eq('class_id', classId)
              .eq('profile_id', currentUser.id)
              .maybeSingle();
          
          isRegistered = userRegistration != null;
          print('🎫 Is user ${currentUser.id} registered? $isRegistered');
        } catch (e) {
          print('⚠️ Could not check registration status: $e');
        }
      } else if (isAlreadyRegistered) {
        print('🎫 User is registered (from registered-only filter)');
      }

      List<Map<String, dynamic>> participants = [];

      if (canViewParticipants) {
        // Fetch participants - just get profile_id first to avoid column errors
        print('🔍 Fetching ALL participants for class $classId...');
        
        final participantsResponse = await supabase
            .from('student_classes')
            .select('profile_id')
            .eq('class_id', classId);

        print('👥 Participants response for class $classId (${(participantsResponse as List).length} rows): $participantsResponse');

        // Parse participants and fetch their profile details
        for (var row in (participantsResponse as List)) {
          final profileId = row['profile_id'] as String?;
          if (profileId != null) {
            try {
              final profileData = await supabase
                  .from('profiles')
                  .select('username, avatar_url, id')
                  .eq('id', profileId)
                  .single();
              
              print('👤 Profile data for $profileId: $profileData');
              
              final avatarPath = profileData['avatar_url'] as String?;
              final avatarUrl = (avatarPath != null && avatarPath.isNotEmpty)
                  ? supabase.storage.from('avatars').getPublicUrl(avatarPath)
                  : 'https://i.postimg.cc/cCsYDjvj/user-2.png';
              
              participants.add({
                'id': profileData['id'],
                'username': profileData['username'],
                'avatar_url': avatarUrl,
              });
            } catch (e) {
              print('⚠️ Could not fetch profile for $profileId: $e');
              // Add a placeholder if we can't fetch the profile
              participants.add({
                'id': profileId,
                'username': 'Unknown User',
                'avatar_url': 'https://i.postimg.cc/cCsYDjvj/user-2.png',
              });
            }
          }
        }
        
        print('✅ Parsed participants (${participants.length}): $participants');
      }

      // Fetch coach information
      final coachId = classData['coach_id'];
      Map<String, dynamic>? coach;
      
      if (coachId != null) {
        try {
          final coachResponse = await supabase
              .from('profiles')
              .select('username, avatar_url')
              .eq('id', coachId)
              .single();
          
          coach = coachResponse;
        } catch (e) {
          print('⚠️ Could not fetch coach info: $e');
        }
      }

      return {
        'participants': participants,
        'coach': coach,
        'isRegistered': isRegistered,
        'canViewParticipants': canViewParticipants,
      };
    } catch (e) {
      print('❌ Error fetching class details: $e');
      return {
        'participants': [],
        'coach': null,
        'isRegistered': false,
      };
    }
  }

  void _showClassDetailsDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchClassDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

              final details = snapshot.data ?? {};
              final participants = details['participants'] as List<Map<String, dynamic>>? ?? [];
              final coach = details['coach'] as Map<String, dynamic>?;
              final isRegistered = details['isRegistered'] as bool? ?? false;
              final canViewParticipants = details['canViewParticipants'] as bool? ?? false;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with close button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              classData['class_name'] ?? 'Unnamed Class',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date and Time
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date',
                        classData['date']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.access_time,
                        'Time',
                        classData['time']?.toString() ?? 'N/A',
                      ),
                      const SizedBox(height: 12),

                      // Coach Information
                      if (coach != null) ...[
                        _buildInfoRow(
                          Icons.person,
                          'Coach',
                          coach['username']?.toString() ?? 'Unknown Coach',
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Participants Section - Only show for coaches and owners
                      if (canViewParticipants) ...[
                        const Divider(),
                        const SizedBox(height: 16),

                        // Participants Section
                        Row(
                          children: [
                            const Icon(Icons.group, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Participants (${participants.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Participants List
                        if (participants.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No participants yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: participants.length,
                              itemBuilder: (context, index) {
                                final participant = participants[index];
                                final username = participant['username']?.toString() ?? 'Unknown User';
                                final avatarUrl = participant['avatar_url']?.toString() ?? 
                                    'https://i.postimg.cc/cCsYDjvj/user-2.png';
                                
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: NetworkImage(avatarUrl),
                                    onBackgroundImageError: (exception, stackTrace) {
                                      // If image fails to load, it will show the grey background
                                    },
                                  ),
                                  title: Text(username),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),
                      ] else ...[
                        // For students, just add spacing without the participants section
                        const SizedBox(height: 24),
                      ],

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isRegistered ? null : () async {
                            await _registerForClass(context, setDialogState);
                          },
                          icon: Icon(isRegistered ? Icons.check_circle_outline : Icons.check_circle),
                          label: Text(isRegistered ? 'Already Registered' : 'Register for Class'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: isRegistered ? Colors.grey : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _registerForClass(BuildContext context, StateSetter setDialogState) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to register')),
        );
      }
      return;
    }

    try {
      print('🔵 Registering user ${user.id} for class ${classData['id']}');
      
      final response = await supabase.from('student_classes').insert({
        'profile_id': user.id,
        'class_id': classData['id'],
      }).select();
      
      print('✅ Registration successful! Response: $response');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully registered!')),
        );
        
        // Wait a moment for the database to update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Refresh the dialog to show updated participants list
        setDialogState(() {});
        
        // Refresh the calendar list
        onRegistered();
      }
    } catch (e) {
      print('❌ Registration error: $e');
      if (context.mounted) {
        final error = e.toString();
        String message = 'Error registering: $error';
        
        if (error.contains('duplicate key value')) {
          message = 'You are already registered for this class!';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final className = classData['class_name'] ?? 'Unnamed class';
    final classDate = classData['date'] ?? '';
    final classTime = classData['time'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showClassDetailsDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(
              className,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Date: $classDate\nTime: $classTime'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ),
      ),
    );
  }
}

