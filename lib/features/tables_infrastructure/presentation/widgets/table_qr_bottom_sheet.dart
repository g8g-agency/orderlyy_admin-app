import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/dtos/floor_dto.dart';
import '../../data/dtos/table_dto.dart';
import '../../data/repositories/table_infrastructure_repository.dart';
import '../services/table_qr_file_save.dart';
import '../state/table_infrastructure_providers.dart';

class TableQrBottomSheet extends ConsumerStatefulWidget {
  const TableQrBottomSheet({
    super.key,
    required this.table,
    this.floorName,
  });

  final TableDto table;
  final String? floorName;

  @override
  ConsumerState<TableQrBottomSheet> createState() => _TableQrBottomSheetState();
}

class _TableQrBottomSheetState extends ConsumerState<TableQrBottomSheet> {
  final GlobalKey _qrKey = GlobalKey();
  bool _loading = true;
  String? _error;
  late TableDto _table;

  @override
  void initState() {
    super.initState();
    _table = widget.table;
    Future.microtask(_ensureQr);
  }

  Future<void> _ensureQr() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_table.qrUrl == null || _table.qrUrl!.isEmpty) {
        final repo = ref.read(tableInfrastructureRepositoryProvider);
        _table = await repo.generateQr(widget.table.id);
        ref.invalidate(tablesFutureProvider);
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _displayTitle {
    final floor = widget.floorName;
    final name = _table.displayName ?? _table.tableNumber;
    if (floor != null && floor.isNotEmpty) {
      return 'Table $name · $floor';
    }
    return 'Table $name';
  }

  String get _shortUrl {
    final url = _table.qrUrl;
    if (url == null || url.isEmpty) return '';
    return url.replaceFirst(RegExp(r'^https?://'), '');
  }

  Future<void> _copyLink() async {
    final url = _table.qrUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied!')),
    );
  }

  Future<void> _downloadPng() async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return;

    final slug = _table.tableNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-');
    await saveBytesAsDownload(
      byteData.buffer.asUint8List(),
      'table-$slug-qr.png',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('QR code saved for Table ${_table.tableNumber}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _table.qrUrl ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 32.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _displayTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 20.h),
          if (_loading)
            SizedBox(
              height: 220.h,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
            )
          else if (qrUrl.isEmpty)
            ElevatedButton(
              onPressed: _ensureQr,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Generate QR'),
            )
          else ...[
            RepaintBoundary(
              key: _qrKey,
              child: QrImageView(
                data: qrUrl,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              _shortUrl,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.sp,
                color: AppTheme.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _downloadPng,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyLink,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('Copy link'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: const BorderSide(color: AppTheme.surfaceContainerHigh),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String? floorNameForTable(TableDto table, List<FloorDto> floors) {
  if (table.floorId == null) return null;
  for (final f in floors) {
    if (f.id == table.floorId) return f.name;
  }
  return null;
}
