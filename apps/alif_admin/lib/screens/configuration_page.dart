import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../models/category.dart';
import '../models/rating.dart';
import '../services/activity_service.dart';
import '../services/category_service.dart';
import '../services/rating_service.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  late final CategoryListController _controller;
  ActivityCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _controller = CategoryListController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCategoryDialog([ActivityCategory? category]) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        initialCategory: category,
        onSuccess: () {
          _controller.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                category == null
                    ? 'Category added successfully'
                    : 'Category updated successfully',
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteCategory(ActivityCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete ${category.name}?'),
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
      await CategoryService.deleteCategory(category.id);
      _controller.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: 'Configuration',
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: '+ Add Category',
            expand: false,
            onPressed: _showCategoryDialog,
          ),
        ),
      ],
      body: CategoryListView(
        controller: _controller,
        selectedCategoryId: _selectedCategory?.id,
        onSelect: (category) => setState(() => _selectedCategory = category),
        onEdit: _showCategoryDialog,
        onDelete: _deleteCategory,
      ),
    );
  }
}

class CategoryListController extends ChangeNotifier {
  CategoryListController() {
    load();
  }

  List<ActivityCategory> _data = [];
  bool _isLoading = false;
  String? _error;
  String _status = 'active';
  bool _isDisposed = false;

