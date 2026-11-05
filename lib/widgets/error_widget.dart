import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppErrorWidget extends ConsumerWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Icon(
        Icons.error_outline,
        size: 50,
        color: theme.colorScheme.error,
      ),
    );
  }
}
