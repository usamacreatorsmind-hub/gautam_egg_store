import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/notifiers/category_notifier.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class CategorySlider extends ConsumerStatefulWidget {
  const CategorySlider({super.key});

  @override
  ConsumerState<CategorySlider> createState() => _CategorySliderState();
}

class _CategorySliderState extends ConsumerState<CategorySlider> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final categoriesState = ref.watch(categoryProvider);

    return categoriesState.when(
      loading: () => SizedBox(
        height: 110.h,
        child: const Center(child: AppLoader()),
      ),
      error: (e, _) => SizedBox(
        height: 110.h,
        child: Center(child: Text(e.toString())),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return SizedBox(
            height: 110.h,
            child: const Center(child: Text('No categories')),
          );
        }

        return SizedBox(
          height: 110.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final item = categories[index];
              final isSelected = index == selectedIndex;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedIndex = index);

                  if (item.isStoryItem == true) {
                    context.pushNamed(
                      RouteNames.itemStory,
                      pathParameters: {'docId': item.docId},
                    );
                  } else {
                    context.push(
                      '/category-items/${item.id}',
                      extra: item.name,
                    );
                  }
                },
                child: item.isStoryItem
                    ? Container(
                        width: 70.w,
                        margin: EdgeInsets.only(right: 8.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(isSelected ? 2.5.w : 0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 26.r,
                                backgroundColor: isSelected
                                    ? scheme.primaryContainer
                                    : scheme.surfaceContainerHighest,
                                backgroundImage: (item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty)
                                    ? NetworkImage(item.imageUrl!)
                                    : null,
                                onBackgroundImageError:
                                    (item.imageUrl != null &&
                                            item.imageUrl!.isNotEmpty)
                                        ? (_, __) {}
                                        : null,
                                child: (item.imageUrl == null ||
                                        item.imageUrl!.isEmpty)
                                    ? Icon(
                                        Icons.category_rounded,
                                        color: isSelected
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                        size: 22.sp,
                                      )
                                    : null,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              item.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
        );
      },
    );
  }
}
