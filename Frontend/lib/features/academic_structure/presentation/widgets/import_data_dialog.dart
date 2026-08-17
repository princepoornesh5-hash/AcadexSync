import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme/app_theme.dart';

class ImportDataDialog extends StatefulWidget {
  final String entityName; // 'Students', 'Faculty'

  const ImportDataDialog({super.key, required this.entityName});

  @override
  State<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<ImportDataDialog> {
  bool _isUploading = false;
  bool _isSuccess = false;

  void _simulateUpload() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDarkCard,
      title: Text('Import ${widget.entityName}', style: const TextStyle(color: AppColors.onDark)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.canvasDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(_isSuccess ? LucideIcons.checkCircle : LucideIcons.uploadCloud, size: 48, color: _isSuccess ? AppColors.success : AppColors.primary),
                const SizedBox(height: 16),
                Text(_isSuccess ? 'Upload Successful!' : 'Drag and drop your CSV/Excel file here', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('or click to browse from your computer', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.fileSpreadsheet, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Download template for ${widget.entityName}', style: const TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.underline)),
            ],
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.onDark),
          onPressed: _isUploading || _isSuccess ? null : _simulateUpload,
          child: _isUploading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onDark)) 
              : const Text('Upload File'),
        ),
      ],
    );
  }
}
