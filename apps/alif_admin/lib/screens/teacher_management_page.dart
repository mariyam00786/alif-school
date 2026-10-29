import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../models/teacher.dart';
import '../services/batch_service.dart';
import '../services/teacher_service.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  late final TeacherListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TeacherListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTeacherDialog([Teacher? teacher]) {
    showDialog(
      context: context,
      builder: (context) => TeacherFormDialog(
        initialTeacher: teacher,
        onSuccess: () {
          _controller.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                teacher == null
                    ? 'Teacher added successfully'
                    : 'Teacher updated successfully',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text('Delete ${teacher.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await TeacherService.deleteTeacher(teacher.id);
      _controller.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting teacher: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Teacher Management',
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: '+ Add Teacher',
            expand: false,
            onPressed: _showTeacherDialog,
          ),
        ),
      ],
      body: TeacherListView(
        controller: _controller,
        onEdit: _showTeacherDialog,
        onDelete: _deleteTeacher,
      ),
    );
  }
}

class TeacherListController extends ChangeNotifier {
  List<Teacher> _data = [];
  bool _isLoading = false;
  String? _error;
  String _search = '';
  String _status = 'active';
  String? _selectedBatch;
  bool _isDisposed = false;

  List<Teacher> get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get status => _status;
  String? get selectedBatch => _selectedBatch;

