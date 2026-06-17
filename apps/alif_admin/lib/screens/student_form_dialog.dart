import "package:flutter/material.dart";
import "package:alif_design_system/alif_design_system.dart";

import "../models/student.dart";
import "../services/student_service.dart";

class StudentFormDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final Student? initialStudent;

  const StudentFormDialog({
    super.key,
    required this.onSuccess,
    this.initialStudent,
  });

  @override
  State<StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<StudentFormDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _phoneController = TextEditingController(
    text: widget.initialStudent?.parentPhone ?? "",
  );
  late final _fatherController = TextEditingController(
    text: widget.initialStudent?.fatherName ?? "",
  );
  late final _motherController = TextEditingController(
    text: widget.initialStudent?.motherName ?? "",
  );
  late final _addressController = TextEditingController(
    text: widget.initialStudent?.address ?? "",
  );

  DateTime? _dob;
  String _gender = "male";
  String? _batchId;
  String? _classId;
  List<Batch> _batches = [];
  List<Class> _classes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dob = widget.initialStudent?.dateOfBirth ?? DateTime.now();
    _gender = widget.initialStudent?.gender ?? "male";
    _batchId = widget.initialStudent?.batchId;
    _classId = widget.initialStudent?.classId;
    _loadBatches();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fatherController.dispose();
    _motherController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadBatches() async {
    try {
      final batches = await StudentService.getBatches();
      setState(() => _batches = batches);

      if (_batchId != null) {
        _loadClasses(_batchId!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading batches: $e")),
        );
      }
    }
  }

  Future<void> _loadClasses(String batchId) async {
    try {
      final classes = await StudentService.getClasses(batchId);
      setState(() {
        _classes = classes;
        if (_classId == null && classes.isNotEmpty) {
          _classId = classes.first.id;
        }
      });
    } catch (e) {
      // Silently fail - classes are optional
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dob,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _dob = date);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _dob != null) {
      try {
        setState(() => _isLoading = true);

        if (widget.initialStudent == null) {
          await StudentService.createStudent(
            parentPhone: _phoneController.text,
            fatherName: _fatherController.text,
            motherName: _motherController.text,
            dateOfBirth: _dob!,
            gender: _gender,
            batchId: _batchId,
            classId: _classId,
            address: _addressController.text.isEmpty ? null : _addressController.text,
          );
        } else {
          await StudentService.updateStudent(
            widget.initialStudent!.id,
            parentPhone: _phoneController.text,
            fatherName: _fatherController.text,
            motherName: _motherController.text,
            dateOfBirth: _dob,
            gender: _gender,
            batchId: _batchId,
            classId: _classId,
            address: _addressController.text.isEmpty ? null : _addressController.text,
            status: widget.initialStudent!.status,
          );
        }

        if (mounted) {
          widget.onSuccess();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.toString()}")),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialStudent == null ? "Add Student" : "Edit Student",
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AlifSpacing.md,
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Parent Phone"),
                validator: (v) => (v?.isEmpty ?? true) ? "Required" : null,
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                controller: _fatherController,
                decoration: const InputDecoration(labelText: "Father Name"),
                validator: (v) => (v?.isEmpty ?? true) ? "Required" : null,
              ),
              TextFormField(
                controller: _motherController,
                decoration: const InputDecoration(labelText: "Mother Name"),
                validator: (v) => (v?.isEmpty ?? true) ? "Required" : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                maxLines: 3,
              ),
              FilledButton(
                onPressed: _pickDate,
                child: Text(
                  "Date of Birth: ${_dob?.toLocal().toString().split(' ')[0] ?? 'Select'}",
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Male")),
                  DropdownMenuItem(value: "female", child: Text("Female")),
                ],
                onChanged: (v) => setState(() => _gender = v ?? "male"),
                decoration: const InputDecoration(labelText: "Gender"),
              ),
              DropdownButtonFormField<String?>(
                initialValue: _batchId,
                items: [
                  const DropdownMenuItem(value: null, child: Text("No Batch")),
                  ..._batches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
                ],
                onChanged: (v) {
                  setState(() {
                    _batchId = v;
                    _classId = null;
                  });
                  if (v != null) _loadClasses(v);
                },
                decoration: const InputDecoration(labelText: "Batch"),
              ),
              if (_classes.isNotEmpty)
                DropdownButtonFormField<String?>(
                  initialValue: _classId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text("No Class")),
                    ..._classes.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _classId = v),
                  decoration: const InputDecoration(labelText: "Class"),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        AlifButton(
          label: "Save",
          expand: false,
          isLoading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}
