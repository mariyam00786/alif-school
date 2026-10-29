import 'package:flutter/material.dart';
import 'package:alif_design_system/alif_design_system.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alif_student_teacher/models/student.dart';
import 'package:alif_student_teacher/models/teacher_remark.dart';
import 'package:alif_student_teacher/services/api_service.dart';
import 'package:alif_student_teacher/services/auth_service.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = true;
  bool _isUploading = false;
  String? _error;
  StudentProfile? _profile;
  List<TeacherRemark> _teacherRemarks = const [];
  String? _remarksStudentId;
  DateTime? _remarksSeenAt;
  int _unreadRemarksCount = 0;
  List<Map<String, dynamic>> _notificationDevices = [];
  Map<String, bool> _devicePreferences = {};

  String _remarksSeenKey(String studentId) => 'remarks_seen_at_$studentId';

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  int _countUnreadRemarks(List<TeacherRemark> remarks, DateTime? seenAt) {
    if (seenAt == null) {
      return remarks.length;
    }

    return remarks.where((item) {
      final created = _tryParseDate(item.createdAt);
      if (created == null) {
        return false;
      }
      return created.isAfter(seenAt);
    }).length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

        final session = AuthService.currentSession;
        final linkedStudents = session?.user.role == 'parent'
          ? await ApiService.getLinkedStudents(parentPhone: session!.user.phone)
          : const <LinkedStudent>[];
        final studentId = linkedStudents.isNotEmpty
          ? linkedStudents.first.id
          : await ApiService.getFirstStudentId();
      final profile = await ApiService.getStudentProfile(studentId: studentId);
          final remarks = await ApiService.getTeacherRemarks(studentId: studentId, limit: 5);
      final devices = await ApiService.getNotificationDevices();
          final prefs = await SharedPreferences.getInstance();
          final seenRaw = prefs.getString(_remarksSeenKey(studentId));
          final seenAt = _tryParseDate(seenRaw);
          final unreadCount = _countUnreadRemarks(remarks, seenAt);

      if (!mounted) {
        return;
      }

      // Build device preferences map
      final preferences = <String, bool>{};
      for (final device in devices) {
        preferences[device['id'] as String] = device['notifications_enabled'] as bool? ?? true;
      }

      setState(() {
        _profile = profile;
        _teacherRemarks = remarks;
        _remarksStudentId = studentId;
        _remarksSeenAt = seenAt;
        _unreadRemarksCount = unreadCount;
        _notificationDevices = devices;
        _devicePreferences = preferences;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markRemarksAsRead() async {
    final studentId = _remarksStudentId;
    if (studentId == null) {
      return;
    }

    final newestCreatedAt = _teacherRemarks.isNotEmpty
        ? _tryParseDate(_teacherRemarks.first.createdAt)
        : DateTime.now().toUtc();
    final markAt = newestCreatedAt ?? DateTime.now().toUtc();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_remarksSeenKey(studentId), markAt.toIso8601String());

    if (!mounted) {
      return;
    }

    setState(() {
      _remarksSeenAt = markAt;
      _unreadRemarksCount = 0;
    });
  }

  Future<void> _toggleNotificationPreference(String deviceId, bool enabled) async {
    try {
      await ApiService.updateNotificationPreference(
        deviceId: deviceId,
        notificationsEnabled: enabled,
      );

      if (!mounted) return;

      setState(() {
        _devicePreferences[deviceId] = enabled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled ? 'Notifications enabled' : 'Notifications disabled'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (file == null) {
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _error = null;
      });

      final bytes = await file.readAsBytes();
      final extension = file.name.toLowerCase().endsWith('.png')
          ? 'png'
          : file.name.toLowerCase().endsWith('.webp')
              ? 'webp'
              : 'jpg';
      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final updated = await ApiService.uploadStudentProfilePhoto(
        studentId: profile.id,
        fileName: file.name,
        contentType: contentType,
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      setState(() => _profile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            AlifCard(
              child: Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else if (_profile != null)
            ...[
              AlifCard(
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AlifColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _profile!.profilePhotoUrl != null
                          ? Image.network(
                              _profile!.profilePhotoUrl!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.person,
                              size: 40,
                              color: AlifColors.primary,
                            ),
                    ),
                    const SizedBox(width: AlifSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _profile!.fatherName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Batch: ${_profile!.batchName}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            'Class: ${_profile!.className}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _isUploading ? null : _pickAndUploadPhoto,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined),
                      label: const Text('Photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    _buildProfileField('Father\'s Name', _profile!.fatherName),
                    _buildProfileField('Mother\'s Name', _profile!.motherName),
                    _buildProfileField('Date of Birth', _profile!.dateOfBirth),
                    _buildProfileField('Gender', _profile!.gender),
                    _buildProfileField('Address', _profile!.address),
                  ],
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Academic Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    _buildProfileField('Batch', _profile!.batchName),
                    _buildProfileField('Class', _profile!.className),
                  ],
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Teacher Remarks',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: AlifSpacing.sm),
                        if (_unreadRemarksCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AlifSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AlifColors.error,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_unreadRemarksCount new',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        const Spacer(),
                        if (_unreadRemarksCount > 0)
                          TextButton(
                            onPressed: _markRemarksAsRead,
                            child: const Text('Mark all as read'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    if (_teacherRemarks.isEmpty)
                      const Text('No teacher remarks yet.')
                    else
                      ..._teacherRemarks.map(
                        (item) {
                          final created = _tryParseDate(item.createdAt);
                          final isUnread = _remarksSeenAt == null
                              ? true
                              : (created?.isAfter(_remarksSeenAt!) ?? false);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AlifSpacing.md),
                              decoration: BoxDecoration(
                                color: isUnread
                                    ? AlifColors.primaryContainer
                                    : AlifColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(item.remark)),
                                      if (isUnread)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AlifSpacing.sm,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AlifColors.primary,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            'NEW',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: AlifSpacing.xs),
                                  Text(
                                    '${item.teacherName ?? 'Teacher'} • ${item.createdAt.split('T').first}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AlifColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Preferences',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    if (_notificationDevices.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AlifSpacing.md),
                        child: Text('No registered devices'),
                      )
                    else
                      Column(
                        children: _notificationDevices.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final device = entry.value;
                          final deviceId = device['id'] as String;
                          final platform = (device['platform'] as String?) ?? 'unknown';
                          final appName = (device['app_name'] as String?) ?? 'Unknown App';
                          final isEnabled = _devicePreferences[deviceId] ?? true;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: idx < _notificationDevices.length - 1
                                  ? AlifSpacing.md
                                  : 0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appName,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Text(
                                        platform.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AlifColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isEnabled,
                                  onChanged: (value) => _toggleNotificationPreference(
                                    deviceId,
                                    value,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ]
          else
            const AlifCard(child: Text('No profile data available')),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AlifSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AlifColors.textSecondary,
                ),
          ),
          const SizedBox(height: AlifSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