  TeacherListController() {
    load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> load() async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      _data = await TeacherService.listTeachers(
        search: _search.isEmpty ? null : _search,
        status: _status,
        batchId: _selectedBatch,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setSearch(String value) {
    _search = value;
    load();
  }

  void setStatus(String value) {
    _status = value;
    load();
  }

  void setBatch(String? value) {
    _selectedBatch = value;
    load();
  }

  void refresh() {
    load();
  }
}

class TeacherListView extends StatefulWidget {
  const TeacherListView({
    super.key,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final TeacherListController controller;
  final ValueChanged<Teacher> onEdit;
  final ValueChanged<Teacher> onDelete;

  @override
  State<TeacherListView> createState() => _TeacherListViewState();
}

class _TeacherListViewState extends State<TeacherListView> {
  final _searchController = TextEditingController();
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _searchController.addListener(_onSearchChanged);
    _loadBatches();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  void _onSearchChanged() {
    widget.controller.setSearch(_searchController.text);
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await BatchService.listBatches(status: 'active');
      if (!mounted) {
        return;
      }
      setState(() => _batches = batches);
    } catch (_) {
      // Keep teacher list usable even if batches fail to load.
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachers = widget.controller.data;
    final selectedBatchName = _batches
        .where((batch) => batch.id == widget.controller.selectedBatch)
        .map((batch) => batch.name)
        .firstOrNull;

    return Column(
      children: [
        _TeacherSummaryStrip(
          total: teachers.length,
          activeCount: teachers.where((teacher) => teacher.status == 'active').length,
          selectedBatch: selectedBatchName,
          status: widget.controller.status,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AlifSpacing.md,
            0,
            AlifSpacing.md,
            AlifSpacing.md,
          ),
          child: AlifCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                if (compact) {
                  return Column(
                    children: [
                      _buildSearchField(),
                      const SizedBox(height: AlifSpacing.md),
                      _buildBatchDropdown(),
                      const SizedBox(height: AlifSpacing.md),
                      _buildStatusDropdown(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: AlifSpacing.md),
                    Expanded(child: _buildBatchDropdown()),
                    const SizedBox(width: AlifSpacing.md),
                    Expanded(child: _buildStatusDropdown()),
                  ],
                );
              },
            ),
          ),
        ),
        if (widget.controller.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (widget.controller.error != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AlifSpacing.md),
              child: AlifCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AlifColors.danger, size: 34),
                    const SizedBox(height: AlifSpacing.md),
                    Text(
                      'Could not load teachers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.xs),
                    Text(
                      widget.controller.error ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlifColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    FilledButton.tonalIcon(
                      onPressed: widget.controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (widget.controller.data.isEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AlifSpacing.md),
              child: AlifCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: AlifColors.neutral.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Text(
                      'No teachers found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.xs),
                    Text(
                      'Try changing filters or add a new teacher.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlifColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AlifSpacing.md),
              child: ListView.separated(
              itemCount: widget.controller.data.length,
              separatorBuilder: (_, _) => const SizedBox(height: AlifSpacing.md),
              itemBuilder: (context, index) {
                final teacher = widget.controller.data[index];
                return _TeacherCard(
                  teacher: teacher,
                  onEdit: () => widget.onEdit(teacher),
                  onDelete: () => widget.onDelete(teacher),
                );
              },
            ),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return AlifTextInput(
      label: 'Search teachers',
      hintText: 'By name, mobile or email...',
      controller: _searchController,
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String?>(
      initialValue: widget.controller.selectedBatch,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All Batches'),
        ),
        ..._batches.map(
          (batch) => DropdownMenuItem<String?>(
            value: batch.id,
            child: Text(batch.name),
          ),
        ),
      ],
      onChanged: widget.controller.setBatch,
      decoration: InputDecoration(
        labelText: 'Batch',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.controller.status,
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: (value) {
        if (value != null) {
          widget.controller.setStatus(value);
        }
      },
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _TeacherSummaryStrip extends StatelessWidget {
  const _TeacherSummaryStrip({
    required this.total,
    required this.activeCount,
    required this.selectedBatch,
    required this.status,
  });

  final int total;
  final int activeCount;
  final String? selectedBatch;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AlifSpacing.md),
      child: AlifCard(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(AlifSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AlifColors.secondary.withValues(alpha: 0.95),
                AlifColors.primary.withValues(alpha: 0.9),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            spacing: AlifSpacing.md,
            runSpacing: AlifSpacing.md,
            children: [
              _TeacherSummaryPill(label: 'Teachers', value: '$total'),
              _TeacherSummaryPill(label: 'Active', value: '$activeCount'),
              _TeacherSummaryPill(label: 'Status', value: status.toUpperCase()),
              _TeacherSummaryPill(label: 'Batch', value: selectedBatch ?? 'All'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherSummaryPill extends StatelessWidget {
  const _TeacherSummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlifSpacing.md,
        vertical: AlifSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({
    required this.teacher,
    required this.onEdit,
    required this.onDelete,
  });

  final Teacher teacher;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    return AlifCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AlifColors.secondaryContainer,
                ),
                child: Text(
                  _initials(teacher.fullName),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AlifColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AlifSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacher.fullName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      teacher.mobileNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AlifColors.textSecondary,
                          ),
                    ),
                    if ((teacher.email ?? '').isNotEmpty)
                      Text(
                        teacher.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                        if (compact) ...[
                          const SizedBox(height: AlifSpacing.sm),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AlifBadge(
                              label: teacher.status.toUpperCase(),
                              background: teacher.status == 'active'
                                  ? AlifColors.primary
                                  : AlifColors.neutral,
                            ),
                          ),
                        ],
                  ],
                ),
              ),
                  if (!compact) ...[
                    const SizedBox(width: AlifSpacing.md),
                    AlifBadge(
                      label: teacher.status.toUpperCase(),
                      background: teacher.status == 'active'
                          ? AlifColors.primary
                          : AlifColors.neutral,
                    ),
                  ],
            ],
          ),
          const SizedBox(height: AlifSpacing.md),
          Wrap(
            spacing: AlifSpacing.sm,
            runSpacing: AlifSpacing.sm,
            children: [
              if ((teacher.qualification ?? '').isNotEmpty)
                _TeacherMetaChip(
                  icon: Icons.verified_outlined,
                  text: teacher.qualification!,
                ),
              _TeacherMetaChip(
                icon: Icons.group_work_outlined,
                text: teacher.teacherBatches.isEmpty
                    ? 'No batches assigned'
                    : '${teacher.teacherBatches.length} batches assigned',
              ),
            ],
          ),
          if (teacher.teacherBatches.isNotEmpty) ...[
            const SizedBox(height: AlifSpacing.sm),
            Wrap(
              spacing: AlifSpacing.sm,
              runSpacing: AlifSpacing.sm,
              children: teacher.teacherBatches
                  .map(
                    (assignment) => AlifBadge(
                      label: assignment.batch.name,
                      background: AlifColors.secondary.withValues(alpha: 0.16),
                      foreground: AlifColors.secondary,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AlifSpacing.md),
          Wrap(
            spacing: AlifSpacing.md,
            runSpacing: AlifSpacing.sm,
            alignment: WrapAlignment.end,
            children: [
              FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
              FilledButton.tonal(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
                onPressed: onDelete,
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      return 'TR';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _TeacherMetaChip extends StatelessWidget {
  const _TeacherMetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AlifSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AlifColors.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AlifColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AlifColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class TeacherFormDialog extends StatefulWidget {
  const TeacherFormDialog({
    super.key,
    required this.onSuccess,
    this.initialTeacher,
  });

  final VoidCallback onSuccess;
  final Teacher? initialTeacher;

  @override
  State<TeacherFormDialog> createState() => _TeacherFormDialogState();
}

class _TeacherFormDialogState extends State<TeacherFormDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialTeacher?.fullName ?? '',
  );
  late final _mobileController = TextEditingController(
    text: widget.initialTeacher?.mobileNumber ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialTeacher?.email ?? '',
  );
  late final _qualificationController = TextEditingController(
    text: widget.initialTeacher?.qualification ?? '',
  );
  late String _status = widget.initialTeacher?.status ?? 'active';
  final Set<String> _selectedBatchIds = <String>{};
  List<Batch> _batches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBatchIds.addAll(widget.initialTeacher?.batchIds ?? const []);
    _loadBatches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _qualificationController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await BatchService.listBatches(status: 'active');
      setState(() => _batches = batches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading batches: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (widget.initialTeacher == null) {
        await TeacherService.createTeacher(
          fullName: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          qualification: _qualificationController.text.trim().isEmpty
              ? null
              : _qualificationController.text.trim(),
          status: _status,
          batchIds: _selectedBatchIds.toList(),
        );
      } else {
        await TeacherService.updateTeacher(
          widget.initialTeacher!.id,
          fullName: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          qualification: _qualificationController.text.trim().isEmpty
              ? null
              : _qualificationController.text.trim(),
          status: _status,
          batchIds: _selectedBatchIds.toList(),
        );
      }

      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTeacher == null ? 'Add Teacher' : 'Edit Teacher'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AlifSpacing.md,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Teacher Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _qualificationController,
                decoration: const InputDecoration(labelText: 'Qualification'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _status,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Assigned Batches',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Wrap(
                spacing: AlifSpacing.sm,
                runSpacing: AlifSpacing.sm,
                children: _batches
                    .map(
                      (batch) => FilterChip(
                        label: Text(batch.name),
                        selected: _selectedBatchIds.contains(batch.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBatchIds.add(batch.id);
                            } else {
                              _selectedBatchIds.remove(batch.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        AlifButton(
          label: 'Save',
          expand: false,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}