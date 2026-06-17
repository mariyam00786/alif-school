import 'package:alif_design_system/alif_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/report.dart';
import '../models/student.dart';
import '../services/batch_service.dart';
import '../services/report_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedWeekStart = _mondayOfWeek(DateTime.now());
  DateTime _selectedMonthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  String _reportType = 'daily';
  String? _selectedBatchId;

  bool _isLoading = true;
  String? _error;
  ReportResponse? _report;
  List<Batch> _batches = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  static DateTime _mondayOfWeek(DateTime date) {
    final day = date.weekday;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: day - 1));
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final batchesFuture = BatchService.listBatches(status: 'active');
      final reportFuture = _reportType == 'daily'
          ? ReportService.getDailyReport(date: _selectedDate, batchId: _selectedBatchId)
          : _reportType == 'weekly'
          ? ReportService.getWeeklyReport(
              weekStart: _selectedWeekStart,
              batchId: _selectedBatchId,
            )
          : ReportService.getMonthlyReport(
              monthStart: _selectedMonthStart,
              batchId: _selectedBatchId,
            );

      final batches = await batchesFuture;
      final report = await reportFuture;

      if (!mounted) {
        return;
      }

      setState(() {
        _batches = batches;
        _report = report;
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

  Future<void> _pickDate() async {
    final initialDate = _reportType == 'daily'
        ? _selectedDate
        : _reportType == 'weekly'
        ? _selectedWeekStart
        : _selectedMonthStart;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      if (_reportType == 'daily') {
        _selectedDate = picked;
      } else if (_reportType == 'weekly') {
        _selectedWeekStart = _mondayOfWeek(picked);
      } else {
        _selectedMonthStart = DateTime(picked.year, picked.month, 1);
      }
    });

    await _load();
  }

  Future<void> _exportCsv() async {
    try {
      setState(() => _isExporting = true);
      final csv = _reportType == 'daily'
          ? await ReportService.exportDailyCsv(
              date: _selectedDate,
              batchId: _selectedBatchId,
            )
          : _reportType == 'weekly'
          ? await ReportService.exportWeeklyCsv(
              weekStart: _selectedWeekStart,
              batchId: _selectedBatchId,
            )
          : await ReportService.exportMonthlyCsv(
              monthStart: _selectedMonthStart,
              batchId: _selectedBatchId,
            );

      if (!mounted) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CSV Export Ready'),
          content: SizedBox(
            width: 640,
            child: SingleChildScrollView(
              child: Text(
                csv.length > 3000 ? '${csv.substring(0, 3000)}\n\n...truncated preview...' : csv,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV copied to clipboard.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportExcel() async {
    try {
      setState(() => _isExporting = true);
      final excel = _reportType == 'daily'
          ? await ReportService.exportDailyExcel(
              date: _selectedDate,
              batchId: _selectedBatchId,
            )
          : _reportType == 'weekly'
          ? await ReportService.exportWeeklyExcel(
              weekStart: _selectedWeekStart,
              batchId: _selectedBatchId,
            )
          : await ReportService.exportMonthlyExcel(
              monthStart: _selectedMonthStart,
              batchId: _selectedBatchId,
            );

      if (!mounted) {
        return;
      }

      await Clipboard.setData(ClipboardData(text: excel));
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel-compatible data copied to clipboard.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel export failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _previewPrintLayout() async {
    try {
      final html = _reportType == 'daily'
          ? await ReportService.getDailyPrintHtml(
              date: _selectedDate,
              batchId: _selectedBatchId,
            )
          : _reportType == 'weekly'
          ? await ReportService.getWeeklyPrintHtml(
              weekStart: _selectedWeekStart,
              batchId: _selectedBatchId,
            )
          : await ReportService.getMonthlyPrintHtml(
              monthStart: _selectedMonthStart,
              batchId: _selectedBatchId,
            );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Print Template Preview (HTML)'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Text(
                html.length > 3500
                    ? '${html.substring(0, 3500)}\n\n...truncated preview...'
                    : html,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print preview failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return AlifAppShell(
      title: 'Reports',
      body: ListView(
        padding: const EdgeInsets.all(AlifSpacing.md),
        children: [
          AlifCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _reportType,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily Report')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly Report')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly Report')),
                        ],
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }

                          setState(() => _reportType = value);
                          await _load();
                        },
                        decoration: const InputDecoration(labelText: 'Report Type'),
                      ),
                    ),
                    const SizedBox(width: AlifSpacing.md),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _selectedBatchId,
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
                        onChanged: (value) async {
                          setState(() => _selectedBatchId = value);
                          await _load();
                        },
                        decoration: const InputDecoration(labelText: 'Batch'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AlifSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _reportType == 'daily'
                            ? 'Date: ${_selectedDate.toIso8601String().split('T').first}'
                            : _reportType == 'weekly'
                            ? 'Week Start: ${_selectedWeekStart.toIso8601String().split('T').first}'
                            : 'Month: ${_selectedMonthStart.year}-${_selectedMonthStart.month.toString().padLeft(2, '0')}',
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _pickDate,
                      child: Text(
                        _reportType == 'daily'
                            ? 'Change Date'
                            : _reportType == 'weekly'
                            ? 'Change Week'
                            : 'Change Month',
                      ),
                    ),
                    const SizedBox(width: AlifSpacing.sm),
                    FilledButton.tonalIcon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: AlifSpacing.sm),
                    FilledButton.icon(
                      onPressed: _isExporting ? null : _exportCsv,
                      icon: const Icon(Icons.download_rounded),
                      label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
                    ),
                    const SizedBox(width: AlifSpacing.sm),
                    FilledButton.icon(
                      onPressed: _isExporting ? null : _exportExcel,
                      icon: const Icon(Icons.table_view_rounded),
                      label: const Text('Export Excel'),
                    ),
                    const SizedBox(width: AlifSpacing.sm),
                    FilledButton.tonalIcon(
                      onPressed: _previewPrintLayout,
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print Preview'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AlifSpacing.md),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Colors.red))
          else if (report == null)
            const Text('No report data')
          else ...[
            AlifCard(
              child: Wrap(
                spacing: AlifSpacing.md,
                runSpacing: AlifSpacing.md,
                children: [
                  _SummaryChip(
                    label: 'Students',
                    value: report.summary.students.toString(),
                  ),
                  _SummaryChip(
                    label: 'Total Marks',
                    value: report.summary.totalMarks.toString(),
                  ),
                  _SummaryChip(
                    label: 'Activities',
                    value: report.summary.totalActivities.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AlifSpacing.md),
            if (report.data.isEmpty)
              const AlifCard(child: Text('No rows found for selected filters.'))
            else
              ...report.data.map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: AlifSpacing.md),
                  child: AlifCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.studentName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: AlifSpacing.xs),
                              Text(
                                'Batch: ${row.batchName ?? '-'} | Phone: ${row.parentPhone ?? '-'}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        _SummaryChip(label: 'Marks', value: '${row.totalMarks}'),
                        const SizedBox(width: AlifSpacing.sm),
                        _SummaryChip(
                          label: 'Activities',
                          value: '${row.activitiesCompleted}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

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
        color: AlifColors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AlifColors.border),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
