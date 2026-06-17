import "package:flutter/material.dart";
import "package:alif_design_system/alif_design_system.dart";

import "../models/student.dart";
import "../services/student_service.dart";
import "student_form_dialog.dart";
import "student_list_view.dart";

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  late StudentListViewController _listController;

  @override
  void initState() {
    super.initState();
    _listController = StudentListViewController();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (context) => StudentFormDialog(
        onSuccess: () {
          _listController.refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student added successfully")),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlifAppShell(
      title: "Student Management",
      actions: [
        Padding(
          padding: const EdgeInsets.all(AlifSpacing.md),
          child: AlifButton(
            label: "+ Add Student",
            expand: false,
            onPressed: _showAddStudentDialog,
          ),
        ),
      ],
      body: StudentListView(controller: _listController),
    );
  }
}

class StudentListViewController extends ChangeNotifier {
  StudentListResponse? _data;
  bool _isLoading = false;
  String? _error;
  String _search = "";
  String? _selectedBatch;
  String _status = "active";
  final int _limit = 20;
  int _offset = 0;
  bool _isDisposed = false;

  StudentListResponse? get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedBatch => _selectedBatch;
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

  StudentListViewController() {
    load();
  }

  Future<void> load() async {
    try {
      _isLoading = true;
      _error = null;
      _safeNotify();

      _data = await StudentService.listStudents(
        search: _search.isEmpty ? null : _search,
        batchId: _selectedBatch,
        status: _status,
        limit: _limit,
        offset: _offset,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setSearch(String value) {
    _search = value;
    _offset = 0;
    load();
  }

  void setBatch(String? value) {
    _selectedBatch = value;
    _offset = 0;
    load();
  }

  void setStatus(String value) {
    _status = value;
    _offset = 0;
    load();
  }

  void setOffset(int value) {
    _offset = value;
    load();
  }

  void refresh() {
    _offset = 0;
    load();
  }
}