  List<ActivityCategory> get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get status => _status;

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
      _data = await CategoryService.listCategories(status: _status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setStatus(String status) {
    _status = status;
    load();
  }

  void refresh() => load();
}

class CategoryListView extends StatefulWidget {
  const CategoryListView({
    super.key,
    required this.controller,
    required this.selectedCategoryId,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryListController controller;
  final String? selectedCategoryId;
  final ValueChanged<ActivityCategory> onSelect;
  final ValueChanged<ActivityCategory> onEdit;
  final ValueChanged<ActivityCategory> onDelete;

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant CategoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  ActivityCategory? _selectedCategory() {
    for (final category in widget.controller.data) {
      if (category.id == widget.selectedCategoryId) {
        return category;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.data;
    final activeCount = categories.where((category) => category.status == 'active').length;

    return ListView(
      padding: const EdgeInsets.all(AlifSpacing.md),
      children: [
        _ConfigSummaryStrip(
          total: categories.length,
          activeCount: activeCount,
          status: widget.controller.status,
        ),
        const SizedBox(height: AlifSpacing.md),
        AlifCard(
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
              labelText: 'Category Status',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: AlifSpacing.md),
        if (widget.controller.data.isNotEmpty)
          ActivityManagementSection(
            categories: widget.controller.data,
            selectedCategory: _selectedCategory(),
            onSelectCategory: widget.onSelect,
          ),
        const SizedBox(height: AlifSpacing.md),
        if (widget.controller.isLoading)
          const Padding(
            padding: EdgeInsets.all(AlifSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.controller.error != null)
          AlifCard(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: AlifColors.danger, size: 30),
                const SizedBox(height: AlifSpacing.sm),
                Text(
                  widget.controller.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          )
        else
          ...widget.controller.data.map(
            (category) => Padding(
              padding: const EdgeInsets.only(bottom: AlifSpacing.md),
              child: AlifCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name, style: Theme.of(context).textTheme.titleLarge),
                              if ((category.nameMl ?? '').isNotEmpty)
                                Text(
                                  category.nameMl!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AlifColors.textSecondary,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        AlifBadge(
                          label: category.status.toUpperCase(),
                          background: category.status == 'active'
                              ? AlifColors.primary
                              : AlifColors.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AlifSpacing.sm),
                    Wrap(
                      spacing: AlifSpacing.sm,
                      runSpacing: AlifSpacing.sm,
                      children: [
                        _ConfigMetaChip(
                          icon: Icons.grid_view_rounded,
                          text: 'Order: ${category.displayOrder}',
                        ),
                        _ConfigMetaChip(
                          icon: Icons.tag,
                          text: 'Icon: ${category.icon ?? '-'}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Wrap(
                      spacing: AlifSpacing.sm,
                      runSpacing: AlifSpacing.sm,
                      alignment: WrapAlignment.end,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => widget.onSelect(category),
                          child: Text(
                            widget.selectedCategoryId == category.id
                                ? 'Selected'
                                : 'Manage Activities',
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: () => widget.onEdit(category),
                          child: const Text('Edit'),
                        ),
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
                          onPressed: () => widget.onDelete(category),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfigSummaryStrip extends StatelessWidget {
  const _ConfigSummaryStrip({
    required this.total,
    required this.activeCount,
    required this.status,
  });

  final int total;
  final int activeCount;
  final String status;

  @override
  Widget build(BuildContext context) {
    return AlifCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AlifSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AlifColors.primary.withValues(alpha: 0.95),
              AlifColors.accent.withValues(alpha: 0.9),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Wrap(
          spacing: AlifSpacing.md,
          runSpacing: AlifSpacing.sm,
          children: [
            _ConfigSummaryPill(label: 'Categories', value: '$total'),
            _ConfigSummaryPill(label: 'Active', value: '$activeCount'),
            _ConfigSummaryPill(label: 'Status', value: status.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

class _ConfigSummaryPill extends StatelessWidget {
  const _ConfigSummaryPill({required this.label, required this.value});

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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ConfigMetaChip extends StatelessWidget {
  const _ConfigMetaChip({required this.icon, required this.text});

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

class ActivityManagementSection extends StatefulWidget {
  const ActivityManagementSection({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  final List<ActivityCategory> categories;
  final ActivityCategory? selectedCategory;
  final ValueChanged<ActivityCategory> onSelectCategory;

  @override
  State<ActivityManagementSection> createState() => _ActivityManagementSectionState();
}

class _ActivityManagementSectionState extends State<ActivityManagementSection> {
  late ActivityListController _controller;
  ActivityItem? _selectedActivity;

  Future<void> _deleteActivity(ActivityItem activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Delete ${activity.name}?'),
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
      await ActivityService.deleteActivity(activity.id);
      if (_selectedActivity?.id == activity.id) {
        setState(() => _selectedActivity = null);
      }
      _controller.refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting activity: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ActivityListController(selectedCategoryId: widget.selectedCategory?.id);
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant ActivityManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCategory?.id != oldWidget.selectedCategory?.id) {
      _selectedActivity = null;
      _controller.setCategory(widget.selectedCategory?.id);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.selectedCategory == null
                ? 'Select a category above to manage activities.'
                : 'Managing activities for ${widget.selectedCategory!.name}',
          ),
          const SizedBox(height: AlifSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: widget.selectedCategory?.id,
            items: widget.categories
                .map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                widget.onSelectCategory(widget.categories.firstWhere((c) => c.id == value));
              }
            },
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (widget.selectedCategory != null)
            AlifButton(
              label: '+ Add Activity',
              expand: false,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ActivityFormDialog(
                    category: widget.selectedCategory!,
                    onSuccess: _controller.refresh,
                  ),
                );
              },
            ),
          const SizedBox(height: AlifSpacing.md),
          if (_controller.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_controller.error != null)
            Text('Error: ${_controller.error}', style: const TextStyle(color: Colors.red))
          else
            ..._controller.data.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.sm),
                child: AlifCard(
                  child: Row(
                    children: [
                      Expanded(child: Text(activity.name)),
                      FilledButton.tonal(
                        onPressed: () => setState(() => _selectedActivity = activity),
                        child: Text(
                          _selectedActivity?.id == activity.id ? 'Selected' : 'Manage Ratings',
                        ),
                      ),
                      const SizedBox(width: AlifSpacing.sm),
                      FilledButton.tonal(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => ActivityFormDialog(
                              category: widget.selectedCategory!,
                              initialActivity: activity,
                              onSuccess: _controller.refresh,
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: AlifSpacing.sm),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
                        onPressed: () => _deleteActivity(activity),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AlifSpacing.md),
          RatingManagementSection(selectedActivity: _selectedActivity),
        ],
      ),
    );
  }
}

class ActivityListController extends ChangeNotifier {
  ActivityListController({required this.selectedCategoryId}) {
    load();
  }

  String? selectedCategoryId;
  List<ActivityItem> data = [];
  bool isLoading = false;
  String? error;
  bool _isDisposed = false;

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
    if (selectedCategoryId == null) {
      data = [];
      _safeNotify();
      return;
    }
    try {
      isLoading = true;
      error = null;
      _safeNotify();
      data = await ActivityService.listActivities(categoryId: selectedCategoryId, status: 'active');
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  void refresh() => load();

  void setCategory(String? categoryId) {
    selectedCategoryId = categoryId;
    load();
  }
}

class RatingManagementSection extends StatefulWidget {
  const RatingManagementSection({super.key, required this.selectedActivity});

  final ActivityItem? selectedActivity;

  @override
  State<RatingManagementSection> createState() => _RatingManagementSectionState();
}

class _RatingManagementSectionState extends State<RatingManagementSection> {
  List<RatingOption> _data = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _deleteRating(RatingOption rating) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rating'),
        content: Text('Delete ${rating.ratingName}?'),
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
      await RatingService.deleteRating(rating.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting rating: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RatingManagementSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedActivity?.id != oldWidget.selectedActivity?.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.selectedActivity?.id;
    if (id == null) {
      setState(() {
        _data = [];
        _error = null;
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final list = await RatingService.listRatings(activityId: id);
      setState(() => _data = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlifCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.selectedActivity == null
                      ? 'Select an activity above to manage ratings.'
                      : 'Ratings for ${widget.selectedActivity!.name}',
                ),
              ),
              if (widget.selectedActivity != null)
                AlifButton(
                  label: '+ Add Rating',
                  expand: false,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RatingFormDialog(
                        activity: widget.selectedActivity!,
                        onSuccess: _load,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (_data.isEmpty)
            const Text('No ratings found for this activity')
          else
            ..._data.map(
              (rating) => Padding(
                padding: const EdgeInsets.only(bottom: AlifSpacing.sm),
                child: AlifCard(
                  child: Row(
                    children: [
                      Expanded(child: Text('${rating.ratingName} (${rating.marks})')),
                      FilledButton.tonal(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => RatingFormDialog(
                              activity: widget.selectedActivity!,
                              initialRating: rating,
                              onSuccess: _load,
                            ),
                          );
                        },
                        child: const Text('Edit'),
                      ),
                      const SizedBox(width: AlifSpacing.sm),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red.shade100),
                        onPressed: () => _deleteRating(rating),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    super.key,
    required this.onSuccess,
    this.initialCategory,
  });

  final VoidCallback onSuccess;
  final ActivityCategory? initialCategory;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialCategory?.name ?? '');
  late final _nameMl = TextEditingController(text: widget.initialCategory?.nameMl ?? '');
  late final _icon = TextEditingController(text: widget.initialCategory?.icon ?? '');
  late final _displayOrder = TextEditingController(
    text: widget.initialCategory?.displayOrder.toString() ?? '0',
  );
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialCategory?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _icon.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final order = int.tryParse(_displayOrder.text.trim()) ?? 0;

      if (widget.initialCategory == null) {
        await CategoryService.createCategory(
          name: _name.text.trim(),
          nameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          icon: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
          displayOrder: order,
          status: _status,
        );
      } else {
        await CategoryService.updateCategory(
          widget.initialCategory!.id,
          name: _name.text.trim(),
          nameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          icon: _icon.text.trim().isEmpty ? null : _icon.text.trim(),
          displayOrder: order,
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
      title: Text(widget.initialCategory == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _nameMl,
                decoration: const InputDecoration(labelText: 'Name (Malayalam)'),
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _icon,
                decoration: const InputDecoration(labelText: 'Icon'),
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _displayOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Order'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
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

class ActivityFormDialog extends StatefulWidget {
  const ActivityFormDialog({
    super.key,
    required this.category,
    required this.onSuccess,
    this.initialActivity,
  });

  final ActivityCategory category;
  final VoidCallback onSuccess;
  final ActivityItem? initialActivity;

  @override
  State<ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialActivity?.name ?? '');
  late final _nameMl = TextEditingController(text: widget.initialActivity?.nameMl ?? '');
  late final _displayOrder = TextEditingController(
    text: widget.initialActivity?.displayOrder.toString() ?? '0',
  );
  bool _hasQuantity = false;
  String _status = 'active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _hasQuantity = widget.initialActivity?.hasQuantity ?? false;
    _status = widget.initialActivity?.status ?? 'active';
  }

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);
      final order = int.tryParse(_displayOrder.text.trim()) ?? 0;

      if (widget.initialActivity == null) {
        await ActivityService.createActivity(
          categoryId: widget.category.id,
          name: _name.text.trim(),
          nameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          displayOrder: order,
          hasQuantity: _hasQuantity,
          status: _status,
        );
      } else {
        await ActivityService.updateActivity(
          widget.initialActivity!.id,
          name: _name.text.trim(),
          nameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          displayOrder: order,
          hasQuantity: _hasQuantity,
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
      title: Text(widget.initialActivity == null ? 'Add Activity' : 'Edit Activity'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _nameMl,
                decoration: const InputDecoration(labelText: 'Name (Malayalam)'),
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _displayOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Order'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AlifSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Has Quantity Input'),
                value: _hasQuantity,
                onChanged: (value) => setState(() => _hasQuantity = value),
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

class RatingFormDialog extends StatefulWidget {
  const RatingFormDialog({
    super.key,
    required this.activity,
    required this.onSuccess,
    this.initialRating,
  });

  final ActivityItem activity;
  final VoidCallback onSuccess;
  final RatingOption? initialRating;

  @override
  State<RatingFormDialog> createState() => _RatingFormDialogState();
}

class _RatingFormDialogState extends State<RatingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialRating?.ratingName ?? '');
  late final _nameMl = TextEditingController(text: widget.initialRating?.ratingNameMl ?? '');
  late final _marks = TextEditingController(text: widget.initialRating?.marks.toString() ?? '0');
  late final _color = TextEditingController(text: widget.initialRating?.color ?? '#3FA34D');
  late final _displayOrder = TextEditingController(
    text: widget.initialRating?.displayOrder.toString() ?? '0',
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _nameMl.dispose();
    _marks.dispose();
    _color.dispose();
    _displayOrder.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      final marks = int.tryParse(_marks.text.trim()) ?? 0;
      final order = int.tryParse(_displayOrder.text.trim()) ?? 0;
      if (widget.initialRating == null) {
        await RatingService.createRating(
          activityId: widget.activity.id,
          ratingName: _name.text.trim(),
          ratingNameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          marks: marks,
          color: _color.text.trim().isEmpty ? '#3FA34D' : _color.text.trim(),
          displayOrder: order,
        );
      } else {
        await RatingService.updateRating(
          widget.initialRating!.id,
          ratingName: _name.text.trim(),
          ratingNameMl: _nameMl.text.trim().isEmpty ? null : _nameMl.text.trim(),
          marks: marks,
          color: _color.text.trim().isEmpty ? '#3FA34D' : _color.text.trim(),
          displayOrder: order,
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
      title: Text(widget.initialRating == null ? 'Add Rating' : 'Edit Rating'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _nameMl,
                decoration: const InputDecoration(labelText: 'Name (Malayalam)'),
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _marks,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Marks'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _color,
                decoration: const InputDecoration(labelText: 'Color (hex, e.g. #3FA34D)'),
                validator: (value) {
                  final input = (value ?? '').trim();
                  if (input.isEmpty) {
                    return 'Required';
                  }
                  final colorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
                  if (!colorRegex.hasMatch(input)) {
                    return 'Use valid hex color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AlifSpacing.md),
              TextFormField(
                controller: _displayOrder,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Display Order'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
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
