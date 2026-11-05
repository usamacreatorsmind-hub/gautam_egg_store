import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/core/constants/asset_constants.dart';
import 'package:sure_wholesaler/core/routing/app_router.dart';
import 'package:sure_wholesaler/core/routing/app_routes.dart';
import 'package:sure_wholesaler/utils/locationProviders.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for Firebase Auth, location initialization AND minimum splash duration
    final results = await Future.wait([
      FirebaseAuth.instance.authStateChanges().first,
      ref.read(locationInitlializerProvider.future),
      Future.delayed(const Duration(seconds: 3)),
    ]);

    if (!mounted) return;

    final user = results[0] as User?;

    if (user != null) {
      context.go(AppRoutes.home);
      return;
    }

    final seenOnboarding = await AppRouter.hasSeenOnboarding();
    if (!mounted) return;

    context.go(seenOnboarding ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              theme.primaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Image.asset(
                  AssetConstants.appLogoCleanBg,
                  width: 250,
                  height: 250,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 40,
              child: LinearProgressIndicator(
                backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                color: theme.primaryColor,
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
