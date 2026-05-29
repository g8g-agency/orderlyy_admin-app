import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/dtos/table_dto.dart';
import '../state/table_infrastructure_providers.dart';

class TableManagementScreen extends ConsumerWidget {
  const TableManagementScreen({super.key});

  void _showTableForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _TableFormSheet(),
    ).then((_) {
      ref.invalidate(tablesFutureProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTables = ref.watch(tablesFutureProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Tables',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncTables.when(
        data: (tables) {
          if (tables.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGrid(tables, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            'Error loading tables: $err',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableForm(context, ref),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Table',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant_outlined,
            size: 64,
            color: AppTheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Tables Configured',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add tables to manage your floor plan.',
            style: GoogleFonts.inter(color: AppTheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<TableDto> tables, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: tables.length,
      itemBuilder: (ctx, index) {
        final table = tables[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.surfaceContainerHigh),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    table.tableNumber,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppTheme.primaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${table.capacity}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    table.isActive ? 'Active' : 'Inactive',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: table.isActive ? Colors.green : AppTheme.secondary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    onPressed: () => ref
                        .read(tablesFutureProvider.notifier)
                        .deleteTable(table.id),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TableFormSheet extends ConsumerStatefulWidget {
  const _TableFormSheet();

  @override
  ConsumerState<_TableFormSheet> createState() => _TableFormSheetState();
}

class _TableFormSheetState extends ConsumerState<_TableFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '4');
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _capCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final capacity = int.tryParse(_capCtrl.text) ?? 4;
      await ref
          .read(tablesFutureProvider.notifier)
          .addTable(_nameCtrl.text, capacity);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding table: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 20 : 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Table',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Table Number / Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _capCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Capacity (Seats)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Save Table',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
