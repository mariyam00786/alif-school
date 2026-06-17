import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/student.dart';
import '../services/batch_service.dart';

class BatchManagementPage extends StatefulWidget {
  const BatchManagementPage({super.key});

  @override
  State<BatchManagementPage> createState() => _BatchManagementPageState();
}

class _BatchManagementPageState extends State<BatchManagementPage> {
  late final BatchListController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BatchListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showBatchDialog([Batch? batch]) {
    showDialog(
      context: context,
      builder: (context) => BatchFormDialog(
        initialBatch: batch,
        onSuccess: () {
          _controller.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                batch == null
                    ? 'Batch added successfully'
                    : 'Batch updated successfully',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteBatch(Batch batch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch'),
        content: Text('Delete ${batch.name}? Students linked to this batch will be unassigned in local mode.'),
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
      await BatchService.deleteBatch(batch.id);
      _controller.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting batch: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Batch Management',
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: '+ Add Batch',
            expand: false,
            onPressed: _showBatchDialog,
          ),
        ),
      ],
      body: BatchListView(
        controller: _controller,
        onEdit: _showBatchDialog,
        onDelete: _deleteBatch,
      ),
    );
  }
}

class BatchListController extends ChangeNotifier {
  List<Batch> _data = [];
  bool _isLoading = false;
  String? _error;
  String _status = 'active';
  bool _isDisposed = false;

  List<Batch> get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get status => _status;

  BatchListController() {
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

      _data = await BatchService.listBatches(status: _status);
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

  void refresh() {
    load();
  }
}

class BatchListView extends StatefulWidget {
  const BatchListView({
    super.key,
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  final BatchListController controller;
  final ValueChanged<Batch> onEdit;
  final ValueChanged<Batch> onDelete;

  @override
  State<BatchListView> createState() => _BatchListViewState();
}

class _BatchListViewState extends State<BatchListView> {
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
    final batches = widget.controller.data;
    final activeCount = batches.where((batch) => batch.status == 'active').length;

    return Column(
      children: [
        _BatchSummaryStrip(
          total: batches.length,
          activeCount: activeCount,
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
            child: Row(
              children: [
                Expanded(child: _buildStatusDropdown()),
              ],
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
                      'Could not load batches',
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
                      Icons.groups_2_outlined,
                      size: 48,
                      color: AlifColors.neutral.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Text(
                      'No batches found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.xs),
                    Text(
                      'Create a batch to organize students and teachers.',
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
                  final batch = widget.controller.data[index];
                  return _BatchCard(
                    batch: batch,
                    onEdit: () => widget.onEdit(batch),
                    onDelete: () => widget.onDelete(batch),
                  );
                },
              ),
            ),
          ),
      ],
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

class _BatchSummaryStrip extends StatelessWidget {
  const _BatchSummaryStrip({
    required this.total,
    required this.activeCount,
    required this.status,
  });

  final int total;
  final int activeCount;
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
                AlifColors.primary.withValues(alpha: 0.95),
                AlifColors.secondary.withValues(alpha: 0.9),
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
              _BatchSummaryPill(label: 'Batches', value: '$total'),
              _BatchSummaryPill(label: 'Active', value: '$activeCount'),
              _BatchSummaryPill(label: 'Status', value: status.toUpperCase()),
            ],
          ),
        ),
      ),
    );
  }
}

class _BatchSummaryPill extends StatelessWidget {
  const _BatchSummaryPill({required this.label, required this.value});

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

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onEdit,
    required this.onDelete,
  });

  final Batch batch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                  color: AlifColors.primaryContainer,
                ),
                child: Text(
                  _initials(batch.name),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AlifColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: AlifSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.name, style: Theme.of(context).textTheme.titleLarge),
                    if ((batch.nameMl ?? '').isNotEmpty)
                      Text(
                        batch.nameMl!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AlifColors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AlifSpacing.md),
              AlifBadge(
                label: batch.status.toUpperCase(),
                background: batch.status == 'active' ? AlifColors.primary : AlifColors.neutral,
              ),
            ],
          ),
          const SizedBox(height: AlifSpacing.md),
          if ((batch.description ?? '').isNotEmpty)
            Text(
              batch.description!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if ((batch.description ?? '').isNotEmpty)
            const SizedBox(height: AlifSpacing.sm),
          Wrap(
            spacing: AlifSpacing.sm,
            runSpacing: AlifSpacing.sm,
            children: [
              _BatchMetaChip(
                icon: Icons.people_outline,
                text: 'Capacity: ${batch.capacity?.toString() ?? '-'}',
              ),
              _BatchMetaChip(
                icon: Icons.schedule,
                text: 'Timing: ${batch.timing ?? '-'}',
              ),
            ],
          ),
          const SizedBox(height: AlifSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonal(onPressed: onEdit, child: const Text('Edit')),
              const SizedBox(width: AlifSpacing.md),
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
      return 'BA';
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _BatchMetaChip extends StatelessWidget {
  const _BatchMetaChip({required this.icon, required this.text});

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

class BatchFormDialog extends StatefulWidget {
  const BatchFormDialog({
    super.key,
    required this.onSuccess,
    this.initialBatch,
  });

  final VoidCallback onSuccess;
  final Batch? initialBatch;

  @override
  State<BatchFormDialog> createState() => _BatchFormDialogState();
}

class _BatchFormDialogState extends State<BatchFormDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.initialBatch?.name ?? '');
  late final _nameMlController = TextEditingController(text: widget.initialBatch?.nameMl ?? '');
  late final _descriptionController = TextEditingController(text: widget.initialBatch?.description ?? '');
  late final _capacityController = TextEditingController(
    text: widget.initialBatch?.capacity?.toString() ?? '',
  );
  late final _timingController = TextEditingController(text: widget.initialBatch?.timing ?? '');
  late String _status = widget.initialBatch?.status ?? 'active';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nameMlController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _timingController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final capacity = _capacityController.text.trim().isEmpty
          ? null
          : int.parse(_capacityController.text.trim());

      if (widget.initialBatch == null) {
        await BatchService.createBatch(
          name: _nameController.text.trim(),
          nameMl: _nameMlController.text.trim().isEmpty ? null : _nameMlController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          capacity: capacity,
          timing: _timingController.text.trim().isEmpty ? null : _timingController.text.trim(),
          status: _status,
        );
      } else {
        await BatchService.updateBatch(
          widget.initialBatch!.id,
          name: _nameController.text.trim(),
          nameMl: _nameMlController.text.trim().isEmpty ? null : _nameMlController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          capacity: capacity,
          timing: _timingController.text.trim().isEmpty ? null : _timingController.text.trim(),
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
      title: Text(widget.initialBatch == null ? 'Add Batch' : 'Edit Batch'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AlifSpacing.md,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Batch Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _nameMlController,
                decoration: const InputDecoration(labelText: 'Batch Name (Malayalam)'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _timingController,
                decoration: const InputDecoration(labelText: 'Timing'),
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