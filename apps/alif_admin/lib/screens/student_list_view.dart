import "package:flutter/material.dart";
import "package:alif_design_system/alif_design_system.dart";
import "package:intl/intl.dart";

import "../models/student.dart";
import "../services/student_service.dart";
import "student_form_dialog.dart";
import "student_management_page.dart";

class StudentListView extends StatefulWidget {
  final StudentListViewController controller;

  const StudentListView({
    super.key,
    required this.controller,
  });

  @override
  State<StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<StudentListView> {
  List<Batch> _batches = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBatches();
    _searchController.addListener(_onSearchChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    widget.controller.setSearch(_searchController.text.trim());
  }

  void _onControllerChanged() {
    setState(() {});
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await StudentService.getBatches();
      if (!mounted) {
        return;
      }
      setState(() => _batches = batches);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading batches: \$e")),
        );
      }
    }
  }

  void _deleteStudent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student"),
        content: const Text("Are you sure you want to delete this student?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StudentService.deleteStudent(id);
        widget.controller.refresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student deleted successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting student: \$e")),
          );
        }
      }
    }
  }

  void _editStudent(Student student) {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        initialStudent: student,
        onSuccess: () {
          widget.controller.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student updated successfully")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.controller.data;
    final students = response?.data ?? const <Student>[];
    final pagination = response?.pagination;

    return Column(
      children: [
        _SummaryStrip(
          total: pagination?.total ?? 0,
          page: pagination?.currentPage ?? 1,
          pages: pagination?.pages ?? 1,
          activeStatus: widget.controller.status,
          selectedBatch: _batches
              .where((batch) => batch.id == widget.controller.selectedBatch)
              .map((batch) => batch.name)
              .firstOrNull,
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
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
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
                      "Could not load students",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.xs),
                    Text(
                      widget.controller.error ?? "Unknown error",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlifColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    FilledButton.tonalIcon(
                      onPressed: widget.controller.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try again"),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (students.isEmpty)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AlifSpacing.md),
              child: AlifCard(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.manage_accounts_outlined,
                      size: 48,
                      color: AlifColors.neutral.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: AlifSpacing.md),
                    Text(
                      "No students found",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AlifSpacing.xs),
                    Text(
                      "Try changing filters or add a new student.",
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
                itemCount: students.length,
                separatorBuilder: (_, _) => const SizedBox(height: AlifSpacing.md),
                itemBuilder: (context, index) {
                  final student = students[index];
                  return StudentListTile(
                    student: student,
                    onEdit: () => _editStudent(student),
                    onDelete: () => _deleteStudent(student.id),
                  );
                },
              ),
            ),
          ),
        if (pagination != null)
          _StudentPaginationBar(
            pagination: pagination,
            onPrev: pagination.currentPage > 1
                ? () => widget.controller.setOffset(pagination.offset - pagination.limit)
                : null,
            onNext: pagination.currentPage < pagination.pages
                ? () => widget.controller.setOffset(pagination.offset + pagination.limit)
                : null,
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return AlifTextInput(
      label: "Search students",
      hintText: "By name or phone...",
      controller: _searchController,
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<String?>(
      initialValue: widget.controller.selectedBatch,
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text("All Batches"),
        ),
        ..._batches.map(
          (batch) => DropdownMenuItem<String?>(
            value: batch.id,
            child: Text(batch.name),
          ),
        ),
      ],
      onChanged: (value) => widget.controller.setBatch(value),
      decoration: InputDecoration(
        labelText: "Batch",
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
        DropdownMenuItem(value: "active", child: Text("Active")),
        DropdownMenuItem(value: "inactive", child: Text("Inactive")),
      ],
      onChanged: (value) {
        if (value != null) {
          widget.controller.setStatus(value);
        }
      },
      decoration: InputDecoration(
        labelText: "Status",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.total,
    required this.page,
    required this.pages,
    required this.activeStatus,
    required this.selectedBatch,
  });

  final int total;
  final int page;
  final int pages;
  final String activeStatus;
  final String? selectedBatch;

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
                AlifColors.accent.withValues(alpha: 0.9),
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
              _SummaryPill(label: "Students", value: "$total"),
              _SummaryPill(label: "Page", value: "$page / $pages"),
              _SummaryPill(label: "Status", value: activeStatus.toUpperCase()),
              _SummaryPill(label: "Batch", value: selectedBatch ?? "All"),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
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

class _StudentPaginationBar extends StatelessWidget {
  const _StudentPaginationBar({
    required this.pagination,
    required this.onPrev,
    required this.onNext,
  });

  final Pagination pagination;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;

    return Padding(
      padding: const EdgeInsets.all(AlifSpacing.md),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Showing page ${pagination.currentPage} of ${pagination.pages}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlifColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AlifSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onPrev,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text("Prev"),
                      ),
                    ),
                    const SizedBox(width: AlifSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text("Next"),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Text(
                  "Showing page ${pagination.currentPage} of ${pagination.pages}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AlifColors.textSecondary,
                      ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: onPrev,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text("Prev"),
                ),
                const SizedBox(width: AlifSpacing.sm),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text("Next"),
                ),
              ],
            ),
    );
  }
}

class StudentListTile extends StatelessWidget {
  final Student student;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudentListTile({
    super.key,
    required this.student,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final dob = DateFormat("MMM dd, yyyy").format(student.dateOfBirth);
    final enrolled = DateFormat("MMM dd, yyyy").format(student.enrollmentDate);
    final title = (student.fullName ?? "").trim().isNotEmpty
        ? student.fullName!.trim()
        : student.parentPhone;
    final subtitle = [
      "Father: ${student.fatherName}",
      "Mother: ${student.motherName}",
    ].join("  |  ");

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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AlifColors.primaryContainer,
                ),
                child: Text(
                  _initials(title),
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AlifColors.textSecondary,
                          ),
                    ),
                    if (compact) ...[
                      const SizedBox(height: AlifSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AlifBadge(
                          label: student.status.toUpperCase(),
                          background: student.status == "active"
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
                  label: student.status.toUpperCase(),
                  background: student.status == "active"
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
              _MetaChip(icon: Icons.phone_rounded, text: student.parentPhone),
              _MetaChip(icon: Icons.cake_outlined, text: "DOB: $dob"),
              _MetaChip(icon: Icons.person_outline, text: student.gender),
              _MetaChip(
                icon: Icons.groups_outlined,
                text: student.batch?.name ?? "No batch",
              ),
              _MetaChip(icon: Icons.event_note_outlined, text: "Enrolled: $enrolled"),
            ],
          ),
          const SizedBox(height: AlifSpacing.md),
          Wrap(
            spacing: AlifSpacing.md,
            runSpacing: AlifSpacing.sm,
            alignment: WrapAlignment.end,
            children: [
              FilledButton.tonal(
                onPressed: onEdit,
                child: const Text("Edit"),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                ),
                onPressed: onDelete,
                child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
      return "ST";
    }
    final parts = cleaned.split(RegExp(r"\s+"));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

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
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
