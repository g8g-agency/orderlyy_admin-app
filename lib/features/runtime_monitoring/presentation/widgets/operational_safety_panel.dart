import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OperationalSafetyPanel extends ConsumerStatefulWidget {
  const OperationalSafetyPanel({super.key});

  @override
  ConsumerState<OperationalSafetyPanel> createState() => _OperationalSafetyPanelState();
}

class _OperationalSafetyPanelState extends ConsumerState<OperationalSafetyPanel> {
  final _reasonController = TextEditingController();
  final _incidentController = TextEditingController();
  bool _isAwaitingConfirmation = false;
  String? _selectedDirectiveType;

  @override
  void dispose() {
    _reasonController.dispose();
    _incidentController.dispose();
    super.dispose();
  }

  void _initiateAction(String type) {
    setState(() {
      _selectedDirectiveType = type;
      _isAwaitingConfirmation = true;
    });
  }

  void _cancelAction() {
    setState(() {
      _isAwaitingConfirmation = false;
      _selectedDirectiveType = null;
      _reasonController.clear();
      _incidentController.clear();
    });
  }

  Future<void> _confirmAction() async {
    if (_reasonController.text.trim().isEmpty || _selectedDirectiveType == null) return;

    final type = _selectedDirectiveType!;
    final reason = _reasonController.text;
    final incident = _incidentController.text.isNotEmpty ? _incidentController.text : null;
    
    // In a real app we would dispatch this to the backend API via repository
    // e.g. ref.read(apiRuntimeObservabilityRepositoryProvider).issueSafetyDirective(type, reason, incident);
    debugPrint('Triggering $type with reason: $reason');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Safety Directive Issued: $type'),
        backgroundColor: Colors.orange,
      ),
    );

    _cancelAction();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Operational Safety Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PILOT BOUNDED',
                  style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isAwaitingConfirmation) ...[
            _buildActionCard(
              title: 'Throttle Replay',
              description: 'Slow down mutation replay processing to contain CPU spikes.',
              type: 'THROTTLE_REPLAY',
              icon: Icons.speed,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Engage Degraded Mode',
              description: 'Force clients into polling mode and suppress heavy UI rebuilds.',
              type: 'ENGAGE_DEGRADED_MODE',
              icon: Icons.battery_alert,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Contain Reconnects',
              description: 'Enforce aggressive backoff for clients stuck in reconnect loops.',
              type: 'CONTAIN_RECONNECTS',
              icon: Icons.wifi_off,
            ),
          ] else ...[
            _buildConfirmationForm(),
          ]
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required String description, required String type, required IconData icon}) {
    return InkWell(
      onTap: () => _initiateAction(type),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          border: Border.all(color: const Color(0xFF30363D)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1B16), // Dark orange/red tint
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm: $_selectedDirectiveType',
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incidentController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Incident ID (Optional)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Operational Justification (Required)',
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelAction,
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (_reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Justification is required')),
                    );
                    return;
                  }
                  _confirmAction();
                },
                child: const Text('Execute Directive'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
