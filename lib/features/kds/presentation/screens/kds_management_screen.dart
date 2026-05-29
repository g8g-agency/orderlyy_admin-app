import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/dtos/kitchen_station_dto.dart';
import '../../data/repositories/kds_repository.dart';

class KdsManagementScreen extends ConsumerWidget {
  const KdsManagementScreen({super.key});

  void _showKdsForm(
    BuildContext context,
    WidgetRef ref, {
    KitchenStationDto? existing,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _KdsFormSheet(existing: existing),
    ).then((_) {
      ref.invalidate(kitchenStationsProvider);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStations = ref.watch(kitchenStationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: Text(
          'Kitchen Stations',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncStations.when(
        data: (stations) {
          if (stations.isEmpty) {
            return _buildEmptyState();
          }
          return _buildList(stations, context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text(
            'Error loading stations: $err',
            style: GoogleFonts.inter(color: Colors.red),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showKdsForm(context, ref),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Station',
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
            Icons.kitchen_outlined,
            size: 64,
            color: AppTheme.secondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Kitchen Stations',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create stations (e.g. Grill, Bar) to route orders.',
            style: GoogleFonts.inter(color: AppTheme.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<KitchenStationDto> stations,
    BuildContext context,
    WidgetRef ref,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stations.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final station = stations[index];
        return InkWell(
          onTap: () => _showKdsForm(context, ref, existing: station),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceContainerHigh),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            station.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (station.isDefault)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryContainer.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Default',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryContainer,
                                  ),
                                ),
                              ),
                            ),
                          if (!station.isActive)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Inactive',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (station.description != null &&
                          station.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            station.description!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: station.isActive,
                  onChanged: (val) async {
                    await ref
                        .read(kdsRepositoryProvider)
                        .toggleStation(station.id, val);
                    ref.invalidate(kitchenStationsProvider);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await ref
                        .read(kdsRepositoryProvider)
                        .deleteStation(station.id);
                    ref.invalidate(kitchenStationsProvider);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KdsFormSheet extends ConsumerStatefulWidget {
  final KitchenStationDto? existing;
  const _KdsFormSheet({this.existing});

  @override
  ConsumerState<_KdsFormSheet> createState() => _KdsFormSheetState();
}

class _KdsFormSheetState extends ConsumerState<_KdsFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(kdsRepositoryProvider);

      if (widget.existing == null) {
        await repo.createStation(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          branchId: 'branch_1', // default fallback
          isDefault: _isDefault,
        );
      } else {
        await repo.updateStation(
          widget.existing!.id,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          isDefault: _isDefault,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving station: $e')));
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
              widget.existing == null ? 'Create Station' : 'Edit Station',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Station Name (e.g. Grill, Bar)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: Text(
                'Default Station',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Unrouted items will be sent here.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.secondary,
                ),
              ),
              value: _isDefault,
              onChanged: (val) => setState(() => _isDefault = val),
              contentPadding: EdgeInsets.zero,
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
                      'Save Station',
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
