import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';
import '../../../../../core/network/api_client.dart';
import '../../domain/models/import_models.dart';

class ImportDataDialog extends ConsumerStatefulWidget {
  final String entityName; // 'Students', 'Faculty', 'Internal Marks'
  final String? sectionId;
  final String? academicYearId;
  final String? semesterId;
  final String? subjectId;

  const ImportDataDialog({
    super.key,
    required this.entityName,
    this.sectionId,
    this.academicYearId,
    this.semesterId,
    this.subjectId,
  });

  @override
  ConsumerState<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends ConsumerState<ImportDataDialog> {
  int _currentStep = 1; // 1: Upload, 2: Sheet & Mapping, 3: Preview & Confirm
  bool _isLoading = false;
  String? _errorMessage;

  // File state
  String? _fileName;

  // Batch & Preview state
  ImportBatchModel? _batch;
  ImportSummaryModel? _summary;
  List<NormalizedImportRowModel> _previewRows = [];
  String _activeFilter = 'ALL'; // ALL, VALID, WARNING, UNRESOLVED, INVALID

  // Mapping state
  final Map<String, String> _customMappings = {};
  bool _allowPartial = false;
  String? _selectedSheet;

  final ApiClient _apiClient = ApiClient();

  Future<void> _handleFileUpload(String name, String base64Content) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _fileName = name;
    });

    try {
      final res = await _apiClient.dio.post(
        '/imports/upload',
        data: {
          'fileName': name,
          'fileBase64': base64Content,
          'dataType': widget.entityName.toLowerCase().contains('mark') ||
                  widget.entityName.toLowerCase().contains('assessment')
              ? 'ASSESSMENT'
              : widget.entityName.toLowerCase().contains('attendance')
                  ? 'ATTENDANCE'
                  : 'STUDENT_ROSTER',
          'sectionId': widget.sectionId,
          'academicYearId': widget.academicYearId,
          'semesterId': widget.semesterId,
          'subjectId': widget.subjectId,
        },
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final batchData = data['batch'] as Map<String, dynamic>;
      final batch = ImportBatchModel.fromJson(batchData);

      setState(() {
        _batch = batch;
        _selectedSheet = batch.selectedSheet;
        for (final m in batch.columnMappings) {
          _customMappings[m.sourceColumn] = m.targetField;
        }
        _currentStep = 2;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _validateAndPreview() async {
    if (_batch == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Update mappings if changed
      final mappingList = _customMappings.entries
          .map((e) => {'sourceColumn': e.key, 'targetField': e.value})
          .toList();

      await _apiClient.dio.put(
        '/imports/${_batch!.id}/mappings',
        data: {
          'selectedSheet': _selectedSheet,
          'customMappings': mappingList,
        },
      );

      // 2. Validate and generate preview
      final res = await _apiClient.dio.post(
        '/imports/${_batch!.id}/validate',
        data: {
          'sectionId': widget.sectionId,
          'academicYearId': widget.academicYearId,
          'semesterId': widget.semesterId,
          'subjectId': widget.subjectId,
        },
      );

      final data = res.data['data'] as Map<String, dynamic>;
      final previewResponse = ImportPreviewResponseModel.fromJson(data);

      setState(() {
        _batch = previewResponse.batch;
        _summary = previewResponse.summary;
        _previewRows = previewResponse.previewRows;
        _currentStep = 3;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _confirmImport() async {
    if (_batch == null) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.dio.post(
        '/imports/${_batch!.id}/confirm',
        data: {
          'allowPartial': _allowPartial,
        },
      );

      final msg = res.data['message']?.toString() ?? 'Import completed';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.success),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<NormalizedImportRowModel> get _filteredRows {
    if (_activeFilter == 'ALL') return _previewRows;
    return _previewRows.where((r) {
      if (_activeFilter == 'VALID') return r.status == 'VALID';
      if (_activeFilter == 'WARNING') return r.status == 'WARNING';
      if (_activeFilter == 'UNRESOLVED') return r.status == 'UNRESOLVED';
      if (_activeFilter == 'INVALID') {
        return r.status == 'INVALID' || r.status == 'DUPLICATE_CONFLICT';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceDarkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_errorMessage != null) _buildErrorBanner(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary))
                    : _buildStepContent(),
              ),
              const SizedBox(height: 16),
              _buildActionFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import ${widget.entityName}',
              style: const TextStyle(
                color: AppColors.onDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Step $_currentStep of 3: ${_getStepTitle()}${_fileName != null ? " ($_fileName)" : ""}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(LucideIcons.x, color: AppColors.textMuted),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Upload Spreadsheet File';
      case 2:
        return 'Select Sheet & Map Columns';
      case 3:
        return 'Review Preview & Confirm';
      default:
        return '';
    }
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle,
              color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildUploadStep();
      case 2:
        return _buildMappingStep();
      case 3:
        return _buildPreviewStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildUploadStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.canvasDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.fileSpreadsheet,
                    size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text(
                  'Select CSV or Excel (.xlsx) file',
                  style: TextStyle(
                      color: AppColors.onDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Supported formats: .xlsx, .xls, .csv (Max 10MB)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onDark,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    // Provide realistic default template file for quick upload
                    final sampleCsv =
                        'PIN,Student Name,Marks,Status\n23A001,Student 1,22,PRESENT\n23A002,Student 2,19,PRESENT\n23A003,Student 3,,ABSENT\n';
                    final b64 = base64Encode(utf8.encode(sampleCsv));
                    _handleFileUpload('marks_template.csv', b64);
                  },
                  icon: const Icon(LucideIcons.uploadCloud, size: 18),
                  label: const Text('Load Spreadsheet Template'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingStep() {
    if (_batch == null) return const SizedBox();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_batch!.sheetNames.length > 1) ...[
            const Text(
              'Select Sheet',
              style: TextStyle(
                  color: AppColors.onDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _batch!.sheetNames.map((s) {
                final isSelected = _selectedSheet == s;
                return ChoiceChip(
                  label: Text(s),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  onSelected: (val) {
                    if (val) setState(() => _selectedSheet = s);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Column Mappings',
            style: TextStyle(
                color: AppColors.onDark,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Confirm how spreadsheet columns correspond to canonical fields.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.canvasDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.hairlineDark),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _batch!.columnMappings.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.hairlineDark, height: 1),
              itemBuilder: (context, idx) {
                final m = _batch!.columnMappings[idx];
                final currentTarget = _customMappings[m.sourceColumn] ?? m.targetField;

                return ListTile(
                  dense: true,
                  title: Text(
                    m.sourceColumn,
                    style: const TextStyle(
                        color: AppColors.onDark, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Status: ${m.status} (${m.confidence})',
                    style: TextStyle(
                      color: m.status == 'AUTO_MATCHED'
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 11,
                    ),
                  ),
                  trailing: DropdownButton<String>(
                    dropdownColor: AppColors.surfaceDarkCard,
                    value: currentTarget,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                          value: 'studentPin',
                          child: Text('Student PIN / Roll',
                              style: TextStyle(color: AppColors.onDark))),
                      DropdownMenuItem(
                          value: 'studentName',
                          child: Text('Student Name',
                              style: TextStyle(color: AppColors.onDark))),
                      DropdownMenuItem(
                          value: 'marks',
                          child: Text('Marks / Score',
                              style: TextStyle(color: AppColors.onDark))),
                      DropdownMenuItem(
                          value: 'status',
                          child: Text('Attendance Status',
                              style: TextStyle(color: AppColors.onDark))),
                      DropdownMenuItem(
                          value: 'UNMAPPED',
                          child: Text('Ignore (Unmapped)',
                              style: TextStyle(color: AppColors.textMuted))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _customMappings[m.sourceColumn] = val;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_summary != null) _buildSummaryCards(),
        const SizedBox(height: 12),
        _buildFilterChips(),
        const SizedBox(height: 12),
        Expanded(child: _buildPreviewTable()),
        const SizedBox(height: 8),
        if ((_summary?.errorCount ?? 0) > 0 ||
            (_summary?.unresolvedCount ?? 0) > 0)
          _buildPartialImportToggle(),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final precision = _summary?.detectedPrecision;
    final hasPrecision = precision != null && precision != 'NOT_APPLICABLE';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasPrecision) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.gauge, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    precision == 'DETAILED_SESSION'
                        ? 'Attendance precision detected: Detailed session records'
                        : precision == 'PERIOD_SUMMARY'
                            ? 'Attendance precision detected: Period summary (${_summary!.summaryCount} records)'
                            : precision == 'PERCENTAGE_ONLY'
                                ? 'Attendance precision detected: Percentage only (${_summary!.percentageOnlyCount} records)'
                                : 'Attendance precision detected: Mixed precision (Review required)',
                    style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            _buildStatBadge(
                'Total', '${_summary!.rowCount}', LucideIcons.layers, AppColors.primary),
            const SizedBox(width: 8),
            _buildStatBadge(
                'Valid', '${_summary!.validCount}', LucideIcons.checkCircle, AppColors.success),
            const SizedBox(width: 8),
            _buildStatBadge('Warnings', '${_summary!.warningCount}',
                LucideIcons.alertTriangle, AppColors.warning),
            const SizedBox(width: 8),
            _buildStatBadge(
                'Errors', '${_summary!.errorCount}', LucideIcons.xCircle, AppColors.error),
          ],
        ),
        if (hasPrecision &&
            (_summary!.detailedCount > 0 ||
                _summary!.summaryCount > 0 ||
                _summary!.percentageOnlyCount > 0)) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatBadge('Detailed', '${_summary!.detailedCount}',
                  LucideIcons.calendar, AppColors.primary),
              const SizedBox(width: 8),
              _buildStatBadge('Summary', '${_summary!.summaryCount}',
                  LucideIcons.table, AppColors.warning),
              const SizedBox(width: 8),
              _buildStatBadge('Pct Only', '${_summary!.percentageOnlyCount}',
                  LucideIcons.percent, AppColors.primaryPressed),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['ALL', 'VALID', 'WARNING', 'UNRESOLVED', 'INVALID'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(f, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              selectedColor: AppColors.primary,
              onSelected: (val) {
                if (val) setState(() => _activeFilter = f);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreviewTable() {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      return const Center(
        child: Text('No rows match active filter',
            style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.hairlineDark, height: 1),
        itemBuilder: (context, idx) {
          final r = rows[idx];
          final isInvalid =
              r.status == 'INVALID' || r.status == 'DUPLICATE_CONFLICT';
          final color = isInvalid
              ? AppColors.error
              : r.status == 'WARNING'
                  ? AppColors.warning
                  : AppColors.success;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text('#${r.rowNumber}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.studentName ?? 'Unknown Student',
                        style: const TextStyle(
                            color: AppColors.onDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'PIN: ${r.studentPin ?? r.rollNumber ?? '—'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (r.marks != null)
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Marks: ${r.marks}',
                      style: const TextStyle(
                          color: AppColors.onDark, fontSize: 12),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r.status,
                    style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartialImportToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            activeColor: AppColors.primary,
            value: _allowPartial,
            onChanged: (val) => setState(() => _allowPartial = val ?? false),
          ),
          const Expanded(
            child: Text(
              'Allow partial import (skip invalid and unresolved rows)',
              style: TextStyle(color: AppColors.onDark, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 1)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('Back',
                style: TextStyle(color: AppColors.textMuted)),
          )
        else
          const SizedBox(),
        Row(
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            const SizedBox(width: 8),
            if (_currentStep == 2)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onDark),
                onPressed: _validateAndPreview,
                child: const Text('Validate & Preview'),
              )
            else if (_currentStep == 3)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onDark),
                onPressed: _confirmImport,
                child: const Text('Confirm Import'),
              ),
          ],
        ),
      ],
    );
  }
}
