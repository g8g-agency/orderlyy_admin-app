import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class OccConflictDialog extends StatelessWidget {
  final VoidCallback onOverwrite;
  final VoidCallback onRefresh;
  final String entityName;

  const OccConflictDialog({
    super.key,
    required this.onOverwrite,
    required this.onRefresh,
    this.entityName = 'record',
  });

  static Future<bool?> show(
    BuildContext context, {
    String entityName = 'record',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => OccConflictDialog(
        entityName: entityName,
        onOverwrite: () => Navigator.of(context).pop(true),
        onRefresh: () => Navigator.of(context).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
          const SizedBox(width: 8),
          Text(
            'Version Conflict',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'The $entityName you are trying to update has been modified by someone else since you last loaded it.\n\n'
        'You can either refresh to see their changes, or force overwrite with your changes.',
        style: GoogleFonts.plusJakartaSans(),
      ),
      actions: [
        TextButton(
          onPressed: onRefresh,
          child: const Text('Refresh Data'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
          onPressed: onOverwrite,
          child: const Text('Force Overwrite'),
        ),
      ],
    );
  }
}
