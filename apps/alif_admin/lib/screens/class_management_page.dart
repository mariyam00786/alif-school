import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/batch_service.dart';
import '../services/class_service.dart';

class ClassManagementPage extends StatefulWidget {
  const ClassManagementPage({super.key});

  @override
  State<ClassManagementPage> createState() => _ClassManagementPageState();
}

class _ClassManagementPageState extends State<ClassManagementPage> {
  late final ClassListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ClassListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showClassDialog([Class? classItem]) {
    showDialog(
      context: context,
      builder: (context) => ClassFormDialog(
        initialClass: classItem,
        onSuccess: () {
          _controller.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                classItem == null
                    ? 'Class added successfully'
                    : 'Class updated successfully',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteClass(Class classItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text('Delete ${classItem.name}?'),
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
      await ClassService.deleteClass(classItem.id);
      _controller.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Class Management',
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: '+ Add Class',
            expand: false,
            onPressed: _showClassDialog,
          ),
        ),
      ],
      body: ClassListView(
        controller: _controller,
        onEdit: _showClassDialog,
        onDelete: _deleteClass,
      ),
    );
  }
}

class ClassListController extends ChangeNotifier {
  List<Class> _data = [];
  List<Batch> _batches = [];
  bool _isLoading = false;
  String? _error;
  String _status = 'active';
  String? _selectedBatch;
  bool _isDisposed = false;

  List<Class> get data => _data;
  List<Batch> get batches => _batches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get status => _status;
  String? get selectedBatch => _selectedBatch;

  ClassListController() {
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

      final results = await Future.wait([
        BatchService.listBatches(status: 'active'),
        ClassService.listClasses(batchId: _selectedBatch, status: _status),
      ]);

      _batches = results[0] as List<Batch>;
      _data = results[1] as List<Class>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setStatus(String value) {
    _status = value;
    load();
  }

  void setBatch(String? value) {
    _selectedBatch = value;
    load();
  }

  void refresh() => load();
}

class ClassListView extends StatefulWidget {
  const ClassListView({
    super.key,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassListController controller;
  final ValueChanged<Class> onEdit;
  final ValueChanged<Class> onDelete;

  @override
  State<ClassListView> createState() => _ClassListViewState();
}

class _ClassListViewState extends State<ClassListView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final classes = widget.controller.data;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifCard(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: widget.controller.selectedBatch,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Batches'),
                      ),
                      ...widget.controller.batches.map(
                        (batch) => DropdownMenuItem<String?>(
                          value: batch.id,
                          child: Text(batch.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => widget.controller.setBatch(value),
                    decoration: InputDecoration(
                      labelText: 'Batch',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AlifSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
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
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.controller.isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (widget.controller.error != null)
          Expanded(
            child: Center(
              child: Text(
                'Error: ${widget.controller.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          )
        else if (classes.isEmpty)
          const Expanded(
            child: Center(child: Text('No classes found')),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AlifSpacing.md),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                final classItem = classes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                  child: AlifCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classItem.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if ((classItem.nameMl ?? '').isNotEmpty)
                                Text(
                                  classItem.nameMl!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              const SizedBox(height: AlifSpacing.xs),
                              Text(
                                'Level: ${classItem.level ?? '-'} | Batch: ${classItem.batch?.name ?? classItem.batchId ?? '-'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        AlifBadge(
                          label: classItem.status.toUpperCase(),
                          background: classItem.status == 'active'
                              ? AlifColors.primary
                              : AlifColors.neutral,
                        ),
                        const SizedBox(width: AlifSpacing.md),
                        FilledButton.tonal(
                          onPressed: () => widget.onEdit(classItem),
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: AlifSpacing.sm),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                          ),
                          onPressed: () => widget.onDelete(classItem),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ClassFormDialog extends StatefulWidget {
  const ClassFormDialog({
    super.key,
    required this.onSuccess,
    this.initialClass,
  });

  final VoidCallback onSuccess;
  final Class? initialClass;

  @override
  State<ClassFormDialog> createState() => _ClassFormDialogState();
}

class _ClassFormDialogState extends State<ClassFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialClass?.name ?? '');
  late final _nameMlController = TextEditingController(text: widget.initialClass?.nameMl ?? '');
  late final _levelController = TextEditingController(text: widget.initialClass?.level ?? '');
  String? _batchId;
  String _status = 'active';
  bool _isLoading = false;
  List<Batch> _batches = [];

  @override
  void initState() {
    super.initState();
    _batchId = widget.initialClass?.batchId;
    _status = widget.initialClass?.status ?? 'active';
    _loadBatches();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameMlController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await BatchService.listBatches(status: 'active');
      if (!mounted) {
        return;
      }

      setState(() {
        _batches = batches;
        _batchId ??= batches.isNotEmpty ? batches.first.id : null;
      });
    } catch (_) {
      // Keep form usable if batch fetch fails.
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_batchId == null || _batchId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a batch')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (widget.initialClass == null) {
        await ClassService.createClass(
          name: _nameController.text.trim(),
          nameMl: _nameMlController.text.trim().isEmpty
              ? null
              : _nameMlController.text.trim(),
          level: _levelController.text.trim().isEmpty
              ? null
              : _levelController.text.trim(),
          batchId: _batchId!,
          status: _status,
        );
      } else {
        await ClassService.updateClass(
          widget.initialClass!.id,
          name: _nameController.text.trim(),
          nameMl: _nameMlController.text.trim().isEmpty
              ? null
              : _nameMlController.text.trim(),
          level: _levelController.text.trim().isEmpty
              ? null
              : _levelController.text.trim(),
          batchId: _batchId,
          status: _status,
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
      title: Text(widget.initialClass == null ? 'Add Class' : 'Edit Class'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Class Name'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _nameMlController,
                decoration: const InputDecoration(
                  labelText: 'Class Name (Malayalam)',
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(
                  labelText: 'Level (beginner/intermediate/advanced)',
                ),
              ),
              const SizedBox(height: AlifSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _batchId,
                items: _batches
                    .map(
                      (batch) => DropdownMenuItem<String>(
                        value: batch.id,
                        child: Text(batch.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _batchId = value),
                decoration: const InputDecoration(labelText: 'Batch'),
              ),
              const SizedBox(height: AlifSpacing.md),
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
