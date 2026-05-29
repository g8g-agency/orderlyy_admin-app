import 'package:flutter/material.dart';

class ReplayRecoveryInspector extends StatelessWidget {
  const ReplayRecoveryInspector({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF30363D)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REPLAY RECOVERY STATUS',
              style: TextStyle(
                color: Color(0xFF8B949E),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // Placeholder for now. Replay state would be populated from the snapshot or stream.
            // A more complex visualization would go here.
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Monitoring replay backlog...',
                  style: TextStyle(
                    color: Color(0xFF484F58),
                    fontFamily: 'RobotoMono',
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
