import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.color,
    this.size = 30,
    this.strokeWidth,
  });

  final Color? color;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LoadingAnimationWidget.staggeredDotsWave(
      color: color ?? scheme.primary,
      size: size,
    );
  }
}
