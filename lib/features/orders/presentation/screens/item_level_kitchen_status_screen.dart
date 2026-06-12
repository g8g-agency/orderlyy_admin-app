import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../providers/live_active_orders_provider.dart';

class KitchenStationInfo {
  final String name;
  final IconData icon;
  final Color themeColor;
  final String currentDelay;

  const KitchenStationInfo({
    required this.name,
    required this.icon,
    required this.themeColor,
    required this.currentDelay,
  });
}

class ItemLevelKitchenStatusScreen extends ConsumerStatefulWidget {
  const ItemLevelKitchenStatusScreen({super.key});

  @override
  ConsumerState<ItemLevelKitchenStatusScreen> createState() =>
      _ItemLevelKitchenStatusScreenState();
}

class _ItemLevelKitchenStatusScreenState
    extends ConsumerState<ItemLevelKitchenStatusScreen> {
  final List<KitchenStationInfo> _stations = const [
    KitchenStationInfo(
      name: 'Grill',
      icon: Icons.local_fire_department_rounded,
      themeColor: Colors.orange,
      currentDelay: '8m delay',
    ),
    KitchenStationInfo(
      name: 'Fryer',
      icon: Icons.cookie_rounded,
      themeColor: Colors.amber,
      currentDelay: '3m delay',
    ),
    KitchenStationInfo(
      name: 'Salad',
      icon: Icons.spa_rounded,
      themeColor: Colors.green,
      currentDelay: 'No delay',
    ),
    KitchenStationInfo(
      name: 'Bar',
      icon: Icons.local_bar_rounded,
      themeColor: Colors.blue,
      currentDelay: 'No delay',
    ),
  ];

  String _getStationForItem(String menuItemName) {
    final name = menuItemName.toLowerCase();
    if (name.contains('grill') || name.contains('steak') || name.contains('burger') ||
        name.contains('chicken') || name.contains('lamb') || name.contains('mains')) {
      return 'Grill';
    }
    if (name.contains('fries') || name.contains('chips') || name.contains('fried') ||
        name.contains('sides')) {
      return 'Fryer';
    }
    if (name.contains('salad') || name.contains('greens') || name.contains('slaw')) {
      return 'Salad';
    }
    if (name.contains('drink') || name.contains('juice') || name.contains('water') ||
        name.contains('coffee') || name.contains('tea') || name.contains('beer') ||
        name.contains('wine')) {
      return 'Bar';
    }
    return 'Grill';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Item-Level Kitchen Stations')),
      body: Consumer(
        builder: (context, ref, _) {
          final ordersAsync = ref.watch(liveActiveOrdersProvider);
          return ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (orders) {
              final List<Map<String, dynamic>> allItems = [];
              for (final order in orders) {
                for (final item in order.items) {
                  allItems.add({
                    'order': order,
                    'item': item,
                    'station': _getStationForItem(item.menuItemName),
                  });
                }
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _stations.map((station) {
                    final stationItems = allItems
                        .where((i) => i['station'] == station.name)
                        .toList();
                    return Card(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        leading: Icon(
                          station.icon,
                          color: station.themeColor,
                          size: 28,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${station.name} Station',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: station.currentDelay.contains('delay')
                                    ? AppColors.error.withValues(alpha: 0.15)
                                    : AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                station.currentDelay,
                                style: TextStyle(
                                  color: station.currentDelay.contains('delay')
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${stationItems.length} active prep tasks',
                          style: theme.textTheme.bodySmall,
                        ),
                        children: [
                          const Divider(height: 1),
                          if (stationItems.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'No active prep items in this station.',
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stationItems.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final task = stationItems[index];
                                final Order order = task['order'];
                                final OrderItem item = task['item'];

                                // Check dependencies
                                final List<String> dependencies = [];
                                if (station.name == 'Grill') {
                                  final sideItems = order.items.where(
                                    (o) =>
                                        _getStationForItem(
                                          o.menuItemName,
                                        ) ==
                                        'Fryer',
                                  );
                                  for (final side in sideItems) {
                                    dependencies.add(
                                      'Fryer Station (${side.menuItemName})',
                                    );
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${item.quantity}x ${item.menuItemName}',
                                                style: theme.textTheme.bodyLarge
                                                    ?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Table ${order.tableId}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (dependencies.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.link_rounded,
                                              size: 14,
                                              color: AppColors.info,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                'Dependencies: ${dependencies.join(", ")}',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: AppColors.info,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
