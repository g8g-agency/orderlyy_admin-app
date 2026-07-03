import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/tables_provider.dart';
import '../providers/reviews_provider.dart';
import '../../data/models/review_dto.dart';

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reviewsProvider.notifier).loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviewsState = ref.watch(reviewsProvider);
    final tablesState = ref.watch(tablesProvider);
    final desktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Customer Reviews',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
        backgroundColor: AppTheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 22.r),
            onPressed: () => ref.read(reviewsProvider.notifier).loadReviews(forceRefresh: true),
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(
            height: 1.h,
            thickness: 1.h,
            color: AppTheme.surfaceContainerHigh,
          ),
        ),
      ),
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (reviewsState.error != null) {
              return Center(
                child: Text(
                  'Error loading reviews: ${reviewsState.error}',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.error),
                ),
              );
            }
            if (reviewsState.isLoading && reviewsState.reviews.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              );
            }
            
            final reviews = reviewsState.reviews;

            if (reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline_rounded,
                        size: 48.r,
                        color: AppTheme.secondary.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No reviews yet',
                        style: AppTheme.titleSm.copyWith(color: AppTheme.secondary),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Reviews from customers will appear here.',
                        textAlign: TextAlign.center,
                        style: AppTheme.bodySm.copyWith(
                          color: AppTheme.secondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: EdgeInsets.all(16.r),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: desktop ? 3 : 1,
                mainAxisSpacing: 16.h,
                crossAxisSpacing: 16.w,
                childAspectRatio: desktop ? 1.5 : 2.0,
                mainAxisExtent: 180.h,
              ),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final tableLabel = review.tableId != null 
                    ? (tablesState.tablesById[review.tableId]?.label ?? 'Unknown Table')
                    : 'Unknown Table';

                return _ReviewCard(review: review, tableLabel: tableLabel)
                    .animate(delay: Duration(milliseconds: 30 * index))
                    .fadeIn(duration: 350.ms)
                    .slideY(begin: 0.05, end: 0, duration: 350.ms);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewDto review;
  final String tableLabel;

  const _ReviewCard({
    required this.review,
    required this.tableLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color getRatingColor() {
      if (review.rating >= 4) return Colors.green;
      if (review.rating == 3) return Colors.orange;
      return Colors.red;
    }

    final orderIdShort = review.orderId.length >= 8 
        ? review.orderId.substring(review.orderId.length - 8).toUpperCase()
        : review.orderId.toUpperCase();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppTheme.surfaceContainerHigh,
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: index < review.rating ? getRatingColor() : AppTheme.surfaceContainerHigh,
                    size: 20.r,
                  );
                }),
              ),
              Text(
                DateFormat('MMM d, h:mm a').format(review.createdAt),
                style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (review.comment != null && review.comment!.isNotEmpty)
            Expanded(
              child: Text(
                '"${review.comment}"',
                style: AppTheme.bodyMd.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Expanded(
              child: Text(
                'No comment provided',
                style: AppTheme.bodyMd.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.secondary.withValues(alpha: 0.6),
                ),
              ),
            ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppTheme.surfaceContainerHigh),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Table $tableLabel',
                    style: AppTheme.labelSm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    'Order #$orderIdShort',
                    style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                  ),
                ],
              ),
              if (review.phone != null && review.phone!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_rounded, size: 12.r, color: AppTheme.secondary),
                      SizedBox(width: 4.w),
                      Text(
                        review.phone!,
                        style: AppTheme.labelSm.copyWith(color: AppTheme.secondary),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
